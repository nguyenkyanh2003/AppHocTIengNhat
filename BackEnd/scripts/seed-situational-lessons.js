/**
 * Nạp bộ bài học theo chủ đề và từ vựng đi kèm; tuỳ chọn dọn mọi bài không
 * thuộc bộ.
 *
 * Upsert theo khoá tự nhiên (`Lesson.title`, `Vocabulary.word + hiragana`) nên
 * chạy lại nhiều lần cho cùng kết quả. Bài giữ nguyên tiêu đề giữ nguyên `_id`,
 * nên tiến độ học đã gắn với bài đó không mất.
 *
 * Cách chạy:
 *   node scripts/seed-situational-lessons.js --dry-run            # xem trước
 *   node scripts/seed-situational-lessons.js                      # upsert bộ bài
 *   node scripts/seed-situational-lessons.js --replace --dry-run  # xem trước cả phần dọn
 *   node scripts/seed-situational-lessons.js --replace            # upsert rồi dọn bài cũ
 */
import { mkdir, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

import dotenv from 'dotenv';
import mongoose from 'mongoose';

import Exercise from '../model/Exercise.js';
import ExerciseResult from '../model/ExerciseResult.js';
import Grammar from '../model/Grammar.js';
import Kanji from '../model/Kanji.js';
import Lesson from '../model/Lesson.js';
import LessonProgress from '../model/LessonProgress.js';
import Vocabulary from '../model/Vocabulary.js';
import { SITUATIONAL_LESSONS } from './situational-lessons.js';

dotenv.config({ quiet: true });

const dryRun = process.argv.includes('--dry-run');
const replace = process.argv.includes('--replace');
const BACKUP_DIR = new URL('../backups/', import.meta.url);

/**
 * Bài trong bộ là toàn bộ nội dung của bài đó: thiếu `dialogue` nghĩa là bài
 * không có hội thoại soạn sẵn (bài có video dùng kịch bản video), nên phải ghi
 * mảng rỗng — `$set` bỏ qua trường vắng mặt, hội thoại cũ sẽ còn nằm lại.
 */
const upsertLesson = async ({ vocabularies, dialogue = [], ...rest }) => {
  const lesson = { ...rest, dialogue };
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
 * Liên kết với bài chủ đề đi qua mảng `Lesson.vocabularies` thay vì ghi đè.
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

/**
 * Gỡ mọi bài học không thuộc bộ chủ đề, cùng dữ liệu chỉ có nghĩa khi bài còn.
 *
 * Bài tập, kết quả làm bài và tiến độ học của bài bị gỡ cũng bị xoá:
 * `Exercise.lesson_id` là bắt buộc, giữ lại thì thành bài tập trỏ vào hư
 * không. Từ vựng, kanji, ngữ pháp chỉ bị gỡ liên kết — chúng là nội dung dùng
 * được ở chỗ khác (SRS, tra từ), không thuộc riêng bài nào.
 *
 * Mọi bản ghi sắp xoá hoặc sửa được ghi ra file JSON trước khi ghi DB, nên có
 * thể khôi phục bằng tay.
 */
const replaceStaleLessons = async () => {
  const keepTitles = SITUATIONAL_LESSONS.map((lesson) => lesson.title);
  const lessons = await Lesson.find({ title: { $nin: keepTitles } }).lean();

  console.log('\n🧹 Dọn bài học không thuộc bộ chủ đề:');
  if (lessons.length === 0) {
    console.log('   Không có bài nào cần dọn.');
    return;
  }

  const lessonIds = lessons.map((lesson) => lesson._id);
  const exercises = await Exercise.find({ lesson_id: { $in: lessonIds } }).lean();
  const exerciseIds = exercises.map((exercise) => exercise._id);

  const [exerciseResults, lessonProgresses, vocabularies, kanjis, grammars] =
    await Promise.all([
      ExerciseResult.find({ exercise_id: { $in: exerciseIds } }).lean(),
      LessonProgress.find({ lesson: { $in: lessonIds } }).lean(),
      Vocabulary.find({ lesson: { $in: lessonIds } }).select('_id lesson').lean(),
      Kanji.find({ lessonId: { $in: lessonIds } }).select('_id lessonId').lean(),
      Grammar.find({ lesson_id: { $in: lessonIds } }).select('_id lesson_id').lean(),
    ]);

  for (const lesson of lessons) console.log(`   ✖ ${lesson.level} ${lesson.title}`);
  console.log(
    `   Xoá: ${lessons.length} bài học, ${exercises.length} bài tập, ` +
      `${exerciseResults.length} kết quả làm bài, ${lessonProgresses.length} tiến độ học`,
  );
  console.log(
    `   Gỡ liên kết, giữ nội dung: ${vocabularies.length} từ vựng, ` +
      `${kanjis.length} kanji, ${grammars.length} ngữ pháp`,
  );

  if (dryRun) return;

  await mkdir(BACKUP_DIR, { recursive: true });
  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupFile = new URL(`lessons-${stamp}.json`, BACKUP_DIR);
  await writeFile(
    backupFile,
    JSON.stringify(
      { lessons, exercises, exerciseResults, lessonProgresses, vocabularies, kanjis, grammars },
      null,
      2,
    ),
    'utf8',
  );
  console.log(`   💾 Sao lưu: ${fileURLToPath(backupFile)}`);

  // Xoá từ lá lên gốc: nếu dừng giữa chừng, không bao giờ còn bản ghi con trỏ
  // vào một bài học đã mất.
  await ExerciseResult.deleteMany({ _id: { $in: exerciseResults.map((r) => r._id) } });
  await Exercise.deleteMany({ _id: { $in: exerciseIds } });
  await LessonProgress.deleteMany({ _id: { $in: lessonProgresses.map((p) => p._id) } });
  await Vocabulary.updateMany({ lesson: { $in: lessonIds } }, { $unset: { lesson: '' } });
  await Kanji.updateMany({ lessonId: { $in: lessonIds } }, { $unset: { lessonId: '' } });
  await Grammar.updateMany({ lesson_id: { $in: lessonIds } }, { $unset: { lesson_id: '' } });
  await Lesson.deleteMany({ _id: { $in: lessonIds } });
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
      `${created ? '➕' : '♻️ '} ${lesson.level} ${lesson.title} — ` +
        `${lesson.dialogue?.length ?? 0} lượt thoại, ${lesson.vocabularies.length} từ vựng`,
    );

    const vocabularyIds = [];
    for (const row of lesson.vocabularies) {
      const result = await upsertVocabulary(row, id, lesson.level);
      report[result.created ? 'wordsCreated' : 'wordsReused'] += 1;
      if (result.id) vocabularyIds.push(result.id);
    }

    if (!dryRun && id) {
      await Lesson.updateOne({ _id: id }, { $set: { vocabularies: vocabularyIds } });
    }
  }

  console.log('\n📊 Bộ bài chủ đề:');
  console.log(`   Bài học: tạo mới ${report.lessonsCreated}, cập nhật ${report.lessonsUpdated}`);
  console.log(
    `   Từ vựng: tạo mới ${report.wordsCreated}, dùng lại từ đã có ${report.wordsReused}`,
  );

  // Dọn sau khi bộ mới đã nằm trong DB: nếu upsert lỗi giữa chừng thì chưa có
  // bài cũ nào bị xoá.
  if (replace) await replaceStaleLessons();

  if (dryRun) console.log('\n🔍 --dry-run: không ghi gì vào database.');
  console.log('\n⚠️  Nội dung tiếng Nhật chưa được người biết tiếng Nhật rà soát.');

  await mongoose.connection.close();
};

run().catch(async (error) => {
  console.error('❌ Lỗi:', error.message);
  await mongoose.connection.close();
  process.exit(1);
});
