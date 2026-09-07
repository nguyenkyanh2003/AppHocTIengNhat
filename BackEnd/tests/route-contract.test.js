import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import test from 'node:test';

const routeMounts = new Map([
  ['../src/modules/achievements/achievement.routes.js', '/api/achievement'],
  ['../src/modules/exercise/exercise.routes.js', '/api/exercise'],
  ['../src/modules/flashcards/flashcard.routes.js', '/api/flashcard'],
  ['../src/modules/grammar/grammar.routes.js', '/api/grammar'],
  ['../src/modules/study-groups/group.routes.js', '/api/group'],
  ['../src/modules/chat/group-chat.routes.js', '/api/group-chat'],
  ['../src/modules/jlpt/jlpt.routes.js', '/api/jlpt'],
  ['../src/modules/kanji/kanji.routes.js', '/api/kanji'],
  ['../src/modules/lessons/lesson.routes.js', '/api/lesson'],
  ['../src/modules/lesson-progress/lesson-progress.routes.js', '/api/lesson-progress'],
  ['../src/modules/news/news.routes.js', '/api/news'],
  ['../src/modules/notebook/notebook.routes.js', '/api/notebook'],
  ['../src/modules/notifications/notification.routes.js', '/api/notifications'],
  ['../src/modules/progress/progress.routes.js', '/api/progress'],
  ['../src/modules/reports/report.routes.js', '/api/report'],
  ['../src/modules/settings/settings.routes.js', '/api/settings'],
  ['../src/modules/srs/srs-progress.routes.js', '/api/srs'],
  ['../src/modules/streaks/streak.routes.js', '/api/streak'],
  ['../src/modules/transactions/transaction.routes.js', '/api/transactions'],
  ['../src/modules/users/user.routes.js', '/api/users'],
  ['../src/modules/vocabulary/vocabulary.routes.js', '/api/vocabulary'],
]);

const routePattern = /router\.(get|post|put|patch|delete)\(\s*["']([^"']+)/g;
const expectedCount = 261;
// Update this digest only after intentionally reviewing a public route change.
const expectedSignatureHash = '75d5d6968c84885bee137582512f0de999bcf7b1cd521e245e3ee7c4517e4e66';

const collectSignatures = async () => {
  const signatures = [];

  for (const [fileName, mountPath] of routeMounts) {
    const routeUrl = fileName.startsWith('../')
      ? new URL(fileName, import.meta.url)
      : new URL(`../routes/${fileName}`, import.meta.url);
    const source = await readFile(routeUrl, 'utf8');

    for (const match of source.matchAll(routePattern)) {
      const method = match[1].toUpperCase();
      const localPath = match[2];
      const fullPath = localPath === '/' ? mountPath : `${mountPath}${localPath}`;
      signatures.push(`${method} ${fullPath}`);
    }
  }

  signatures.sort();
  return signatures;
};

test('public API method/path signatures match the reviewed contract', async () => {
  const signatures = await collectSignatures();

  const signatureHash = createHash('sha256')
    .update(signatures.join('\n'))
    .digest('hex');

  assert.equal(signatures.length, expectedCount);
  assert.equal(signatureHash, expectedSignatureHash);
});

test('public API does not declare duplicate method/path pairs', async () => {
  const signatures = await collectSignatures();
  const duplicates = signatures.filter(
    (signature, index) => signature === signatures[index - 1],
  );
  assert.deepEqual(duplicates, []);
});
