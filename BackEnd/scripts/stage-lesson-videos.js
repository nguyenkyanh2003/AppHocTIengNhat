import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { mergeManifest, planLessonFolder, transcriptSkeleton } from './lesson-video-staging.js';
import { contentHash, faststart, mp4Duration } from './mp4-file.js';

/**
 * Đưa video gốc (`data/Video_baihoc/<số bài>. <chủ đề>/`) vào app: chép sang
 * `uploads/lesson-videos/<tên file mô tả>/scene-<n>.mp4` + `summary.mp4`, tối ưu
 * faststart, và cập nhật danh sách cảnh trong `data/lesson-videos/*.json`.
 *
 * Không ghi DB — chạy `import-lesson-videos.js --all` sau đó. Thư mục nào có
 * bất thường (tên sai mẫu, file đánh số bài khác, hai file giống hệt nhau)
 * được báo rõ và giữ nguyên hiện trạng; các thư mục khác vẫn được đưa vào.
 *
 *   node scripts/stage-lesson-videos.js --dry-run
 *   node scripts/stage-lesson-videos.js [--from data/Video_baihoc]
 */

const BACKEND_DIR = fileURLToPath(new URL('..', import.meta.url));
const MANIFEST_DIR = path.join(BACKEND_DIR, 'data', 'lesson-videos');
const UPLOAD_DIR = path.join(BACKEND_DIR, 'uploads', 'lesson-videos');

const parseArgs = (argv) => {
  const args = { dryRun: false, from: path.join(BACKEND_DIR, 'data', 'Video_baihoc') };
  for (let index = 0; index < argv.length; index += 1) {
    const flag = argv[index];
    if (flag === '--dry-run') args.dryRun = true;
    else if (flag === '--from') args.from = path.resolve(argv[(index += 1)]);
    else throw new Error(`Cờ không nhận ra: ${flag}`);
  }
  return args;
};

/** File mô tả theo số bài, từ tên dạng `n5-10-bank.json`. */
const manifestsByLesson = async () => {
  const names = (await fs.readdir(MANIFEST_DIR)).filter((name) => /^n5-\d{2}-.+\.json$/.test(name));
  return new Map(names.map((name) => [Number(name.slice(3, 5)), name]));
};

/** Chép một video sang `uploads`, bỏ qua nếu bản đích đã đúng từng byte. */
const copyOptimized = async (source, target) => {
  const original = await fs.readFile(source);
  const optimized = faststart(original) ?? original;
  const current = await fs.readFile(target).catch(() => null);
  if (current && contentHash(current) === contentHash(optimized)) return false;

  await fs.mkdir(path.dirname(target), { recursive: true });
  const temporary = `${target}.tmp`;
  await fs.writeFile(temporary, optimized);
  await fs.rename(temporary, target);
  return true;
};

const formatSize = (bytes) => `${(bytes / 1024 / 1024).toFixed(1)} MB`;

const formatTime = (seconds) => {
  const total = Math.round(seconds);
  return `${String(Math.floor(total / 60)).padStart(2, '0')}:${String(total % 60).padStart(2, '0')}`;
};

/**
 * Bảng chứng cứ cho thư mục bị từ chối: kích thước, thời lượng và vân tay nội
 * dung của từng file. Hai file cùng vân tay là **một** video mang hai cái tên —
 * nhìn bảng này là thấy ngay, không phải tin lời báo lỗi.
 */
const printEvidence = (files) => {
  // Tên file đứng cuối: chữ Nhật và dấu tiếng Việt rộng hơn một ô console nên
  // căn cột theo tên là lệch — để cột cuối tự do thì bảng luôn thẳng.
  console.log('     kích thước  thời lượng   vân tay  file');
  for (const file of files) {
    const length = file.duration === null ? '—' : formatTime(file.duration);
    console.log(
      `     ${formatSize(file.size).padStart(10)}  ${length.padStart(10)}  ${file.hash.slice(0, 8)}  ${file.name}`,
    );
  }
};

const readVideoFile = async (folderPath, name) => {
  const buffer = await fs.readFile(path.join(folderPath, name));
  let duration = null;
  try {
    duration = mp4Duration(buffer);
  } catch {
    // File không đọc được vẫn vào bảng chứng cứ với thời lượng trống, để người
    // dùng thấy đúng file nào hỏng.
  }
  return { name, hash: contentHash(buffer), size: buffer.length, duration };
};

