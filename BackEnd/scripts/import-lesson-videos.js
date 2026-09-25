import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import mongoose from 'mongoose';
import dotenv from 'dotenv';

import Lesson from '../model/Lesson.js';
import { reviewLessonVideos } from '../src/modules/lessons/lesson-video.review.js';
import { contentHash, faststart, mp4Duration } from './mp4-file.js';

dotenv.config({ quiet: true });

/**
 * Gắn video + lời thoại vào bài học có sẵn.
 *
 * Mỗi file JSON trong `data/lesson-videos/` mô tả video của **một** bài, tìm
 * theo `lesson.title` (khoá tự nhiên của bài, giống seed bài học). Chỉ ghi
 * mảng `videos`, không đụng phần còn lại của bài.
 *
 * File video nằm trong `uploads/` (đã `.gitignore`). Trước khi ghi DB, mỗi file
 * được kiểm và chuẩn bị để phát mượt trên web:
 *   - phải tồn tại và là MP4 đọc được;
 *   - không được trùng nội dung với video khác — bắt lỗi chép nhầm một file
 *     thành nhiều cảnh;
 *   - được dời mục lục lên đầu file (faststart) để khung hình đầu hiện ngay;
 *   - thời lượng được đọc từ file và lưu vào `duration_seconds`.
 *
 * Cách dùng:
 *   node scripts/import-lesson-videos.js --all --dry-run
 *   node scripts/import-lesson-videos.js --all
 *   node scripts/import-lesson-videos.js --file data/lesson-videos/n5-01-greeting.json
 *
 * Cờ:
 *   --all          Nhập mọi file trong data/lesson-videos/.
 *   --file <path>  Chỉ nhập một file.
 *   --dry-run      Kiểm và báo cáo, không sửa file video, không ghi DB.
 */

const BACKEND_DIR = fileURLToPath(new URL('..', import.meta.url));
const DATA_DIR = path.join(BACKEND_DIR, 'data', 'lesson-videos');
const UPLOADS_PREFIX = '/uploads/';

const parseArgs = (argv) => {
  const args = { dryRun: false, all: false };
  for (let index = 0; index < argv.length; index += 1) {
    const flag = argv[index];
    if (flag === '--dry-run') args.dryRun = true;
    else if (flag === '--all') args.all = true;
    else if (flag === '--file') args.file = argv[(index += 1)];
    else throw new Error(`Cờ không nhận ra: ${flag}`);
  }
  if (!args.all === !args.file) throw new Error('Cần đúng một trong hai: --all hoặc --file <đường dẫn>.');
  return args;
};

const manifestPaths = async (args) => {
  if (args.file) return [path.resolve(args.file)];
  const names = (await fs.readdir(DATA_DIR)).filter((name) => name.endsWith('.json')).sort();
  return names.map((name) => path.join(DATA_DIR, name));
};

const formatTime = (seconds) => {
  const total = Math.round(seconds);
  return `${String(Math.floor(total / 60)).padStart(2, '0')}:${String(total % 60).padStart(2, '0')}`;
};

/**
 * Kiểm file của một video và (khi không `--dry-run`) tối ưu tại chỗ.
 * URL ngoài (`https://...`) không có file để kiểm nên giữ nguyên.
 */
const prepareFile = async (video, { dryRun }) => {
  if (!video.url.startsWith(UPLOADS_PREFIX)) return { video };

  const file = path.join(BACKEND_DIR, 'uploads', ...video.url.slice(UPLOADS_PREFIX.length).split('/'));
  let buffer;
  try {
    buffer = await fs.readFile(file);
  } catch {
    throw new Error(`không tìm thấy file ${path.relative(BACKEND_DIR, file)}`);
  }

  const hash = contentHash(buffer);
  const duration = mp4Duration(buffer);
  const optimized = faststart(buffer);
  if (optimized && !dryRun) {
    // Ghi ra file tạm rồi đổi tên: dừng giữa chừng không để lại video hỏng.
    const temporary = `${file}.tmp`;
    await fs.writeFile(temporary, optimized);
    await fs.rename(temporary, file);
  }

  return {
    video: { ...video, duration_seconds: Math.round(duration * 10) / 10 },
    hash,
    optimized: Boolean(optimized),
  };
};

