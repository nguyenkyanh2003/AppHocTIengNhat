/**
 * Nạp bộ dữ liệu demo: tài khoản, thẻ SRS, lịch sử học 20 ngày, bạn học cho
 * bảng xếp hạng và huy hiệu đã đạt theo lịch sử đó.
 *
 * Script **không** gọi `deleteMany({})` trên cả collection. Nó chỉ đụng vào
 * đúng những bản ghi của bộ demo, tra theo khoá tự nhiên (`TenDangNhap`,
 * `word + hiragana`, khoá event theo ngày). Lý do: script được chạy trên cùng
 * database đang dùng để phát triển, xoá sạch collection sẽ cuốn theo cả dữ liệu
 * không liên quan.
 *
 * Chạy trước: `seed-situational-lessons.js` (bài và từ), `seed-exercises.js`
 * (bài tập mà lịch sử nộp bài trỏ tới), `seedAchievements.js` (định nghĩa huy
 * hiệu). Chạy lại nhiều lần cho ra cùng một kết quả; chạy vào ngày khác thì
 * lịch sử nối thêm đúng những ngày còn thiếu.
 *
 *   node scripts/seed-demo.js               # toàn bộ bộ demo
 *   node scripts/seed-demo.js --bulk=40     # thêm 40 thẻ N5 đến hạn để thử ôn nhiều đợt
 *   node scripts/seed-demo.js --no-history  # bỏ lịch sử học và bạn học
 *   node scripts/seed-demo.js --no-progress # bỏ thẻ SRS mẫu của học viên
 *   node scripts/seed-demo.js --reset       # xoá tài khoản demo và mọi dữ liệu của họ
 */
import bcrypt from 'bcrypt';
import dotenv from 'dotenv';
import mongoose from 'mongoose';

import ActivityEvent from '../model/ActivityEvent.js';
import Exercise from '../model/Exercise.js';
import ExerciseResult from '../model/ExerciseResult.js';
import SRSProgress from '../model/SRSProgress.js';
import StreakDay from '../model/StreakDay.js';
import User from '../model/User.js';
import UserAchievement from '../model/UserAchievement.js';
import UserStreak from '../model/UserStreak.js';
import Vocabulary from '../model/Vocabulary.js';
import { unitOfWork } from '../src/shared/db/unit-of-work.js';
import { streakService } from '../src/modules/streaks/streak.service.js';
import { POLICY_VERSION } from '../src/modules/streaks/streak-policy.js';
import { dayKey } from '../src/modules/streaks/streak-rules.js';
import {
  buildBulkProgress,
  DEMO_DUE_COUNT,
  DEMO_LEARNER_HISTORY,
  DEMO_PEERS,
  DEMO_SRS_PROGRESS,
  DEMO_USERS,
  DEMO_VOCABULARIES,
} from './demo-dataset.js';
import { buildDemoJournal, summarizeJournal } from './demo-history.js';
import { SAMPLE_EXERCISES } from './sample-exercises.js';

dotenv.config({ quiet: true });

const DAY_IN_MS = 24 * 60 * 60 * 1000;
const LEARNER = 'demo_hocvien';
const ALL_ACCOUNTS = [...DEMO_USERS, ...DEMO_PEERS];

const connect = async () => {
  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('Thiếu MONGODB_URI trong .env');
  await mongoose.connect(uri, { dbName: process.env.DB_NAME || 'AppHocTiengNhat' });
  console.log(`✅ Đã kết nối ${mongoose.connection.name}`);
};

const upsertUsers = async (accounts) => {
  const ids = new Map();
  for (const account of accounts) {
    const hashed = await bcrypt.hash(account.password, 10);
    const doc = await User.findOneAndUpdate(
      { TenDangNhap: account.username },
      {
        $set: {
          HoTen: account.fullName,
          MatKhau: hashed,
          Email: account.email,
          TrinhDo: account.level,
          VaiTro: account.role,
          role: account.role,
        },
      },
      { upsert: true, new: true, setDefaultsOnInsert: true },
    );
    ids.set(account.username, doc._id);
  }
  console.log(`👤 ${accounts.length} tài khoản`);
  return ids;
};

/**
 * Upsert theo (`word`, `hiragana`) — đúng unique index của `Vocabulary`. Từ đã
 * có giữ nguyên nghĩa và ví dụ; không đụng `lesson` — liên kết từ–bài thuộc về
 * `seed-situational-lessons.js`.
 */
const upsertVocabularies = async () => {
  const ids = new Map();
  for (const { word, hiragana, ...content } of DEMO_VOCABULARIES) {
    const doc = await Vocabulary.findOneAndUpdate(
      { word, hiragana },
      { $setOnInsert: content },
      { upsert: true, new: true, setDefaultsOnInsert: true },
    );
    ids.set(word, doc._id);
  }
  console.log(`📝 ${DEMO_VOCABULARIES.length} từ vựng`);
  return ids;
};

const upsertCard = (userId, itemId, { box, streak, dueInDays }, now) => ({
  updateOne: {
    filter: { user: userId, item_id: itemId, item_type: 'Vocabulary' },
    update: { $set: { box, streak, next_review: new Date(now + dueInDays * DAY_IN_MS) } },
    upsert: true,
  },
});

