/**
 * Nạp bộ dữ liệu demo để kiểm thử thủ công mốc 1 (SRS + streak).
 *
 * Khác với các script `seed-*.js` khác trong thư mục này, script này **không**
 * gọi `deleteMany({})` trên cả collection. Nó chỉ đụng vào đúng những bản ghi
 * của bộ demo, tra theo khoá tự nhiên (`TenDangNhap`, `title`, `word`). Lý do:
 * script được chạy trên cùng database mà bạn đang dùng để phát triển, xoá
 * sạch collection sẽ cuốn theo cả dữ liệu không liên quan.
 *
 * Chạy lại nhiều lần cho ra cùng một kết quả.
 *
 *   node scripts/seed-demo.js               # nạp dữ liệu + tiến độ SRS mẫu
 *   node scripts/seed-demo.js --no-progress # bỏ phần tiến độ SRS
 *   node scripts/seed-demo.js --reset       # xoá sạch dữ liệu demo
 */
import bcrypt from 'bcrypt';
import dotenv from 'dotenv';
import mongoose from 'mongoose';

import Exercise from '../model/Exercise.js';
import Lesson from '../model/Lesson.js';
import SRSProgress from '../model/SRSProgress.js';
import User from '../model/User.js';
import UserStreak from '../model/UserStreak.js';
import Vocabulary from '../model/Vocabulary.js';
import {
  DEMO_DUE_COUNT,
  DEMO_EXERCISES,
  DEMO_LESSONS,
  DEMO_SRS_PROGRESS,
  DEMO_USERS,
  DEMO_VOCABULARIES,
} from './demo-dataset.js';

dotenv.config();

const DAY_IN_MS = 24 * 60 * 60 * 1000;

const connect = async () => {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error('❌ Thiếu MONGODB_URI trong .env');
    process.exit(1);
  }
  await mongoose.connect(uri, {
    dbName: process.env.DB_NAME || 'AppHocTiengNhat',
  });
  console.log(`✅ Đã kết nối ${mongoose.connection.name}`);
};

const upsertUsers = async () => {
  const ids = new Map();

  for (const user of DEMO_USERS) {
    const hashed = await bcrypt.hash(user.password, 10);
    const doc = await User.findOneAndUpdate(
      { TenDangNhap: user.username },
      {
        $set: {
          HoTen: user.fullName,
          MatKhau: hashed,
          Email: user.email,
          TrinhDo: user.level,
          VaiTro: user.role,
          role: user.role,
        },
      },
      { upsert: true, new: true, setDefaultsOnInsert: true },
    );
    ids.set(user.username, doc._id);
  }

  console.log(`👤 ${DEMO_USERS.length} tài khoản`);
  return ids;
};

const upsertLessons = async () => {
  const ids = new Map();

  for (const lesson of DEMO_LESSONS) {
    const doc = await Lesson.findOneAndUpdate(
      { title: lesson.title },
      { $set: lesson },
      { upsert: true, new: true, setDefaultsOnInsert: true },
    );
    ids.set(lesson.title, doc._id);
  }

  console.log(`📘 ${DEMO_LESSONS.length} bài học`);
  return ids;
};

const upsertVocabularies = async (lessonIds) => {
  const ids = new Map();

  for (const { lessonTitle, ...vocabulary } of DEMO_VOCABULARIES) {
    const lesson = lessonIds.get(lessonTitle);
    const doc = await Vocabulary.findOneAndUpdate(
      { word: vocabulary.word, lesson },
      { $set: { ...vocabulary, lesson } },
      { upsert: true, new: true, setDefaultsOnInsert: true },
    );
    ids.set(vocabulary.word, doc._id);
  }

  console.log(`📝 ${DEMO_VOCABULARIES.length} từ vựng`);
  return ids;
};

