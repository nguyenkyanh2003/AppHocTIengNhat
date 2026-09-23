/**
 * Smoke test vòng học trên **MongoDB thật** (spec SRS §7, spec streak §7): thứ
 * mà test đơn vị với repository giả không chứng minh được — transaction,
 * unique index, CAS dưới hai request đồng thời, rollback.
 *
 * Chạy trên một database **riêng** `<DB_NAME>_smoke` cùng cluster (cần replica
 * set để có transaction — Atlas có sẵn). Database đó bị xoá lúc bắt đầu và lúc
 * kết thúc; dữ liệu thật không bị đụng tới.
 *
 *   node scripts/smoke-learning-loop.js          # chạy rồi dọn
 *   node scripts/smoke-learning-loop.js --keep   # giữ database smoke để xem lại
 */
import dotenv from 'dotenv';
import mongoose from 'mongoose';

import Achievement from '../model/Achievement.js';
import ActivityEvent from '../model/ActivityEvent.js';
import SRSProgress from '../model/SRSProgress.js';
import StreakDay from '../model/StreakDay.js';
import UserAchievement from '../model/UserAchievement.js';
import UserStreak from '../model/UserStreak.js';
import Vocabulary from '../model/Vocabulary.js';
import { createSrsService, srsService } from '../src/modules/srs/srs.service.js';
import { streakReadService } from '../src/modules/streaks/streak-read.service.js';
import { dayKey } from '../src/modules/streaks/streak-rules.js';
import { vocabularyService } from '../src/modules/vocabulary/vocabulary.service.js';

dotenv.config({ quiet: true });

const TYPE = 'Vocabulary';
const HOUR = 60 * 60 * 1000;
const MODELS = [Achievement, ActivityEvent, SRSProgress, StreakDay, UserAchievement, UserStreak, Vocabulary];

let failures = 0;
const check = (label, condition, detail = '') => {
  if (!condition) failures += 1;
  console.log(`${condition ? '✅' : '❌'} ${label}${!condition && detail ? ` — ${detail}` : ''}`);
};

/** Thẻ đến hạn cách đây một giờ, đọc lại mốc hạn đúng như client sẽ thấy. */
const makeDue = async (userId, itemId) => {
  const due = new Date(Date.now() - HOUR);
  await SRSProgress.updateOne({ user: userId, item_id: itemId, item_type: TYPE }, { $set: { next_review: due } });
  return due;
};

const review = (userId, itemId, expectedNextReview, service = srsService) =>
  service.review({ userId, itemId, itemType: TYPE, isCorrect: true, expectedNextReview });