/** Thẻ SRS dựng sẵn của học viên: có thẻ quá hạn, đến hạn hôm nay và chưa tới hạn. */
const upsertLearnerCards = async (learnerId, vocabularyIds) => {
  const now = Date.now();
  const ops = DEMO_SRS_PROGRESS.filter((row) => vocabularyIds.has(row.word)).map((row) =>
    upsertCard(learnerId, vocabularyIds.get(row.word), row, now),
  );
  await SRSProgress.bulkWrite(ops);
  console.log(`🔁 ${ops.length} thẻ SRS của học viên, ${DEMO_DUE_COUNT} thẻ đến hạn`);
};

/**
 * Thêm `count` thẻ đến hạn trên các từ N5 có sẵn, ngoài bộ 15 từ demo. Chọn
 * theo `_id` tăng dần (lùi `offset` từ) nên chạy lại vẫn là đúng những từ đó.
 */
const upsertBulkCards = async (userId, count, excludeIds, offset = 0) => {
  const words = await Vocabulary.find({ level: 'N5', _id: { $nin: excludeIds } })
    .sort({ _id: 1 })
    .skip(offset)
    .limit(count)
    .select('_id')
    .lean();
  const now = Date.now();
  const schedule = buildBulkProgress(words.length);
  if (words.length > 0) {
    await SRSProgress.bulkWrite(words.map((word, index) => upsertCard(userId, word._id, schedule[index], now)));
  }
  return words.length;
};

/** Bài tập mẫu có thật trong DB, theo cấp của user, kèm câu hỏi và `_id` đáp án. */
const sampleExercisesFor = (levels) =>
  Exercise.find({
    title: { $in: SAMPLE_EXERCISES.map((row) => row.exercise.title) },
    level: { $in: levels },
    is_active: true,
  })
    .sort({ _id: 1 })
    .lean();

/**
 * Ghi lịch sử học của một user trong **một** transaction: event, kết quả bài
 * tập, ngày học, tóm tắt suy ra từ nhật ký và huy hiệu đạt được — dừng giữa
 * chừng thì không để lại nửa lịch sử.
 */
const seedHistory = ({ userId, username, profile, exercises }) =>
  unitOfWork.run(async ({ session }) => {
    const cards = await SRSProgress.find({ user: userId, item_type: 'Vocabulary' })
      .sort({ _id: 1 })
      .select('_id')
      .session(session)
      .lean();
    // Chỉ ngày đã có hoạt động thật mới được giữ nguyên. Ngày `legacy` (chép từ
    // thời đăng nhập cũng tính) không chứng minh được là có học, nên được nâng
    // lên `studied` và giữ dấu nguồn, đúng như đường ghi thật làm (spec §3.2).
    const studiedBefore = await StreakDay.find({ user: userId, status: 'studied' })
      .select('day_key')
      .session(session)
      .lean();
    const journal = buildDemoJournal({
      userId,
      username,
      profile,
      todayKey: dayKey(new Date()),
      cardIds: cards.map((card) => card._id),
      exercises,
      skipDays: new Set(studiedBefore.map((day) => day.day_key)),
    });

    if (journal.events.length > 0) await ActivityEvent.insertMany(journal.events, { session });
    if (journal.results.length > 0) await ExerciseResult.insertMany(journal.results, { session });
    if (journal.days.length > 0) {
      await StreakDay.bulkWrite(
        journal.days.map(({ user, day_key: day, origin, status, ...counts }) => ({
          updateOne: {
            filter: { user, day_key: day },
            update: { $set: { status }, $setOnInsert: { origin }, $inc: counts },
            upsert: true,
          },
        })),
        { session },
      );
    }

    // Tóm tắt suy ra lại từ **toàn bộ** nhật ký của user, kể cả hoạt động thật.
    const studied = await StreakDay.find({ user: userId, status: 'studied' }).select('day_key').session(session).lean();
    const [xp] = await ActivityEvent.aggregate([
      { $match: { user: userId } },
      { $group: { _id: null, total: { $sum: '$xp_delta' } } },
    ]).session(session);
    const current = await UserStreak.findOne({ user: userId }).session(session).lean();

    const legacyDays = await StreakDay.countDocuments({ user: userId, status: 'legacy' }).session(session);

    const summary = summarizeJournal({ studiedDays: studied.map((day) => day.day_key), totalXp: xp?.total ?? 0 });
    summary.legacy_day_count = legacyDays;
    // Mốc cũ (baseline legacy) chỉ được giữ, không bị hạ.
    summary.longest_streak = Math.max(summary.longest_streak, current?.longest_streak ?? 0);
    if (current?.tracking_started_day && current.tracking_started_day < summary.tracking_started_day) {
      summary.tracking_started_day = current.tracking_started_day;
    }
    await UserStreak.updateOne(
      { user: userId },
      { $set: { ...summary, policy_version: POLICY_VERSION }, $inc: { revision: 1 } },
      { upsert: true, session },
    );

    const awarded = await streakService.awardEarnedAchievements(userId, { session });
    return { ...journal, summary, awarded };
  });

