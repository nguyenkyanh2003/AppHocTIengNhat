import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

/**
 * Nơi đặt và cách đặt tên file mô tả video của bài học, dùng chung cho các
 * script stage / nhập lời thoại / nhập DB.
 *
 * Tên file là `<trình độ>-<số bài 2 chữ số>-<tên ngắn>.json`, ví dụ
 * `n5-10-bank.json`, `n4-16-job-hunting.json`: số bài chỉ duy nhất trong một
 * trình độ, nên mọi lệnh làm việc theo số bài đều phải biết trình độ.
 */

export const MANIFEST_DIR = fileURLToPath(new URL('../data/lesson-videos/', import.meta.url));

export const LEVELS = Object.freeze(['N5', 'N4', 'N3', 'N2', 'N1']);

const MANIFEST_NAME = /^(n[1-5])-(\d{2})-.+\.json$/;

/** `{ level: 'N4', lesson: 16 }` từ tên file mô tả, hoặc `null` nếu không đúng mẫu. */
export const parseManifestName = (name) => {
  const match = MANIFEST_NAME.exec(name);
  return match ? { level: match[1].toUpperCase(), lesson: Number(match[2]) } : null;
};

/** Chuẩn hoá giá trị của cờ `--level` (`n4`, `N4`); sai thì báo luôn các giá trị hợp lệ. */
export const parseLevel = (value) => {
  const level = String(value ?? '').toUpperCase();
  if (!LEVELS.includes(level)) throw new Error(`--level phải là một trong ${LEVELS.join(', ')} (đang là "${value}").`);
  return level;
};

/**
 * Tên file mô tả của một trình độ, theo số bài.
 * @returns {Map<number, string>}
 */
export const manifestsByLesson = (level, dir = MANIFEST_DIR) =>
  new Map(
    fs
      .readdirSync(dir)
      .map((name) => ({ name, parsed: parseManifestName(name) }))
      .filter(({ parsed }) => parsed?.level === level)
      .map(({ name, parsed }) => [parsed.lesson, name]),
  );

/** Mọi file mô tả, sắp theo trình độ (N5 trước) rồi theo số bài. */
export const allManifestNames = (dir = MANIFEST_DIR) =>
  fs
    .readdirSync(dir)
    .map((name) => ({ name, parsed: parseManifestName(name) }))
    .filter(({ parsed }) => parsed)
    .sort((a, b) => LEVELS.indexOf(a.parsed.level) - LEVELS.indexOf(b.parsed.level) || a.parsed.lesson - b.parsed.lesson)
    .map(({ name }) => name);

export const manifestPath = (name, dir = MANIFEST_DIR) => path.join(dir, name);
