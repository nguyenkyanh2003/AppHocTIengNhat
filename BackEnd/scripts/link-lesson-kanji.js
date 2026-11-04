import 'dotenv/config';
import mongoose from 'mongoose';

import Kanji from '../model/Kanji.js';
import Lesson from '../model/Lesson.js';
import Vocabulary from '../model/Vocabulary.js';
import { planLessonKanjiLinks } from './lesson-kanji-links.js';

/**
 * Gắn Kanji vào bài học theo từ vựng của bài (xem `lesson-kanji-links.js`).
 *
 *   node scripts/link-lesson-kanji.js           # chỉ đọc: in kế hoạch
 *   node scripts/link-lesson-kanji.js --apply   # ghi mảng `kanjis` của các bài
 *
 * Chỉ ghi `Lesson.kanjis`, không đụng Kanji hay tiến độ học. Chạy lại an toàn:
 * chữ đã gắn thì giữ nguyên, chỉ chữ mới trong seed được gắn thêm.
 */

const parseFlags = (argv = process.argv.slice(2)) => {
  const unknown = argv.filter((flag) => flag !== '--apply');
  if (unknown.length > 0) throw new Error(`Cờ không nhận ra: ${unknown.join(', ')}`);
  return { apply: argv.includes('--apply') };
};

/** Bài học kèm mặt chữ từ vựng, theo đúng thứ tự từ trong bài. */
const loadLessons = async () => {
  const lessons = await Lesson.find().select('title level order kanjis vocabularies').lean();
  const words = await Vocabulary.find({
    $or: [{ _id: { $in: lessons.flatMap((lesson) => lesson.vocabularies) } }, { lesson: { $in: lessons.map((l) => l._id) } }],
  })
    .select('word lesson')
    .lean();
  const byId = new Map(words.map((word) => [String(word._id), word.word]));

  return lessons.map((lesson) => ({
    ...lesson,
    // Cùng nguồn với chi tiết bài: mảng tham chiếu, rỗng thì tra ngược theo `lesson`.
    words:
      lesson.vocabularies.length > 0
        ? lesson.vocabularies.map((id) => byId.get(String(id))).filter(Boolean)
        : words.filter((word) => String(word.lesson) === String(lesson._id)).map((word) => word.word),
  }));
};

const plan = async () =>
  planLessonKanjiLinks({
    lessons: await loadLessons(),
    kanjis: await Kanji.find().select('character lessonId').lean(),
  });

const print = ({ updates, unmatched }) => {
  console.log(`\n📚 Bài sẽ có thêm Kanji: ${updates.length}`);
  for (const { title, added, kanjiIds } of updates) {
    console.log(`   • ${title}: +${added.join('')} (tổng ${kanjiIds.length})`);
  }
  console.log(`   chữ không có trong từ vựng bài nào: ${unmatched.length > 0 ? unmatched.join('') : 'không'}`);
};

const run = async () => {
  const flags = parseFlags();
  await mongoose.connect(process.env.MONGODB_URI, { dbName: process.env.DB_NAME || 'AppHocTiengNhat' });
  console.log(`✅ Đã kết nối ${mongoose.connection.name}`);

  try {
    const before = await plan();
    print(before);
    if (!flags.apply) {
      console.log('\n🔍 Chỉ đọc. Chạy lại với --apply để ghi.');
      return true;
    }

    for (const { lessonId, kanjiIds } of before.updates) {
      await Lesson.updateOne({ _id: lessonId }, { $set: { kanjis: kanjiIds } });
    }
    console.log(`\n🔧 Đã ghi ${before.updates.length} bài`);

    // Đọc lại từ DB: ghi đủ thì kế hoạch mới không còn việc gì.
    const after = await plan();
    const ok = after.updates.length === 0;
    console.log(`   xác minh: ${ok ? '✅ không còn chữ nào chờ gắn' : `❌ còn ${after.updates.length} bài`}`);
    return ok;
  } finally {
    await mongoose.disconnect();
  }
};

run()
  .then((ok) => {
    if (!ok) process.exitCode = 1;
  })
  .catch((error) => {
    console.error('❌', error.message);
    process.exitCode = 1;
  });