const reportHistory = (username, { days, results, summary, awarded }) =>
  console.log(
    `   ${username.padEnd(14)} +${days.length} ngày, +${results.length} bài tập · chuỗi ${summary.current_streak}` +
      ` · ${summary.total_xp} XP · +${awarded.length} huy hiệu`,
  );

const seedHistories = async (userIds, demoWordIds) => {
  const n5 = await sampleExercisesFor(['N5']);
  const n4 = await sampleExercisesFor(['N5', 'N4']);
  if (n5.length === 0) console.log('⚠️  Chưa có bài tập mẫu — chạy seed-exercises.js để lịch sử có bài nộp.');

  // Bạn học cần thẻ SRS thật để lượt ôn trong lịch sử có chỗ trỏ tới.
  for (const [index, peer] of DEMO_PEERS.entries()) {
    await upsertBulkCards(userIds.get(peer.username), peer.cards, demoWordIds, index * 10);
  }

  console.log('📅 Lịch sử học:');
  const accounts = [
    { username: LEARNER, profile: DEMO_LEARNER_HISTORY, exercises: n5 },
    ...DEMO_PEERS.map((peer) => ({
      username: peer.username,
      profile: peer.history,
      exercises: peer.level === 'N4' ? n4 : n5,
    })),
  ];
  for (const { username, profile, exercises } of accounts) {
    const result = await seedHistory({ userId: userIds.get(username), username, profile, exercises });
    reportHistory(username, result);
  }
};

const seed = async ({ withProgress, withHistory, bulk }) => {
  const userIds = await upsertUsers(withHistory ? ALL_ACCOUNTS : DEMO_USERS);
  const vocabularyIds = await upsertVocabularies();
  const learnerId = userIds.get(LEARNER);
  const demoWordIds = [...vocabularyIds.values()];

  if (withProgress) await upsertLearnerCards(learnerId, vocabularyIds);
  if (bulk > 0) {
    const added = await upsertBulkCards(learnerId, bulk, demoWordIds);
    console.log(`🔁 ${added} thẻ N5 đến hạn cho luồng ôn nhiều đợt${added < bulk ? ` (DB chỉ có ${added} từ phù hợp)` : ''}`);
  }
  if (withHistory) await seedHistories(userIds, demoWordIds);

  console.log('\n🔑 Tài khoản kiểm thử:');
  for (const account of DEMO_USERS) {
    console.log(`   ${account.role.padEnd(5)} ${account.username} / ${account.password}`);
  }
  if (withHistory) {
    console.log(`   bạn học: ${DEMO_PEERS.map((peer) => peer.username).join(', ')} / ${DEMO_PEERS[0].password}`);
  }
};

/**
 * Xoá tài khoản demo và mọi dữ liệu học của họ. Từ vựng giữ lại: chúng nằm
 * trong bộ bài chủ đề và có thể là từ của đợt import.
 */
const reset = async () => {
  const users = await User.find({ TenDangNhap: { $in: ALL_ACCOUNTS.map((account) => account.username) } })
    .select('_id')
    .lean();
  const userIds = users.map((user) => user._id);
  const byUser = { user: { $in: userIds } };

  const removed = {
    srs: (await SRSProgress.deleteMany(byUser)).deletedCount,
    events: (await ActivityEvent.deleteMany(byUser)).deletedCount,
    days: (await StreakDay.deleteMany(byUser)).deletedCount,
    results: (await ExerciseResult.deleteMany({ user_id: { $in: userIds } })).deletedCount,
    badges: (await UserAchievement.deleteMany(byUser)).deletedCount,
    streak: (await UserStreak.deleteMany(byUser)).deletedCount,
    users: (await User.deleteMany({ _id: { $in: userIds } })).deletedCount,
  };

  console.log('🗑️  Đã xoá dữ liệu demo:');
  for (const [name, count] of Object.entries(removed)) console.log(`   ${name.padEnd(8)} ${count}`);
};

/** `--bulk=<n>`: số nguyên dương có trần, để một lần gõ nhầm không tạo hàng nghìn thẻ. */
const bulkCount = (args) => {
  const flag = args.find((arg) => arg.startsWith('--bulk='));
  if (!flag) return 0;
  const count = Number(flag.slice('--bulk='.length));
  if (!Number.isSafeInteger(count) || count < 1 || count > 200) {
    throw new Error('--bulk phải là số nguyên từ 1 tới 200.');
  }
  return count;
};

const main = async () => {
  const args = process.argv.slice(2);
  const bulk = bulkCount(args);
  await connect();
  try {
    if (args.includes('--reset')) await reset();
    else {
      await seed({
        withProgress: !args.includes('--no-progress'),
        withHistory: !args.includes('--no-history'),
        bulk,
      });
    }
  } finally {
    await mongoose.disconnect();
  }
};

main().catch((error) => {
  console.error('❌ Lỗi khi chạy seed-demo:', error.message);
  process.exitCode = 1;
});