const upsertExercises = async (lessonIds) => {
  for (const { lessonTitle, ...exercise } of DEMO_EXERCISES) {
    await Exercise.findOneAndUpdate(
      { title: exercise.title },
      { $set: { ...exercise, lesson_id: lessonIds.get(lessonTitle) } },
      { upsert: true, new: true, setDefaultsOnInsert: true },
    );
  }

  const questionCount = DEMO_EXERCISES.reduce(
    (sum, exercise) => sum + exercise.questions.length,
    0,
  );
  console.log(`🧩 ${DEMO_EXERCISES.length} bài tập (${questionCount} câu hỏi)`);
};

/**
 * Dựng sẵn tiến độ ôn tập cho tài khoản học viên.
 *
 * Có thẻ quá hạn, thẻ đến hạn hôm nay và thẻ chưa tới hạn, để kiểm thử được
 * danh sách đến hạn và badge đếm ngay lập tức thay vì phải chờ qua ngày.
 */
const upsertProgress = async (learnerId, vocabularyIds) => {
  const now = Date.now();

  for (const row of DEMO_SRS_PROGRESS) {
    const itemId = vocabularyIds.get(row.word);
    if (!itemId) continue;

    await SRSProgress.findOneAndUpdate(
      { user: learnerId, item_id: itemId, item_type: 'Vocabulary' },
      {
        $set: {
          box: row.box,
          streak: row.streak,
          next_review: new Date(now + row.dueInDays * DAY_IN_MS),
        },
      },
      { upsert: true, new: true, setDefaultsOnInsert: true },
    );
  }

  console.log(
    `🔁 ${DEMO_SRS_PROGRESS.length} thẻ SRS, trong đó ${DEMO_DUE_COUNT} thẻ đến hạn`,
  );
};

const seed = async ({ withProgress }) => {
  const userIds = await upsertUsers();
  const lessonIds = await upsertLessons();
  const vocabularyIds = await upsertVocabularies(lessonIds);
  await upsertExercises(lessonIds);

  if (withProgress) {
    await upsertProgress(userIds.get('demo_hocvien'), vocabularyIds);
  } else {
    console.log('🔁 Bỏ qua tiến độ SRS (--no-progress)');
  }

  console.log('\n🔑 Tài khoản kiểm thử:');
  for (const user of DEMO_USERS) {
    console.log(`   ${user.role.padEnd(5)} ${user.username} / ${user.password}`);
  }
};

const reset = async () => {
  const usernames = DEMO_USERS.map((user) => user.username);
  const users = await User.find({ TenDangNhap: { $in: usernames } })
    .select('_id')
    .lean();
  const userIds = users.map((user) => user._id);

  const lessonTitles = DEMO_LESSONS.map((lesson) => lesson.title);
  const lessons = await Lesson.find({ title: { $in: lessonTitles } })
    .select('_id')
    .lean();
  const lessonIds = lessons.map((lesson) => lesson._id);

  const removed = {
    srs: (await SRSProgress.deleteMany({ user: { $in: userIds } })).deletedCount,
    streak: (await UserStreak.deleteMany({ user: { $in: userIds } }))
      .deletedCount,
    exercises: (
      await Exercise.deleteMany({
        title: { $in: DEMO_EXERCISES.map((exercise) => exercise.title) },
      })
    ).deletedCount,
    vocabularies: (await Vocabulary.deleteMany({ lesson: { $in: lessonIds } }))
      .deletedCount,
    lessons: (await Lesson.deleteMany({ _id: { $in: lessonIds } })).deletedCount,
    users: (await User.deleteMany({ _id: { $in: userIds } })).deletedCount,
  };

  console.log('🗑️  Đã xoá dữ liệu demo:');
  for (const [name, count] of Object.entries(removed)) {
    console.log(`   ${name.padEnd(13)} ${count}`);
  }
};

const main = async () => {
  const args = process.argv.slice(2);
  await connect();

  try {
    if (args.includes('--reset')) {
      await reset();
    } else {
      await seed({ withProgress: !args.includes('--no-progress') });
    }
  } finally {
    await mongoose.disconnect();
  }
};

main().catch((error) => {
  console.error('❌ Lỗi khi chạy seed-demo:', error.message);
  process.exitCode = 1;
});