const stageFolder = async ({ folder, lesson, manifestName, args }) => {
  const folderPath = path.join(args.from, folder);
  const names = (await fs.readdir(folderPath)).filter((name) => name.toLowerCase().endsWith('.mp4')).sort();
  const files = [];
  for (const name of names) files.push(await readVideoFile(folderPath, name));

  const { videos, errors } = planLessonFolder({ lesson, files });
  console.log(`\nBài ${lesson} · ${folder} → ${manifestName}`);
  if (errors.length > 0) {
    errors.forEach((error) => console.log(`  ✖ ${error}`));
    printEvidence(files);
    console.log('  → Giữ nguyên, chưa đưa gì vào app.');
    return false;
  }

  const dir = manifestName.replace(/\.json$/, '');
  const manifestPath = path.join(MANIFEST_DIR, manifestName);
  const manifest = JSON.parse(await fs.readFile(manifestPath, 'utf8'));
  const merged = mergeManifest({ manifest, dir, videos });

  for (const video of videos) {
    const target = path.join(UPLOAD_DIR, dir, video.target);
    const copied = args.dryRun ? null : await copyOptimized(path.join(folderPath, video.file), target);
    const note = copied === null ? '' : copied ? ' · đã chép' : ' · đã có sẵn';
    console.log(`  ✓ ${video.target} ← ${video.file}${note}`);
  }

  const kept = new Set(merged.videos.map((video) => video.url));
  for (const old of manifest.videos ?? []) {
    if (!kept.has(old.url)) console.log(`  − bỏ khỏi file mô tả: ${old.url}`);
  }

  if (!args.dryRun) await fs.writeFile(manifestPath, `${JSON.stringify(merged, null, 2)}\n`);
  await writeSkeleton({ dir, lesson, title: manifest.lesson?.title, videos, args });
  return true;
};

/**
 * Tạo khung file lời thoại nếu bài chưa có.
 *
 * Không bao giờ đè lên file đã có — trong đó là công gõ tay hàng trăm câu.
 */
const writeSkeleton = async ({ dir, lesson, title, videos, args }) => {
  const textPath = path.join(MANIFEST_DIR, `${dir}.txt`);
  if (await fs.access(textPath).then(() => true, () => false)) return;

  console.log(`  📝 ${dir}.txt — khung lời thoại ${args.dryRun ? 'sẽ được tạo' : 'đã tạo'}, chờ gõ câu thoại`);
  if (!args.dryRun) await fs.writeFile(textPath, transcriptSkeleton({ lesson, title, videos }));
};

const main = async () => {
  const args = parseArgs(process.argv.slice(2));
  const manifests = await manifestsByLesson();
  const folders = (await fs.readdir(args.from, { withFileTypes: true }))
    .filter((entry) => entry.isDirectory() && /^\d+/.test(entry.name))
    .map((entry) => ({ folder: entry.name, lesson: Number(/^\d+/.exec(entry.name)[0]) }))
    .sort((a, b) => a.lesson - b.lesson);

  let staged = 0;
  const rejected = [];
  for (const { folder, lesson } of folders) {
    const manifestName = manifests.get(lesson);
    if (!manifestName) {
      console.log(`\nBài ${lesson} · ${folder}\n  ✖ Chưa có file data/lesson-videos/n5-${String(lesson).padStart(2, '0')}-*.json.`);
      rejected.push(lesson);
    } else if (await stageFolder({ folder, lesson, manifestName, args })) {
      staged += 1;
    } else {
      rejected.push(lesson);
    }
  }

  console.log(`\n📊 Đưa vào được ${staged} bài${args.dryRun ? ' (--dry-run: chưa chép, chưa sửa file mô tả)' : ''}.`);
  if (rejected.length > 0) {
    console.log(`⚠️  Bài cần sửa video gốc rồi chạy lại: ${rejected.join(', ')}.`);
    process.exitCode = 1;
  } else if (!args.dryRun) {
    console.log('Bước tiếp: node scripts/import-lesson-videos.js --all');
  }
};

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
