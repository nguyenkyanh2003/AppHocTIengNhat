import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import test from 'node:test';

const routeMounts = new Map([
  ['../src/modules/achievements/achievement.routes.js', '/api/achievement'],
  ['../src/modules/exercise/exercise.routes.js', '/api/exercise'],
  ['../src/modules/flashcards/flashcard.routes.js', '/api/flashcard'],
  ['../src/modules/goals/goal.routes.js', '/api/goal'],
  ['../src/modules/grammar/grammar.routes.js', '/api/grammar'],
  ['../src/modules/study-groups/group.routes.js', '/api/group'],
  ['../src/modules/jlpt/jlpt.routes.js', '/api/jlpt'],
  ['../src/modules/kanji/kanji.routes.js', '/api/kanji'],
  ['../src/modules/lessons/lesson.routes.js', '/api/lesson'],
  ['../src/modules/lesson-progress/lesson-progress.routes.js', '/api/lesson-progress'],
  ['../src/modules/news/news.routes.js', '/api/news'],
  ['../src/modules/notebook/notebook.routes.js', '/api/notebook'],
  ['../src/modules/notifications/notification.routes.js', '/api/notifications'],
  ['../src/modules/progress/progress.routes.js', '/api/progress'],
  ['../src/modules/reports/report.routes.js', '/api/report'],
  ['../src/modules/search/search.routes.js', '/api/search'],
  ['../src/modules/settings/settings.routes.js', '/api/settings'],
  ['../src/modules/srs/srs.routes.js', '/api/srs'],
  ['../src/modules/streaks/streak.routes.js', '/api/streak'],
  ['../src/modules/transactions/transaction.routes.js', '/api/transactions'],
  ['../src/modules/users/user.routes.js', '/api/users'],
  ['../src/modules/vocabulary/vocabulary.routes.js', '/api/vocabulary'],
]);

const routePattern = /router\.(get|post|put|patch|delete)\(\s*["']([^"']+)/g;
const expectedCount = 152;
// Update this digest only after intentionally reviewing a public route change.
// 2026-09-14: +1 route `GET /api/lesson/situations` (danh sách tình huống có bài học).
// 2026-09-20: -4 route ở đợt cutover đường ghi hoạt động (spec streak §3.1, §3.6).
//   Gỡ `POST /api/streak/add-xp` (client tự khai số XP), `POST /api/streak/test/reset-yesterday`
//   và `GET /api/streak/test/debug` (công cụ thử nghiệm lọt ra production), cùng
//   `POST /api/achievement/update-progress` (client tự khai tiến độ rồi nhận XP thưởng).
// 2026-09-21: +2 route `GET /api/vocabulary/sets` và `GET /api/vocabulary/sets/:setId`
//   (bộ học ~20 từ theo chủ đề ở N5–N4, theo từ loại + độ khó ở N3–N1).
// 2026-09-23: SRS 12 → 6 route theo spec SRS §3.3: `GET /due`, `GET /due/count`,
//   `GET /stats`, `POST /review`, `POST /items/:itemId/reset`, `DELETE /items/:itemId`;
//   bỏ `/answer/:id`, `/my-cards`, `DELETE /:id`, `PUT /reset/:id` và bốn route `/admin/*`.
//   +1 route `GET /api/streak/days` (lịch học theo khoảng ngày, spec streak §4.3).
// 2026-09-25: +2 route Phần B `GET /api/streak/settings` và `PUT /api/streak/settings`
//   (mục tiêu ngày và nhắc học, spec streak §5.1, §5.3). Không route nào ghi XP.
// 2026-09-28: đợt 0 one-style — gỡ 9 route chat không có consumer (spec one-style §6.1).
// 2026-09-28: đợt 0 one-style — gỡ 21 route jlpt không có consumer (spec one-style §6.1).
// 2026-09-28: đợt 0 one-style — gỡ 10 route exercise không có consumer (spec one-style §6.1).
// 2026-09-28: đợt 0 one-style — gỡ 12 route progress không có consumer (spec one-style §6.1).
// 2026-09-28: đợt 0 one-style — gỡ 11 route transactions không có consumer (spec one-style §6.1).
// 2026-09-28: đợt 0 one-style — gỡ 21 route notifications/news/notebook/reports không có consumer (spec one-style §6.1).
// 2026-09-28: đợt 0 one-style — gỡ 10 route study-groups/users/grammar không có consumer (spec one-style §6.1).
// 2026-09-28: đợt 0 one-style — gỡ 10 route vocabulary/lessons không có consumer (spec one-style §6.1).
// 2026-11-04: Kanji SRS đợt 1 — gỡ `POST /api/kanji/learn/:id` (không tạo thẻ nào), thêm
//   `POST` và `DELETE /api/kanji/:id/mark-learned` (thêm/gỡ thẻ ôn, spec Kanji SRS §2).
// 2026-11-04: +1 route `GET /api/search` (tìm kiếm chung năm nhóm nội dung, phase-2-plan A5);
//   Flutter bỏ năm lời gọi danh sách riêng lẻ.
// 2026-11-04: +4 route `/api/goal` (GET/POST `/`, PATCH/DELETE `/:id`) — mục tiêu học tập
//   tích luỹ lưu theo tài khoản, thay màn mẫu chỉ có dữ liệu viết sẵn (phase-2-plan A8).
// 2026-11-04: +1 route `POST /api/users/refresh-token` — access token còn 15 phút, refresh
//   token xoay vòng theo phiên; `POST /api/users/logout` giữ nguyên path nhưng giờ thu hồi phiên.
// 2026-11-14: one-style đợt 4 (settings) — gỡ `PATCH /api/settings/:setting`: Flutter chỉ đọc
//   và lưu đủ năm cài đặt một lần (`GET`/`POST /api/settings`), không màn hình nào sửa lẻ một mục.
// 2026-11-14: one-style đợt 4 (reports) — gỡ `DELETE /api/report/:id` (người dùng tự huỷ báo cáo):
//   màn "Báo cáo của tôi" chỉ xem, không có nút huỷ nào gọi tới.
// 2026-11-14: one-style đợt 4 (notebook) — gỡ `DELETE /api/notebook` (xoá nhiều),
//   `GET /api/notebook/related/:item_type/:item_id`, `GET /api/notebook/tags/all` và
//   `GET /api/notebook/stats/me`: chỉ có method service Flutter mà không màn hình nào gọi.
// 2026-11-14: one-style (kanji) — gỡ `GET /api/kanji/level/:level` và `GET /api/kanji/lesson/:lessonId`:
//   màn Kanji lọc cấp độ qua `GET /api/kanji?level=`, bài học tự mang danh sách chữ của nó.
const expectedSignatureHash = '3ab64e18d9819bb5bd9fba34648adf3b3a43e71e1d3737421105f83de565bdad';

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
