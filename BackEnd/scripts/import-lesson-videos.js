import fs from 'node:fs/promises';

import mongoose from 'mongoose';
import dotenv from 'dotenv';

import Lesson from '../model/Lesson.js';
import { reviewLessonVideos } from '../src/modules/lessons/lesson-video.review.js';

dotenv.config();

/**
 * Gắn video + lời thoại vào một bài học có sẵn.
 *
 * Chỉ **cập nhật** bài học đã tồn tại (tìm theo `level` + `order`), không tạo
 * bài mới và không đụng tới phần còn lại của bài. File video nằm trong
 * `uploads/` — thư mục này đã được `.gitignore` bỏ qua, nên file nặng không
 * vào git; chỉ dữ liệu lời thoại trong `data/lesson-videos/` là được commit.
 *
 * Cách dùng:
 *
 *   node scripts/import-lesson-videos.js --file data/lesson-videos/n5-01-greeting.json --dry-run
 *   node scripts/import-lesson-videos.js --file data/lesson-videos/n5-01-greeting.json
 *
 * Cờ:
 *   --file <path>  Bắt buộc. File JSON mô tả video và lời thoại.
 *   --dry-run      Kiểm và báo cáo, không ghi.
 */

const parseArgs = (argv) => {
  const args = { dryRun: false };
  for (let index = 0; index < argv.length; index += 1) {
    const flag = argv[index];
    if (flag === '--dry-run') args.dryRun = true;
    else if (flag === '--file') args.file = argv[(index += 1)];
    else throw new Error(`Cờ không nhận ra: ${flag}`);
  }
  if (!args.file) throw new Error('Thiếu --file <đường dẫn>.');
  return args;
};

const formatTime = (seconds) => {
  const total = Math.round(seconds);
  return `${String(Math.floor(total / 60)).padStart(2, '0')}:${String(total % 60).padStart(2, '0')}`;
};

const main = async () => {
  const args = parseArgs(process.argv.slice(2));
  const data = JSON.parse(await fs.readFile(args.file, 'utf8'));
  const { videos, errors } = reviewLessonVideos(data);

  if (errors.length > 0) {
    console.log(`\nLỗi (${errors.length}):`);
    errors.forEach((error) => console.log(`  ${error}`));
    if (videos.length === 0) throw new Error('Không có video nào hợp lệ.');
  }

  console.log(`\nVideo đọc được (${videos.length}):`);
  videos.forEach((video) => {
    const last = video.transcript.at(-1);
    const length = last ? ` · tới ${formatTime(last.end_seconds ?? last.start_seconds)}` : '';
    console.log(`  ${video.title} — ${video.transcript.length} lời thoại${length}`);
    console.log(`    ${video.url}`);
  });

  const { level, order } = data.lesson ?? {};
  if (!level || !order) throw new Error('File thiếu `lesson.level` hoặc `lesson.order`.');

  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('Thiếu MONGODB_URI trong .env.');
  await mongoose.connect(uri, { dbName: process.env.DB_NAME || 'AppHocTiengNhat' });

  try {
    const lesson = await Lesson.findOne({ level, order }).select('title videos').lean();
    if (!lesson) throw new Error(`Không tìm thấy bài học ${level} số ${order}.`);

    console.log(`\nBài học: ${lesson.title} (đang có ${lesson.videos?.length ?? 0} video)`);
    if (args.dryRun) {
      console.log('(--dry-run: chưa ghi gì)');
      return;
    }

    await Lesson.updateOne({ _id: lesson._id }, { $set: { videos } }, { runValidators: true });
    console.log(`Đã ghi ${videos.length} video vào bài học.`);
  } finally {
    await mongoose.disconnect();
  }
};

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
