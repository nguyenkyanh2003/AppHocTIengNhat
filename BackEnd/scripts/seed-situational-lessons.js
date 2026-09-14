/**
 * Nạp ba bài học theo tình huống và từ vựng đi kèm.
 *
 * Upsert theo khoá tự nhiên (`Lesson.title`, `Vocabulary.word + hiragana`) nên
 * chạy lại nhiều lần cho cùng kết quả và KHÔNG đụng tới bài học cũ — khác hẳn
 * `seed-lessons.js` vốn `deleteMany({})` cả collection.
 *
 * Cách chạy:
 *   node scripts/seed-situational-lessons.js --dry-run
 *   node scripts/seed-situational-lessons.js
 */
import mongoose from 'mongoose';
import dotenv from 'dotenv';

import Lesson from '../model/Lesson.js';
import Vocabulary from '../model/Vocabulary.js';
import { SITUATIONAL_LESSONS } from './situational-lessons.js';

dotenv.config();

const dryRun = process.argv.includes('--dry-run');

const upsertLesson = async ({ vocabularies, ...lesson }) => {
  const existing = await Lesson.findOne({ title: lesson.title }).lean();

  if (dryRun) {
    return { id: existing?._id ?? null, created: !existing };
  }

  const saved = await Lesson.findOneAndUpdate(
    { title: lesson.title },
    { $set: lesson },
    { upsert: true, new: true, setDefaultsOnInsert: true, runValidators: true },
  );

  return { id: saved._id, created: !existing };
};

/**
 * Upsert một từ vựng và trả về `_id` của nó.
 *
 * Từ đã có (ví dụ đã nhập từ bộ N5 trước đó) **không** bị đổi `lesson`: đổi sẽ
 * cướp từ khỏi bài học đang sở hữu nó và làm hỏng tiến độ/thống kê của bài đó.
 * Liên kết với bài tình huống đi qua mảng `Lesson.vocabularies` thay vì ghi đè.
 */
const upsertVocabulary = async (row, lessonId, level) => {
  const key = { word: row.word, hiragana: row.hiragana };
  const existing = await Vocabulary.findOne(key).lean();

  if (dryRun) return { id: existing?._id ?? null, created: !existing };
  if (existing) return { id: existing._id, created: false };

  const saved = await Vocabulary.findOneAndUpdate(
    key,
    { $set: { meaning: row.meaning }, $setOnInsert: { ...key, lesson: lessonId, level } },
    { upsert: true, new: true, setDefaultsOnInsert: true, runValidators: true },
  );

  return { id: saved._id, created: true };
};

const run = async () => {
  await mongoose.connect(process.env.MONGODB_URI, {
    dbName: process.env.DB_NAME || 'AppHocTiengNhat',
  });
  console.log(`✅ Đã kết nối MongoDB${dryRun ? ' (chế độ --dry-run, không ghi)' : ''}`);

  const report = { lessonsCreated: 0, lessonsUpdated: 0, wordsCreated: 0, wordsReused: 0 };

  for (const lesson of SITUATIONAL_LESSONS) {
    const { id, created } = await upsertLesson(lesson);
    report[created ? 'lessonsCreated' : 'lessonsUpdated'] += 1;
    console.log(
      `${created ? '➕' : '♻️ '} ${lesson.title} — ${lesson.dialogue.length} lượt thoại, ` +
        `${lesson.vocabularies.length} từ vựng`,
    );

    const vocabularyIds = [];
    for (const row of lesson.vocabularies) {
      const result = await upsertVocabulary(row, id, lesson.level);
      report[result.created ? 'wordsCreated' : 'wordsReused'] += 1;
      if (result.id) vocabularyIds.push(result.id);
    }

    // Liên kết từ vựng với bài qua mảng M2M sẵn có, không đổi `Vocabulary.lesson`
    // của những từ vốn thuộc bài khác.
    if (!dryRun && id) {
      await Lesson.updateOne({ _id: id }, { $set: { vocabularies: vocabularyIds } });
    }
  }

  console.log('\n📊 Kết quả:');
  console.log(`   Bài học: tạo mới ${report.lessonsCreated}, cập nhật ${report.lessonsUpdated}`);
  console.log(
    `   Từ vựng: tạo mới ${report.wordsCreated}, dùng lại từ đã có ${report.wordsReused}`,
  );
  if (dryRun) console.log('\n🔍 --dry-run: không ghi gì vào database.');
  console.log('\n⚠️  Nội dung tiếng Nhật chưa được người biết tiếng Nhật rà soát.');

  await mongoose.connection.close();
};

run().catch(async (error) => {
  console.error('❌ Lỗi:', error.message);
  await mongoose.connection.close();
  process.exit(1);
});
