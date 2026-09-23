/**
 * Nạp bài tập mẫu cho bộ bài chủ đề — upsert theo `(lesson_id, title)`, không
 * xoá gì, nên kết quả làm bài đã có vẫn trỏ đúng bài tập.
 *
 * Chạy `seed-situational-lessons.js` trước: bài tập gắn vào bài học theo tiêu
 * đề, bài học chưa có thì bài tập của nó bị bỏ qua và được báo ra.
 *
 *   node scripts/seed-exercises.js --dry-run
 *   node scripts/seed-exercises.js [--overwrite]
 */
import dotenv from 'dotenv';
import mongoose from 'mongoose';

import Exercise from '../model/Exercise.js';
import Lesson from '../model/Lesson.js';
import { applyPlan, parseFlags, planUpserts, printPlan } from './content-upsert.js';
import { SAMPLE_EXERCISES } from './sample-exercises.js';

dotenv.config({ quiet: true });

const exerciseKey = (exercise) => `${String(exercise.lesson_id)}:${exercise.title}`;

const run = async () => {
  const flags = parseFlags();
  await mongoose.connect(process.env.MONGODB_URI, { dbName: process.env.DB_NAME || 'AppHocTiengNhat' });
  console.log(`✅ Đã kết nối MongoDB${flags.dryRun ? ' (--dry-run, không ghi)' : ''}`);

  try {
    const titles = [...new Set(SAMPLE_EXERCISES.map((row) => row.lessonTitle))];
    const lessons = await Lesson.find({ title: { $in: titles } }).select('_id title').lean();
    const lessonIdOf = new Map(lessons.map((lesson) => [lesson.title, lesson._id]));

    const missing = titles.filter((title) => !lessonIdOf.has(title));
    const rows = SAMPLE_EXERCISES.filter((row) => lessonIdOf.has(row.lessonTitle)).map((row) => ({
      ...row.exercise,
      lesson_id: lessonIdOf.get(row.lessonTitle),
    }));

    const existing = await Exercise.find({
      lesson_id: { $in: lessons.map((lesson) => lesson._id) },
      title: { $in: rows.map((row) => row.title) },
    }).lean();
    const plan = planUpserts({ rows, existing, keyOf: exerciseKey });
    if (!flags.dryRun) await applyPlan({ model: Exercise, plan, overwrite: flags.overwrite });

    printPlan('Bài tập mẫu', plan, flags);
    if (missing.length > 0) {
      console.log(`\n⚠️  ${missing.length} bài học chưa có trong DB, bỏ qua bài tập của chúng:`);
      for (const title of missing) console.log(`   • ${title}`);
      console.log('   Chạy `node scripts/seed-situational-lessons.js` trước.');
    }
  } finally {
    await mongoose.connection.close();
  }
};

run().catch((error) => {
  console.error('❌ Lỗi:', error.message);
  process.exit(1);
});
