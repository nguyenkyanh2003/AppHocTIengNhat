import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { reviewLessonVideos } from '../src/modules/lessons/lesson-video.review.js';
import { allManifestNames, manifestsByLesson, parseLevel, parseManifestName } from './lesson-video-manifests.js';
import { transcriptSkeleton } from './lesson-video-staging.js';
import { applyTranscripts, parseTranscriptText } from './transcript-text.js';

const BACKEND_DIR = fileURLToPath(new URL('..', import.meta.url));
const MANIFEST_DIR = path.join(BACKEND_DIR, 'data', 'lesson-videos');

const parseArgs = (argv) => {
  const args = { dryRun: false, all: false, level: 'N5' };
  for (let index = 0; index < argv.length; index += 1) {
    const flag = argv[index];
    if (flag === '--dry-run') args.dryRun = true;
    else if (flag === '--all') args.all = true;
    else if (flag === '--lesson') args.lesson = Number(argv[(index += 1)]);
    else if (flag === '--level') args.level = parseLevel(argv[(index += 1)]);
    else throw new Error(`Cờ không nhận ra: ${flag}`);
  }
  if (!args.all === !args.lesson) throw new Error('Cần đúng một trong hai: --all hoặc --lesson <số bài>.');
  return args;
};

/** Bài cần xử lý, lấy theo file mô tả video — đó mới là nơi biết bài có cảnh nào. */
const lessonsToProcess = async (args) => {
  const one = manifestsByLesson(args.level).get(args.lesson);
  const wanted = args.all ? allManifestNames() : one ? [one] : [];
  if (wanted.length === 0) throw new Error(`Không có file mô tả video của ${args.level} bài ${args.lesson}.`);
  return wanted.map((name) => ({ manifest: name, text: name.replace(/\.json$/, '.txt') }));
};

/** Bài chưa có file lời thoại thì tạo khung rồi dừng ở đó, chờ người soạn gõ. */
const createSkeleton = async ({ manifest, manifestName, text, lesson, args }) => {
  const videos = (manifest.videos ?? []).map((video) => ({
    target: video.url.split('/').pop(),
    title: video.title,
  }));
  if (videos.length === 0) {
    console.log(`  ✖ Bài chưa có video nào. Chạy stage-lesson-videos.js trước.`);
    return false;
  }

  console.log(`  📝 ${text} — ${args.dryRun ? 'sẽ tạo' : 'đã tạo'} khung cho ${videos.length} cảnh, chờ gõ câu thoại`);
  if (!args.dryRun) {
    const title = manifest.lesson?.title;
    await fs.writeFile(path.join(MANIFEST_DIR, text), transcriptSkeleton({ lesson, title, videos }));
  }
  return true;
};

const applyOne = async ({ text, manifest: manifestName }, args) => {
  console.log(`\n${manifestName}`);
  const manifest = JSON.parse(await fs.readFile(path.join(MANIFEST_DIR, manifestName), 'utf8'));
  const textPath = path.join(MANIFEST_DIR, text);
  const raw = await fs.readFile(textPath, 'utf8').catch(() => null);
  if (raw === null) {
    return createSkeleton({ manifest, manifestName, text, lesson: parseManifestName(manifestName).lesson, args });
  }

  const { scenes, errors: textErrors } = parseTranscriptText(raw);
  const { manifest: updated, applied, empty, errors: matchErrors } = applyTranscripts({ manifest, scenes });

  // Kiểm bằng chính bộ kiểm lúc nhập DB: sai ở đây thì sửa ngay, không để tới
  // lúc import mới lộ.
  const { errors: reviewErrors } = reviewLessonVideos(updated);
  const errors = [...textErrors, ...matchErrors, ...reviewErrors];

  for (const { name, count, words } of applied) console.log(`  ✓ ${name} — ${count} câu thoại, ${words} từ vựng`);
  for (const name of empty) console.log(`  · ${name} — chưa gõ câu nào, giữ nguyên`);
  for (const error of errors) console.log(`  ✖ ${error}`);
  if (errors.length > 0) {
    console.log('  → Giữ nguyên file mô tả, chưa ghi gì.');
    return false;
  }

  if (!args.dryRun) {
    await fs.writeFile(path.join(MANIFEST_DIR, manifestName), `${JSON.stringify(updated, null, 2)}\n`);
  }
  return true;
};

const main = async () => {
  const args = parseArgs(process.argv.slice(2));
  const lessons = await lessonsToProcess(args);

  let done = 0;
  for (const lesson of lessons) if (await applyOne(lesson, args)) done += 1;

  console.log(`\n📊 ${done}/${lessons.length} bài xử lý xong${args.dryRun ? ' (--dry-run: chưa ghi)' : ''}.`);
  if (done < lessons.length) process.exitCode = 1;
  else if (!args.dryRun) console.log('Bước tiếp: node scripts/import-lesson-videos.js --all');
};

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
