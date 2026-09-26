import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { parseTranscriptMarkdown, spreadTimecodes } from './transcript-markdown.js';
import { parseTranscriptText } from './transcript-text.js';

/**
 * Nhập tài liệu lời thoại dạng Markdown (mỗi video một bảng Nhật / roma-ji /
 * Việt) thành file lời thoại `data/lesson-videos/<bài>.txt`.
 *
 * File `.txt` vẫn là nguồn sự thật: sau khi nhập, đánh dấu câu then chốt
 * (`*`) và thêm bảng từ vựng ngay trong đó, rồi chạy tiếp
 * `apply-transcript.js` và `import-lesson-videos.js` như mọi khi.
 *
 *   node scripts/import-transcript-markdown.js --file <tài liệu.md> [--file …] --dry-run
 *   node scripts/import-transcript-markdown.js --file <tài liệu.md> [--overwrite]
 *
 * File `.txt` đã có câu thoại hay từ vựng thì không bị đè, trừ khi thêm
 * `--overwrite` — trong đó có thể là công đánh dấu và soạn từ vựng.
 */

const BACKEND_DIR = fileURLToPath(new URL('..', import.meta.url));
const MANIFEST_DIR = path.join(BACKEND_DIR, 'data', 'lesson-videos');

const parseArgs = (argv) => {
  const args = { files: [], dryRun: false, overwrite: false };
  for (let index = 0; index < argv.length; index += 1) {
    const flag = argv[index];
    if (flag === '--dry-run') args.dryRun = true;
    else if (flag === '--overwrite') args.overwrite = true;
    else if (flag === '--file') args.files.push(path.resolve(argv[(index += 1)]));
    else throw new Error(`Cờ không nhận ra: ${flag}`);
  }
  if (args.files.length === 0) throw new Error('Cần ít nhất một --file <tài liệu.md>.');
  return args;
};

/** `ja / romaji / vi` — luôn đủ ba vị trí để bộ đọc biết dạng nào là dạng nào. */
const speakerCell = ({ ja, romaji, vi }) => (ja || romaji || vi ? [ja ?? '', romaji ?? '', vi ?? ''].join(' / ') : '');

const buildText = ({ lessonTitle, source, videos, scenesByFile }) => {
  const out = [
    `# Lời thoại ${lessonTitle}`,
    `# Nhập từ ${source} bằng scripts/import-transcript-markdown.js.`,
    '# Mỗi dòng một câu: mốc | người nói JA / roma-ji / VI | câu tiếng Nhật | roma-ji | nghĩa tiếng Việt',
    '# Dấu * trước mốc = câu then chốt (phần "Mẫu câu"). Bảng từ ghi sau "### từ vựng" của từng cảnh.',
  ];
  for (const video of videos) {
    const fileName = video.url.split('/').pop();
    const lines = scenesByFile.get(fileName);
    if (!lines) continue;
    const starts = spreadTimecodes(lines);
    out.push('', `## ${fileName}`, `# ${video.title}`);
    lines.forEach((line, index) => {
      out.push([starts[index], speakerCell(line.speaker), line.textJa, line.romaji ?? '', line.textVi].join(' | '));
    });
  }
  return `${out.join('\n')}\n`;
};

const manifestsByLesson = async () => {
  const names = (await fs.readdir(MANIFEST_DIR)).filter((name) => /^n5-\d{2}-.+\.json$/.test(name));
  return new Map(names.map((name) => [Number(name.slice(3, 5)), name]));
};

const importLesson = async ({ lesson, scenesByFile, source, manifestName, args }) => {
  const manifest = JSON.parse(await fs.readFile(path.join(MANIFEST_DIR, manifestName), 'utf8'));
  const known = new Set(manifest.videos.map((video) => video.url.split('/').pop()));
  const unknown = [...scenesByFile.keys()].filter((name) => !known.has(name));
  const textName = manifestName.replace(/\.json$/, '.txt');

  console.log(`\nBài ${lesson} → ${textName}`);
  if (unknown.length > 0) {
    console.log(`  ✖ Tài liệu có video không có trong bài: ${unknown.join(', ')}.`);
    return false;
  }

  const text = buildText({ lessonTitle: manifest.lesson.title, source, videos: manifest.videos, scenesByFile });
  const { scenes, errors } = parseTranscriptText(text);
  if (errors.length > 0) {
    errors.forEach((error) => console.log(`  ✖ ${error}`));
    return false;
  }
  for (const [name, scene] of scenes) console.log(`  ✓ ${name} — ${scene.lines.length} câu`);

  const textPath = path.join(MANIFEST_DIR, textName);
  const existing = await fs.readFile(textPath, 'utf8').catch(() => null);
  if (existing !== null && !args.overwrite) {
    const typed = [...parseTranscriptText(existing).scenes.values()].some(
      (scene) => scene.lines.length > 0 || scene.vocabulary.length > 0,
    );
    if (typed) {
      console.log(`  ⚠️  ${textName} đã có nội dung — giữ nguyên. Thêm --overwrite để thay.`);
      return false;
    }
  }
  if (!args.dryRun) await fs.writeFile(textPath, text);
  return true;
};

const main = async () => {
  const args = parseArgs(process.argv.slice(2));
  const manifests = await manifestsByLesson();
  let written = 0;
  let failed = 0;

  for (const file of args.files) {
    const { lessons, errors } = parseTranscriptMarkdown(await fs.readFile(file, 'utf8'));
    const source = path.basename(file);
    if (errors.length > 0) {
      console.log(`\n${source}:`);
      errors.forEach((error) => console.log(`  ✖ ${error}`));
      failed += 1;
      continue;
    }
    for (const [lesson, scenesByFile] of lessons) {
      const manifestName = manifests.get(lesson);
      if (!manifestName) {
        console.log(`\nBài ${lesson}: chưa có file mô tả video n5-${String(lesson).padStart(2, '0')}-*.json.`);
        failed += 1;
      } else if (await importLesson({ lesson, scenesByFile, source, manifestName, args })) {
        written += 1;
      } else {
        failed += 1;
      }
    }
  }

  console.log(`\n📊 ${written} bài ${args.dryRun ? 'sẽ được ghi (--dry-run)' : 'đã ghi'}${failed ? `, ${failed} bài lỗi hoặc bỏ qua` : ''}.`);
  if (failed > 0) process.exitCode = 1;
  else if (!args.dryRun) console.log('Bước tiếp: node scripts/apply-transcript.js --all && node scripts/import-lesson-videos.js --all');
};

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