const run = async () => {
  const userId = new mongoose.Types.ObjectId();
  const [word1, word2, word3] = await Vocabulary.insertMany(
    ['学生', '先生', '友達'].map((word, index) => ({
      word: `${word}-smoke`,
      hiragana: ['がくせい', 'せんせい', 'ともだち'][index],
      meaning: 'smoke',
      level: 'N5',
    })),
  );
  await Achievement.create({
    name: 'Smoke first word',
    name_vi: 'Smoke',
    description: 'smoke',
    description_vi: 'smoke',
    icon: '🧪',
    category: 'vocabulary',
    requirement_type: 'count',
    requirement_value: 1,
    xp_reward: 10,
  });

  // 1. Đánh dấu đã học hai lần cùng lúc chỉ ra một thẻ.
  await Promise.all([1, 2].map(() => vocabularyService.markLearned({ id: word1._id, userId })));
  check('đánh dấu đồng thời tạo đúng một thẻ', (await SRSProgress.countDocuments({ user: userId })) === 1);

  // 2. Hai lượt trả lời cùng một kỳ ôn: đúng một bên thắng.
  const due1 = await makeDue(userId, word1._id);
  const outcomes = await Promise.allSettled([1, 2].map(() => review(userId, word1._id, due1)));
  const won = outcomes.filter((outcome) => outcome.status === 'fulfilled');
  const lost = outcomes.filter((outcome) => outcome.status === 'rejected');
  check('hai lượt ôn đồng thời: một thành công', won.length === 1, JSON.stringify(outcomes.map((o) => o.status)));
  check(
    'bên thua nhận 409 có mã, không phải lỗi 500',
    lost.length === 1 && lost[0].reason?.status === 409,
    lost[0]?.reason?.message,
  );
  check('lượt ôn thắng lên hộp 2', won[0]?.value?.box === 2);

  let summary = await UserStreak.findOne({ user: userId }).lean();
  check('đúng một event ôn tập', (await ActivityEvent.countDocuments({ user: userId, type: 'srs.review' })) === 1);
  check('huy hiệu đạt tiêu chí được cấp một lần', (await UserAchievement.countDocuments({ user: userId, is_completed: true })) === 1);
  check('XP = 2 (ôn) + 10 (huy hiệu)', summary?.total_xp === 12, `total_xp=${summary?.total_xp}`);
  check('hôm nay là ngày học đầu tiên', summary?.current_streak === 1 && summary?.last_activity_day === dayKey(new Date()));

  // 3. Gửi lại đúng request cũ không đổi gì thêm.
  const retry = await review(userId, word1._id, due1).catch((error) => error);
  check('gửi lại lượt đã ghi trả SRS_NOT_DUE', retry?.code === 'SRS_NOT_DUE', retry?.code);
  summary = await UserStreak.findOne({ user: userId }).lean();
  check('gửi lại không cộng thêm XP', summary?.total_xp === 12);

  // 4. Thẻ thứ hai cùng ngày: thêm XP, không thêm ngày.
  await vocabularyService.markLearned({ id: word2._id, userId });
  const due2 = await makeDue(userId, word2._id);
  await review(userId, word2._id, due2);
  summary = await UserStreak.findOne({ user: userId }).lean();
  const today = await StreakDay.findOne({ user: userId, day_key: dayKey(new Date()) }).lean();
  check('thẻ khác cùng ngày cộng thêm 2 XP', summary?.total_xp === 14, `total_xp=${summary?.total_xp}`);
  check('vẫn chỉ một ngày học', summary?.total_active_days === 1 && today?.review_count === 2);

  // 5. Lỗi khi ghi hoạt động rollback cả lịch ôn.
  await vocabularyService.markLearned({ id: word3._id, userId });
  const due3 = await makeDue(userId, word3._id);
  const failing = createSrsService({
    streak: {
      recordActivity: async () => {
        throw new Error('smoke: ghi event hỏng');
      },
    },
  });
  await review(userId, word3._id, due3, failing).catch(() => {});
  const untouched = await SRSProgress.findOne({ user: userId, item_id: word3._id }).lean();
  check(
    'lỗi ghi hoạt động rollback lịch ôn',
    untouched?.box === 1 && untouched.next_review.getTime() === due3.getTime(),
  );

  // 6. Đặt lại lịch, rồi gửi lại lệnh đặt lại cũ.
  const card2 = await SRSProgress.findOne({ user: userId, item_id: word2._id }).lean();
  const reset = await srsService.reset({ userId, itemId: word2._id, itemType: TYPE, expectedNextReview: card2.next_review });
  check('đặt lại về hộp 1', reset.box === 1);
  const staleReset = await srsService
    .reset({ userId, itemId: word2._id, itemType: TYPE, expectedNextReview: card2.next_review })
    .catch((error) => error);
  check('đặt lại bằng lịch cũ trả SRS_PROGRESS_CHANGED', staleReset?.code === 'SRS_PROGRESS_CHANGED');

  // 7. Xoá và xoá lại.
  const first = await srsService.remove({ userId, itemId: word3._id, itemType: TYPE });
  const second = await srsService.remove({ userId, itemId: word3._id, itemType: TYPE });
  check('xoá lần đầu true, lần sau false', first.deleted === true && second.deleted === false);

  // 8. Đường đọc phân trang thấy đủ lịch sử.
  const rows = [];
  let cursor;
  do {
    const page = await streakReadService.xpHistoryPage(userId, { limit: 1, cursor });
    rows.push(...page.data);
    cursor = page.next_cursor;
  } while (cursor);
  check('lịch sử XP phân trang đọc đủ 3 dòng', rows.length === 3, `${rows.length} dòng`);
  const days = await streakReadService.days(userId, { limit: 100 });
  check('lịch học trả đúng ngày hôm nay', days.data.length === 1 && days.data[0].review_count === 2);
};

const main = async () => {
  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('Thiếu MONGODB_URI trong .env');
  const dbName = `${process.env.DB_NAME || 'AppHocTiengNhat'}_smoke`;
  await mongoose.connect(uri, { dbName });
  console.log(`🧪 Smoke test trên ${dbName}\n`);

  try {
    await mongoose.connection.dropDatabase();
    // Unique index là một nửa của cơ chế chống trùng — phải có trước khi chạy.
    for (const model of MODELS) await model.createIndexes();
    await run();
  } finally {
    if (!process.argv.includes('--keep')) await mongoose.connection.dropDatabase();
    await mongoose.disconnect();
  }

  console.log(failures === 0 ? '\n✅ Smoke test đạt.' : `\n❌ ${failures} kiểm tra không đạt.`);
  if (failures > 0) process.exitCode = 1;
};

main().catch((error) => {
  console.error('❌ Lỗi smoke test:', error);
  process.exitCode = 1;
});