/** Đọc, kiểm và chuẩn bị một file dữ liệu. Lỗi nào cũng chỉ đúng file và video. */
const prepareManifest = async (manifestPath, { dryRun, seenHashes }) => {
  const label = path.relative(BACKEND_DIR, manifestPath);
  const data = JSON.parse(await fs.readFile(manifestPath, 'utf8'));
  const { videos: reviewed, errors } = reviewLessonVideos(data);
  const title = data.lesson?.title;
  if (!title) errors.push('Thiếu `lesson.title`.');

  const videos = [];
  for (const [index, video] of reviewed.entries()) {
    try {
      const prepared = await prepareFile(video, { dryRun });
      const duplicate = prepared.hash && seenHashes.get(prepared.hash);
      if (duplicate) {
        errors.push(`Video ${index + 1} "${video.title}": nội dung giống hệt ${duplicate} — có vẻ chép nhầm file.`);
        continue;
      }
      if (prepared.hash) seenHashes.set(prepared.hash, `${label} · "${video.title}"`);
      videos.push({ ...prepared.video, optimized: prepared.optimized });
    } catch (error) {
      errors.push(`Video ${index + 1} "${video.title}": ${error.message}`);
    }
  }

  return { label, title, videos, errors };
};

const printManifest = ({ label, title, videos, errors }, { dryRun }) => {
  console.log(`\n${label} → ${title ?? '(không có tiêu đề bài)'}`);
  for (const video of videos) {
    const length = video.duration_seconds === undefined ? '' : ` · ${formatTime(video.duration_seconds)}`;
    const note = video.optimized ? (dryRun ? ' · sẽ tối ưu faststart' : ' · đã tối ưu faststart') : '';
    console.log(`  ✓ ${video.title} — ${video.transcript.length} lời thoại${length}${note}`);
  }
  for (const error of errors) console.log(`  ✖ ${error}`);
};

/**
 * Cảnh nào chưa có lời thoại chạy theo video.
 *
 * Thiếu lời thoại không phải lỗi — video vẫn xem được — nhưng phải nhìn thấy
 * được, vì đó là việc còn lại của người soạn nội dung.
 */
const printTranscriptCoverage = (manifests) => {
  const all = manifests.flatMap(({ label, videos }) => videos.map((video) => ({ label, video })));
  const missing = all.filter(({ video }) => video.transcript.length === 0);

  console.log(`\n📝 Lời thoại chạy theo video: ${all.length - missing.length}/${all.length} cảnh đã có.`);
  if (missing.length === 0) return;

  const byLesson = new Map();
  for (const { label, video } of missing) {
    byLesson.set(label, [...(byLesson.get(label) ?? []), video.url.split('/').pop()]);
  }
  for (const [label, scenes] of byLesson) console.log(`   • ${label}: ${scenes.join(', ')}`);
  console.log('   Gõ lời thoại vào <bài>.txt rồi chạy: node scripts/apply-transcript.js --all');
};

const main = async () => {
  const args = parseArgs(process.argv.slice(2));
  const seenHashes = new Map();
  const manifests = [];
  for (const manifestPath of await manifestPaths(args)) {
    const manifest = await prepareManifest(manifestPath, { dryRun: args.dryRun, seenHashes });
    printManifest(manifest, args);
    manifests.push(manifest);
  }

  // Một file lỗi là không ghi gì: nhập nửa chừng thì bài có bài không, khó biết
  // DB đang ở trạng thái nào.
  const failed = manifests.filter((manifest) => manifest.errors.length > 0 || !manifest.title);
  if (failed.length > 0) throw new Error(`\n${failed.length} file có lỗi — chưa ghi gì vào DB.`);

  printTranscriptCoverage(manifests);

  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('Thiếu MONGODB_URI trong .env.');
  await mongoose.connect(uri, { dbName: process.env.DB_NAME || 'AppHocTiengNhat' });

  try {
    const titles = manifests.map((manifest) => manifest.title);
    const lessons = await Lesson.find({ title: { $in: titles } }).select('_id title').lean();
    const idOf = new Map(lessons.map((lesson) => [lesson.title, lesson._id]));
    const missing = titles.filter((title) => !idOf.has(title));
    if (missing.length > 0) {
      throw new Error(`Chưa có bài học: ${missing.join(', ')}. Chạy seed-situational-lessons.js trước.`);
    }

    if (args.dryRun) {
      console.log(`\n(--dry-run: ${manifests.length} bài hợp lệ, chưa sửa file và chưa ghi DB)`);
      return;
    }

    for (const { title, videos } of manifests) {
      const clean = videos.map(({ optimized, ...video }) => video);
      await Lesson.updateOne({ _id: idOf.get(title) }, { $set: { videos: clean } }, { runValidators: true });
    }
    console.log(`\nĐã ghi video cho ${manifests.length} bài học.`);
  } finally {
    await mongoose.disconnect();
  }
};

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
