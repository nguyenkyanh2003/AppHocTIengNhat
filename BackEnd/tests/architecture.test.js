import assert from 'node:assert/strict';
import fs from 'node:fs';
import test from 'node:test';

/**
 * Máy kiểm "một kiểu" của backend (spec one-style §3.3): mọi module đi đúng bốn
 * tầng routes → controller → service → repository, không cần MongoDB để kiểm.
 *
 * Module chưa chuyển khuôn nằm trong `LEGACY_MODULES`. Chuyển xong module nào
 * thì gỡ tên nó khỏi danh sách; danh sách phải rỗng khi đợt chuyển khuôn kết thúc.
 */
const LEGACY_MODULES = [
  'exercise',
  'flashcards',
  'jlpt',
  'study-groups',
  'users',
];

const MODULES_DIR = new URL('../src/modules/', import.meta.url);
const LAYERS = ['routes', 'schema', 'controller', 'service', 'repository'];

const modules = fs
  .readdirSync(MODULES_DIR, { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name);

const filesOf = (moduleName, layer) =>
  fs
    .readdirSync(new URL(`${moduleName}/`, MODULES_DIR))
    .filter((file) => file.endsWith(`.${layer}.js`))
    .map((file) => ({
      name: `${moduleName}/${file}`,
      source: fs.readFileSync(new URL(`${moduleName}/${file}`, MODULES_DIR), 'utf8'),
    }));

const IMPORTS_DATABASE = /from\s+['"](?:mongoose|[^'"]*\/model\/[^'"]*)['"]/;

/** Từng lời khai `router.<method>(...)`, tính cả lời khai viết trên nhiều dòng. */
const routeDeclarations = (source) =>
  source.split(/(?=\brouter\.(?:get|post|put|patch|delete)\()/).slice(1);

/** Mọi chỗ một module còn lệch khuôn; mảng rỗng là module đã theo khuôn. */
const violationsOf = (moduleName) => {
  const found = [];
  for (const layer of LAYERS) {
    if (filesOf(moduleName, layer).length === 0) found.push(`${moduleName}: thiếu file *.${layer}.js`);
  }
  for (const { name, source } of filesOf(moduleName, 'controller')) {
    if (/\btry\s*\{/.test(source)) found.push(`${name}: controller tự try/catch`);
    if (IMPORTS_DATABASE.test(source)) found.push(`${name}: controller import model hoặc mongoose`);
  }
  for (const { name, source } of filesOf(moduleName, 'service')) {
    if (IMPORTS_DATABASE.test(source)) found.push(`${name}: service import model hoặc mongoose`);
    if (/\b(?:req|res)\./.test(source)) found.push(`${name}: service chạm req/res`);
  }
  for (const { name, source } of filesOf(moduleName, 'routes')) {
    const bare = routeDeclarations(source).filter((declaration) => !declaration.includes('asyncHandler('));
    if (bare.length > 0) found.push(`${name}: ${bare.length} route không bọc asyncHandler`);
  }
  return found;
};

test('module ngoài danh sách miễn đi đúng bốn tầng', () => {
  const violations = modules
    .filter((moduleName) => !LEGACY_MODULES.includes(moduleName))
    .flatMap(violationsOf);

  assert.deepEqual(violations, []);
});

test('danh sách miễn chỉ chứa module có thật và còn lệch khuôn', () => {
  const missing = LEGACY_MODULES.filter((moduleName) => !modules.includes(moduleName));
  assert.deepEqual(missing, [], 'tên trong LEGACY_MODULES không còn là thư mục');

  const alreadyClean = LEGACY_MODULES.filter(
    (moduleName) => modules.includes(moduleName) && violationsOf(moduleName).length === 0,
  );
  assert.deepEqual(alreadyClean, [], 'module đã theo khuôn thì gỡ khỏi LEGACY_MODULES');
});
