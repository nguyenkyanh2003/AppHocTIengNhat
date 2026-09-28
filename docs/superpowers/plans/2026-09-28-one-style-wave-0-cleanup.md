# Đợt 0 — Xoá code không ai dùng — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Gỡ 104 route backend không có consumer trong Flutter cùng handler, helper, test chỉ phục vụ chúng, và 5 method/1 file Flutter chết — để các đợt sau chỉ phải chuyển khuôn cho code đang thật sự chạy.

**Architecture:** Chỉ xoá, không refactor code còn lại. Mỗi nhóm module là một commit tự xanh: thêm path đã gỡ vào bảng `REMOVED_ROUTES` của `tests/app.smoke.test.js` (test đỏ: hiện ra 401), xoá route + handler + import mồ côi, cập nhật `route-contract.test.js` bằng đúng count/hash tính trước trong bảng dưới, chạy `npm test`. Flutter một commit cuối.

**Tech Stack:** Node 22, Express 5, Mongoose 8, `node --test` + supertest; Flutter 3.29, `dart analyze`, `flutter test`.

**Spec:** [2026-09-28-one-style-refactor-design.md §6](../specs/2026-09-28-one-style-refactor-design.md)

## Global Constraints

- Không xoá model, collection, dữ liệu MongoDB, hay file trong `BackEnd/uploads/` (kể cả `uploads/group-chats/`).
- Không sửa hành vi của route còn lại; không chuyển khuôn ở đợt này. Chỉ xoá route, handler, helper/import mồ côi và test của chúng.
- Sau mỗi task backend: `expectedCount` và `expectedSignatureHash` trong `BackEnd/tests/route-contract.test.js` phải **khớp đúng** bảng "Count/hash sau mỗi task". Lệch là đã xoá thừa hoặc thiếu — dừng lại rà, không sửa hash cho khớp.
- Mọi test không chạm MongoDB.
- `dart analyze` sạch tuyệt đối: 0 error, 0 warning, 0 info.
- Commit theo Conventional Commits, tiếng Anh, thân commit giải thích vì sao. Làm trên nhánh `refactor/one-style`.
- Mốc xuất phát: commit `74ba515`; `npm test` 665 pass; `flutter test` 373 pass; `dart analyze` sạch. Số dòng trong plan tính ở mốc này.

## Review Focus

1. **Route bị xoá thật ra có màn hình gọi qua path dựng động** → màn hình đó gãy với 404. Chặn bằng: kiểm tra tay trong bước "Rà tham chiếu" của mỗi task, và danh sách màn hình chạy thử ở Task 10.
2. **Path cũ rơi vào một route tham số còn lại** (ví dụ `GET /api/vocabulary/situations` giờ khớp `GET /api/vocabulary/:id`) → phải bị validate chặn 400, không được tới handler. Test ở Task 8.
3. **Import bị xoá hoá ra vẫn được dùng** (ví dụ `dotenv.config()` ở đầu `progress.controller.js` là lời gọi cấp module) → `ReferenceError` chỉ nổ khi handler còn lại chạy, không test nào bắt. Chặn bằng: mỗi task chỉ xoá đúng danh sách import đã kiểm, và chạy lệnh `grep -nw` xác nhận tên đó không còn xuất hiện trong file.
4. **Màn quản trị dùng route còn giữ** (giao dịch: danh sách + đổi trạng thái; người dùng: danh sách/sửa/xoá; báo cáo: danh sách/đổi trạng thái/xoá) vẫn phải chạy. Test `transaction.admin-filter.test.js` giữ lại ca `admin/all` (Task 5); phần còn lại chạy thử ở Task 10.
5. **Mở chi tiết ngữ pháp sau khi bỏ lời gọi đếm lượt xem** vẫn hiện nội dung và không đổi trạng thái lỗi. Kiểm ở Task 9 bằng `flutter test` + chạy thử ở Task 10.

## Công cụ dùng chung

`TOOLS` = `C:/Users/PC_KyAnh/AppData/Local/Temp/claude/e--GR2-AppHocTiengNhat/77860920-5ca7-4dab-af08-71d57e3866b4/scratchpad`.
Nếu `$TOOLS/route-signatures.mjs` chưa có, tạo lại với nội dung:

```js
// Run from BackEnd/: node <this file> [--list]
// Prints the route count and sha256 exactly as tests/route-contract.test.js computes them.
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';

const testSource = await readFile('tests/route-contract.test.js', 'utf8');
const mounts = [...testSource.matchAll(/\['\.\.\/([^']+)', '([^']+)'\]/g)];
const routePattern = /router\.(get|post|put|patch|delete)\(\s*["']([^"']+)/g;

const signatures = [];
for (const [, file, mount] of mounts) {
  const source = await readFile(file, 'utf8');
  for (const match of source.matchAll(routePattern)) {
    const localPath = match[2];
    signatures.push(`${match[1].toUpperCase()} ${localPath === '/' ? mount : `${mount}${localPath}`}`);
  }
}
signatures.sort();

if (process.argv.includes('--list')) console.log(signatures.join('\n'));
console.log(`count=${signatures.length}`);
console.log(`hash=${createHash('sha256').update(signatures.join('\n')).digest('hex')}`);
```

Ở mốc xuất phát lệnh `cd BackEnd && node $TOOLS/route-signatures.mjs` in `count=257`,
`hash=141cc9f0228b58871049fb8afb2f754cad77ec56b60e6a5deedbc9c1a0956463`. Lưu danh sách gốc
một lần trước Task 1: `node $TOOLS/route-signatures.mjs --list > $TOOLS/route-signatures-before.txt`.

**Count/hash sau mỗi task** (tính trước bằng cách bỏ đúng các chữ ký trong §6.1 của spec):

| Sau task | expectedCount | expectedSignatureHash |
| --- | --- | --- |
| 1 — chat | 248 | `5ba4c30391ee023160f3e431db859bf049800090a8927c0c171f3a1cc8f31518` |
| 2 — jlpt | 227 | `a303670f411e756d632d8a009d17125713b4ec4cfb79fefc0857da32fa82723a` |
| 3 — exercise | 217 | `72fffeba1443feff51e3d61ee3ded46fd8a3123570eb717e9e4601e1d14f28ff` |
| 4 — progress | 205 | `604e9434e939771ddaa19846b3aadb7a5c17067260c31fa4592e8f3f4ef856ca` |
| 5 — transactions | 194 | `3dd6b3c5dfe5e6d5052586291a6893e2215a369b5ed476827845d25906f82ba9` |
| 6 — notifications/news/notebook/reports | 173 | `593e5ebc29270d8da307af0b4bee7360cb81ecf49ea65df6f76e1fb51895e9ac` |
| 7 — study-groups/users/grammar | 163 | `2d31e5117b3c119a3d58e733bcab0cbd38fe966f413fcb5461fc1c1c4147124c` |
| 8 — vocabulary/lessons | 153 | `ca403daf7d140e9664b75f5124bc924dfbcbb131d19f8d78041f5dff8ad4a2fe` |

Mỗi lần cập nhật hash, thêm một dòng chú thích phía trên `expectedSignatureHash` theo mẫu:
`// 2026-09-28: đợt 0 one-style — gỡ <n> route <module> không có consumer (spec one-style §6.1).`

---

### Task 1: Gỡ module chat và dựng bảng route đã gỡ

**Files:**
- Delete: `BackEnd/src/modules/chat/group-chat.controller.js`, `BackEnd/src/modules/chat/group-chat.routes.js`
- Modify: `BackEnd/src/app.js:14,60,87`
- Modify: `BackEnd/tests/route-contract.test.js:12,26,40`
- Test: `BackEnd/tests/app.smoke.test.js`

**Interfaces:**
- Produces: hằng `REMOVED_ROUTES` (mảng `[method, path]`) và test `route không còn consumer đã bị gỡ khỏi app thật` trong `tests/app.smoke.test.js`; các task 2–8 thêm dòng vào mảng này.

- [ ] **Step 1: Viết test đỏ**

Thêm vào cuối `BackEnd/tests/app.smoke.test.js`:

```js
/**
 * Route không màn hình nào gọi, đã gỡ ở đợt 0 (spec one-style §6.1).
 *
 * Mỗi path được chọn sao cho **không** khớp route tham số nào còn lại, nên phải
 * ra đúng 404 của notFoundHandler — không tới middleware auth hay handler nào.
 */
const REMOVED_ROUTES = [
  // chat
  ['post', '/api/group-chat/507f1f77bcf86cd799439011'],
  ['get', '/api/group-chat/507f1f77bcf86cd799439011'],
];

test('route không còn consumer đã bị gỡ khỏi app thật', async () => {
  for (const [method, path] of REMOVED_ROUTES) {
    const response = await request(app)[method](path).send({});
    assert.equal(response.status, 404, `${method.toUpperCase()} ${path} phải 404`);
    assert.deepEqual(response.body, { message: 'API không tồn tại' });
  }
});
```

- [ ] **Step 2: Chạy để thấy đỏ**

Run: `cd BackEnd && node --test tests/app.smoke.test.js`
Expected: FAIL ở test mới — `POST /api/group-chat/... phải 404`, actual `401`.

- [ ] **Step 3: Rà tham chiếu**

Run: `cd .. && grep -rn "modules/chat\|group-chat" BackEnd/src BackEnd/tests BackEnd/scripts FrontEnd/lib`
Expected: chỉ các dòng trong `BackEnd/src/app.js`, `BackEnd/src/modules/chat/`, `BackEnd/tests/route-contract.test.js`. Có dòng nào khác thì dừng lại hỏi.

- [ ] **Step 4: Xoá module và gỡ mount**

- Xoá thư mục `BackEnd/src/modules/chat/` (hai file).
- `BackEnd/src/app.js`: xoá dòng `import GroupChatRoutes from './modules/chat/group-chat.routes.js';`, dòng `app.use('/api/group-chat', GroupChatRoutes);` và phần tử `'/api/group-chat',` trong mảng `endpoints` của `GET /`.
- `BackEnd/tests/route-contract.test.js`: xoá dòng `['../src/modules/chat/group-chat.routes.js', '/api/group-chat'],` trong `routeMounts`.
- Giữ nguyên `BackEnd/model/GroupChat.js` (study-groups còn dùng).

- [ ] **Step 5: Cập nhật contract**

Run: `cd BackEnd && node $TOOLS/route-signatures.mjs`
Expected: `count=248`, `hash=5ba4c30391ee023160f3e431db859bf049800090a8927c0c171f3a1cc8f31518`.
Sửa `expectedCount = 248`, `expectedSignatureHash = '5ba4c30391ee023160f3e431db859bf049800090a8927c0c171f3a1cc8f31518'` và thêm dòng chú thích `// 2026-09-28: đợt 0 one-style — gỡ 9 route chat không có consumer (spec one-style §6.1).`

- [ ] **Step 6: Chạy toàn bộ test backend**

Run: `cd BackEnd && npm test`
Expected: `# fail 0`.

- [ ] **Step 7: Commit**

```bash
git add -A BackEnd/src/modules/chat BackEnd/src/app.js BackEnd/tests/route-contract.test.js BackEnd/tests/app.smoke.test.js
git commit -m "refactor(chat): remove group chat API" -m "The Flutter chat UI was removed earlier and no client calls these nine routes. Keeping them means converting and testing code nobody runs. GroupChat model and stored uploads stay because study groups still write system messages."
```

---

### Task 2: Gỡ API quản trị và lịch sử JLPT

**Files:**
- Modify: `BackEnd/src/modules/jlpt/jlpt.routes.js` (thay toàn bộ)
- Modify: `BackEnd/src/modules/jlpt/jlpt.controller.js:1-12,287-1283`
- Modify: `BackEnd/tests/route-contract.test.js`, `BackEnd/tests/app.smoke.test.js`

**Interfaces:**
- Consumes: `REMOVED_ROUTES` từ Task 1.
- Produces: `jlpt.controller.js` chỉ còn `listExams`, `getPracticeQuestions`, `getSolutions`, `getExam`, `submitExamHandler`.

- [ ] **Step 1: Thêm dòng vào `REMOVED_ROUTES`**

```js
  // jlpt
  ['get', '/api/jlpt/admin/all'],
  ['get', '/api/jlpt/history/me'],
  ['post', '/api/jlpt/submit/507f1f77bcf86cd799439011'],
```

- [ ] **Step 2: Chạy để thấy đỏ**

Run: `cd BackEnd && node --test tests/app.smoke.test.js`
Expected: FAIL — `GET /api/jlpt/admin/all phải 404`, actual `401`.

- [ ] **Step 3: Rà tham chiếu**

Run: `cd .. && grep -rnE "createExam|setPublishStatus|updateExam|updateReadingGroup|updateListeningGroup|importQuestions|getAnswers|getHistoryDetail|addMojiGoiQuestion|addBunpouQuestion|addDokkaiGroup|addChoukaiGroup|deleteQuestionGroup|getExamStats|getExamResults|listAdminExams" BackEnd/src BackEnd/tests BackEnd/scripts`
Expected: chỉ trong `jlpt.routes.js` và `jlpt.controller.js`.
Run: `grep -rnE "/jlpt/(admin|history|answers|stats|results|publish|reading|listening|question|group|importExcel|submit/)" FrontEnd/lib`
Expected: không có dòng nào.

- [ ] **Step 4: Thay `jlpt.routes.js`**

```js
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import * as schema from './jlpt.schema.js';
import express from 'express';
import { authenticateUser } from '../../middleware/auth.middleware.js';
import * as controller from './jlpt.controller.js';

const router = express.Router();

router.get('/', authenticateUser, controller.listExams);
router.get('/practice', authenticateUser, controller.getPracticeQuestions);
router.get('/:id/solutions', authenticateUser, controller.getSolutions);
router.get('/:id', authenticateUser, controller.getExam);
router.post(
    '/:id/submit',
    authenticateUser,
    validate({ params: schema.submitParams, body: schema.submitBody }),
    asyncHandler(controller.submitExamHandler),
);

export default router;
```

- [ ] **Step 5: Xoá handler trong `jlpt.controller.js`**

- Xoá dòng 12 `export const upload = multer({ storage: multer.memoryStorage() });` (và comment ngay trên nếu có).
- Xoá từ comment đứng ngay trên `export const createExam` (quanh dòng 286) tới hết file — vùng này chỉ gồm 20 handler bị gỡ: `createExam` … `listAdminExams`. Sau khi xoá, dòng cuối file là `};` đóng `submitExamHandler`.
- Xoá các import: `isDuplicateKeyError` (dòng 3), `multer` (4), `xlsx` (5), `Grammar` (9), `scoreExamAnswers` (10).

Run: `cd BackEnd && for id in multer xlsx Grammar isDuplicateKeyError scoreExamAnswers upload; do grep -nw "$id" src/modules/jlpt/jlpt.controller.js; done`
Expected: không in dòng nào.
Run: `node --check src/modules/jlpt/jlpt.controller.js`
Expected: không lỗi.

- [ ] **Step 6: Cập nhật contract**

Run: `node $TOOLS/route-signatures.mjs` → Expected `count=227`, `hash=a303670f411e756d632d8a009d17125713b4ec4cfb79fefc0857da32fa82723a`.
Ghi vào `route-contract.test.js` kèm chú thích `// 2026-09-28: đợt 0 one-style — gỡ 21 route jlpt không có consumer (spec one-style §6.1).`

- [ ] **Step 7: Chạy toàn bộ test backend**

Run: `npm test` → Expected `# fail 0`.

- [ ] **Step 8: Commit**

```bash
git add BackEnd/src/modules/jlpt BackEnd/tests/route-contract.test.js BackEnd/tests/app.smoke.test.js
git commit -m "refactor(jlpt): remove admin and history endpoints with no client" -m "No Flutter screen manages exams or reads exam history; these routes only surfaced as silent bugs (history queried user_id/exam_id, which LearningHistory does not have). Exams are loaded by seed/import scripts. The duplicate POST /submit/:id is dropped in favour of /:id/submit, which the app uses."
```

---

### Task 3: Gỡ API quản trị bài tập và xem đáp án

**Files:**
- Modify: `BackEnd/src/modules/exercise/exercise.routes.js` (thay toàn bộ)
- Modify: `BackEnd/src/modules/exercise/exercise.controller.js:1-14,125-160,213-238,278-614`
- Modify: `BackEnd/tests/route-contract.test.js`, `BackEnd/tests/app.smoke.test.js`

**Interfaces:**
- Consumes: `REMOVED_ROUTES`.
- Produces: `exercise.controller.js` chỉ còn `listByLevel`, `listByType`, `listByLesson`, `submitExercise`, `getMyHistory`, `getMyResult`, `getExercise` (test `exercise.list-dto.test.js` import ba hàm đầu).

- [ ] **Step 1: Thêm dòng vào `REMOVED_ROUTES`**

```js
  // exercise
  ['get', '/api/exercise/check-answers/507f1f77bcf86cd799439011'],
  ['post', '/api/exercise/upload/507f1f77bcf86cd799439011'],
  ['post', '/api/exercise/questions/507f1f77bcf86cd799439011'],
```

- [ ] **Step 2: Chạy để thấy đỏ**

Run: `cd BackEnd && node --test tests/app.smoke.test.js` → Expected FAIL (`401`).

- [ ] **Step 3: Rà tham chiếu**

Run: `cd .. && grep -rnE "checkAnswers|getMyResultsForExercise|createExercise|updateExercise|deleteExercise|addQuestion|updateQuestion|deleteQuestion|getAdminResult|uploadQuestions" BackEnd/src/modules/exercise BackEnd/tests BackEnd/scripts`
Expected: chỉ trong `exercise.routes.js` và `exercise.controller.js`.
Run: `grep -rnE "check-answers|my-results|/exercise/(questions|upload|admin)" FrontEnd/lib` → Expected: không có dòng nào.

- [ ] **Step 4: Thay `exercise.routes.js`**

```js
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import * as schema from './exercise.schema.js';
import express from 'express';
import { authenticateUser } from '../../middleware/auth.middleware.js';
import * as controller from './exercise.controller.js';

const router = express.Router();

router.get("/level/:level", authenticateUser, controller.listByLevel);
router.get("/type/:type", authenticateUser, controller.listByType);
router.get("/lesson/:lessonID", authenticateUser, controller.listByLesson);
router.post(
    "/submit/:id",
    authenticateUser,
    validate({ params: schema.submitParams, body: schema.submitBody }),
    asyncHandler(controller.submitExercise),
);
router.get("/history", authenticateUser, controller.getMyHistory);
router.get("/result/:resultId", authenticateUser, controller.getMyResult);
router.get("/:id", authenticateUser, controller.getExercise);

export default router;
```

- [ ] **Step 5: Xoá handler trong `exercise.controller.js`**

- Xoá `export const upload = multer({ … });` (dòng 11, kèm comment ngay trên).
- Xoá khối `export const checkAnswers` (dòng 124–160, kể cả comment `// Xem đáp án (sau khi làm xong)`).
- Xoá khối `export const getMyResultsForExercise` (dòng 212–238, kể cả comment ngay trên).
- Xoá từ comment `// ADMIN ROUTES` đứng trên `export const createExercise` (quanh dòng 275) tới hết file: `createExercise`, `updateExercise`, `deleteExercise`, `addQuestion`, `updateQuestion`, `deleteQuestion`, `getAdminResult`, `uploadQuestions`.
- Xoá các import: `multer` (dòng 2), `xlsx` (3), `Lesson` (6), `isDuplicateKeyError` (7), `scoreExerciseAnswers` (9).

Run: `cd BackEnd && for id in multer xlsx Lesson isDuplicateKeyError scoreExerciseAnswers upload; do grep -nw "$id" src/modules/exercise/exercise.controller.js; done`
Expected: không in dòng nào.
Run: `node --check src/modules/exercise/exercise.controller.js` → Expected: không lỗi.

- [ ] **Step 6: Cập nhật contract**

Run: `node $TOOLS/route-signatures.mjs` → Expected `count=217`, `hash=72fffeba1443feff51e3d61ee3ded46fd8a3123570eb717e9e4601e1d14f28ff`. Ghi vào test kèm chú thích `… gỡ 10 route exercise …`.

- [ ] **Step 7: Chạy toàn bộ test backend**

Run: `npm test` → Expected `# fail 0`.

- [ ] **Step 8: Commit**

```bash
git add BackEnd/src/modules/exercise BackEnd/tests/route-contract.test.js BackEnd/tests/app.smoke.test.js
git commit -m "refactor(exercise): remove admin CRUD and answer-reveal endpoints" -m "No screen manages exercises; content comes from seed-exercises.js. check-answers also let a learner read the key after one attempt and farm XP on resubmission, so it goes with the rest."
```

---

### Task 4: Gỡ phần progress cũ đã được lesson-progress thay

**Files:**
- Modify: `BackEnd/src/modules/progress/progress.routes.js` (thay toàn bộ)
- Modify: `BackEnd/src/modules/progress/progress.controller.js:1-10,36-470`
- Modify: `BackEnd/tests/route-contract.test.js`, `BackEnd/tests/app.smoke.test.js`

**Interfaces:**
- Produces: `progress.controller.js` chỉ còn `getMyProgress`, `getDashboardStats`, `getDashboardTimeline`, `getDashboardHeatmap`, `getDashboardBreakdown`; `analytics.controller.js` không đổi.

- [ ] **Step 1: Thêm dòng vào `REMOVED_ROUTES`**

```js
  // progress
  ['get', '/api/progress/study-time'],
  ['delete', '/api/progress/admin/bulk/delete'],
  ['post', '/api/progress/lesson/507f1f77bcf86cd799439011/update'],
```

- [ ] **Step 2: Chạy để thấy đỏ**

Run: `cd BackEnd && node --test tests/app.smoke.test.js` → Expected FAIL (`401`).

- [ ] **Step 3: Rà tham chiếu**

Run: `cd .. && grep -rnE "getLessonProgress|updateLessonProgress|getStudyTime|getRecentAchievements|deleteLessonProgress|listAdminProgress|getAdminUserProgress|updateAdminProgress|deleteAdminProgress|deleteManyProgress|clearUserProgress" BackEnd/src BackEnd/tests BackEnd/scripts`
Expected: chỉ trong `progress.routes.js` và `progress.controller.js`.
Run: `grep -rnE "progress/(lesson|study-time|achievements|admin)" FrontEnd/lib`
Expected: chỉ `'/progress/admin/analytics…'` trong `admin_service.dart` (route này được giữ).

- [ ] **Step 4: Thay `progress.routes.js`**

```js
import express from 'express';
import { authenticateAdmin, authenticateUser } from '../../middleware/auth.middleware.js';
import * as controller from './progress.controller.js';
import { getAdminAnalytics } from './analytics.controller.js';

const router = express.Router();

router.get("/", authenticateUser, controller.getMyProgress);
router.get("/admin/analytics", authenticateAdmin, getAdminAnalytics);
router.get('/dashboard/stats', authenticateUser, controller.getDashboardStats);
router.get('/dashboard/timeline', authenticateUser, controller.getDashboardTimeline);
router.get('/dashboard/heatmap', authenticateUser, controller.getDashboardHeatmap);
router.get('/dashboard/breakdown', authenticateUser, controller.getDashboardBreakdown);

export default router;
```

- [ ] **Step 5: Xoá handler trong `progress.controller.js`**

- Xoá từ comment đứng ngay trên `export const getLessonProgress` (quanh dòng 35) tới hết dấu `};` đóng `clearUserProgress` (quanh dòng 470): 12 handler `getLessonProgress` … `clearUserProgress`. Khối `getMyProgress` phía trên và `getDashboardStats` trở xuống giữ nguyên.
- Xoá import `Lesson` (dòng 2) và `User` (dòng 3).
- Dòng 6 đổi thành `import { convertDatesToVietnam } from "../../shared/utils/timezone.js";` (bỏ `getVietnamTime`).
- **Giữ** `import dotenv from "dotenv";` và `dotenv.config();` — đây là lời gọi cấp module, không phải import thừa.

Run: `cd BackEnd && for id in Lesson User getVietnamTime; do grep -nw "$id" src/modules/progress/progress.controller.js; done`
Expected: không in dòng nào.
Run: `grep -nw convertDatesToVietnam src/modules/progress/progress.controller.js | wc -l`
Expected: lớn hơn 1 (còn được dùng). Nếu bằng 1 thì xoá luôn import đó.
Run: `node --check src/modules/progress/progress.controller.js` → Expected: không lỗi.

- [ ] **Step 6: Cập nhật contract**

Run: `node $TOOLS/route-signatures.mjs` → Expected `count=205`, `hash=604e9434e939771ddaa19846b3aadb7a5c17067260c31fa4592e8f3f4ef856ca`. Ghi kèm chú thích `… gỡ 12 route progress …`.

- [ ] **Step 7: Chạy toàn bộ test backend**

Run: `npm test` → Expected `# fail 0`.

- [ ] **Step 8: Commit**

```bash
git add BackEnd/src/modules/progress BackEnd/tests/route-contract.test.js BackEnd/tests/app.smoke.test.js
git commit -m "refactor(progress): remove legacy lesson-progress and admin endpoints" -m "These handlers treated LearningHistory as lesson progress with fields (NguoiHocID, BaiHocID, TienDo) the model does not have, and no client calls them; lesson progress lives in the lesson-progress module. The dashboard and admin analytics routes the app uses stay."
```

---

### Task 5: Gỡ các route giao dịch không dùng

**Files:**
- Modify: `BackEnd/src/modules/transactions/transaction.routes.js` (thay toàn bộ)
- Modify: `BackEnd/src/modules/transactions/transaction.controller.js:14,35-60,80-110,144-153,171-269`
- Modify: `BackEnd/tests/transaction.admin-filter.test.js`
- Modify: `BackEnd/tests/route-contract.test.js`, `BackEnd/tests/app.smoke.test.js`

**Interfaces:**
- Produces: `transaction.controller.js` chỉ còn `postCreate`, `getAdminAll`, `putAdminByIdStatus` cùng các helper chúng dùng.

- [ ] **Step 1: Thêm dòng vào `REMOVED_ROUTES`**

```js
  // transactions
  ['get', '/api/transactions/my-transactions'],
  ['post', '/api/transactions/admin/507f1f77bcf86cd799439011/refund'],
  ['get', '/api/transactions/admin/stats/overview'],
```

- [ ] **Step 2: Chạy để thấy đỏ**

Run: `cd BackEnd && node --test tests/app.smoke.test.js` → Expected FAIL (`401`).

- [ ] **Step 3: Rà tham chiếu**

Run: `cd .. && grep -rnE "getMyTransactions|putByIdCancel|getStatsMe|getAdminById|putAdminById\b|deleteAdminById|deleteAdminBulkDelete|getAdminStatsOverview|getAdminUserByUserId|postAdminByIdRefund" BackEnd/src/modules/transactions BackEnd/tests BackEnd/scripts`
Expected: trong `transaction.routes.js`, `transaction.controller.js` và `tests/transaction.admin-filter.test.js` (chỉ `getAdminUserByUserId`).
Run: `grep -rn "/transactions" FrontEnd/lib`
Expected: chỉ `'/transactions/create'`, `'/transactions/admin/all…'`, `'/transactions/admin/$id/status'`.

- [ ] **Step 4: Thay `transaction.routes.js`**

```js
import express from 'express';
import { authenticateUser, authenticateAdmin } from '../../middleware/auth.middleware.js';
import * as controller from './transaction.controller.js';

const router = express.Router();

router.post("/create", authenticateUser, controller.postCreate);
router.get("/admin/all", authenticateAdmin, controller.getAdminAll);
router.put("/admin/:id/status", authenticateAdmin, controller.putAdminByIdStatus);

export default router;
```

- [ ] **Step 5: Xoá handler trong `transaction.controller.js`**

Xoá các khối (kể cả comment ngay trên mỗi khối): `getMyTransactions`, `getById`, `putByIdCancel`, `getStatsMe`, `getAdminById`, `putAdminById`, `deleteAdminById`, `deleteAdminBulkDelete`, `getAdminStatsOverview`, `getAdminUserByUserId`, `postAdminByIdRefund`. Xoá helper `const objectId = (value) => new mongoose.Types.ObjectId(value.toString());` (dòng 14) — chỉ `getStatsMe` dùng nó. Giữ `mongoose` (còn dùng trong `sendError`), `pagination`, `transactionInput`, `sendError` và mọi helper mà `getAdminAll` dùng.

Run: `cd BackEnd && grep -nw objectId src/modules/transactions/transaction.controller.js`
Expected: không in dòng nào.
Run: `node --check src/modules/transactions/transaction.controller.js` → Expected: không lỗi.
Run: `grep -nE "^(const|export const) " src/modules/transactions/transaction.controller.js` rồi với mỗi `const` không export, `grep -cw <tên>` phải lớn hơn 1. Helper nào chỉ còn 1 lần xuất hiện (chính dòng khai báo) thì xoá.

- [ ] **Step 6: Sửa `tests/transaction.admin-filter.test.js`**

- Import đổi thành `import { getAdminAll } from '../src/modules/transactions/transaction.controller.js';`.
- Trong `buildApp`, xoá dòng `router.get('/admin/user/:userId', getAdminUserByUserId);`.
- Xoá bốn test dùng `/admin/user/:userId`: `lịch sử giao dịch của một người dùng lọc đúng theo user trong path`, `userId trên query không ghi đè được user trong path`, `các bộ lọc bổ sung vẫn có hiệu lực cùng user trong path`, `danh sách rỗng trả 200 với mảng rỗng và phân trang hợp lệ`.
- Giữ test `danh sách quản trị không có user vẫn không tự thêm bộ lọc user`. Bỏ hằng `USER_ID`/`OTHER_USER_ID` nếu không còn chỗ dùng.

Run: `node --test tests/transaction.admin-filter.test.js` → Expected: 1 pass, 0 fail.

- [ ] **Step 7: Cập nhật contract**

Run: `node $TOOLS/route-signatures.mjs` → Expected `count=194`, `hash=3dd6b3c5dfe5e6d5052586291a6893e2215a369b5ed476827845d25906f82ba9`. Ghi kèm chú thích `… gỡ 11 route transactions …`.

- [ ] **Step 8: Chạy toàn bộ test backend**

Run: `npm test` → Expected `# fail 0`.

- [ ] **Step 9: Commit**

```bash
git add BackEnd/src/modules/transactions BackEnd/tests/transaction.admin-filter.test.js BackEnd/tests/route-contract.test.js BackEnd/tests/app.smoke.test.js
git commit -m "refactor(transactions): keep only create, admin list and status update" -m "The payment screen creates transactions and the admin screen lists them and changes status; nothing calls the other eleven routes. Tests for the per-user admin history go with that route."
```

---

### Task 6: Gỡ route thừa của notifications, news, notebook, reports

**Files:**
- Modify (thay toàn bộ): `BackEnd/src/modules/notifications/notification.routes.js`, `news/news.routes.js`, `notebook/notebook.routes.js`, `reports/report.routes.js`
- Modify: `notification.controller.js:47-69,161-181,209-240,277-411`; `news.controller.js:99-304`; `notebook.controller.js:250-346`; `report.controller.js:78-102,207-239,260-281`
- Modify: `BackEnd/tests/route-contract.test.js`, `BackEnd/tests/app.smoke.test.js`

**Interfaces:**
- Produces: controller chỉ còn handler được route bên dưới tham chiếu.

- [ ] **Step 1: Thêm dòng vào `REMOVED_ROUTES`**

```js
  // notifications
  ['get', '/api/notifications/admin/all'],
  ['delete', '/api/notifications/clear/read'],
  // news
  ['get', '/api/news/admin/stats'],
  ['delete', '/api/news'],
  // notebook
  ['get', '/api/notebook/admin/all'],
  // reports
  ['put', '/api/report/admin/507f1f77bcf86cd799439011/priority'],
```

- [ ] **Step 2: Chạy để thấy đỏ**

Run: `cd BackEnd && node --test tests/app.smoke.test.js` → Expected FAIL (`401`).

- [ ] **Step 3: Rà tham chiếu phía Flutter**

Run: `cd .. && grep -rnE "/notifications|/news|/notebook|/report" FrontEnd/lib/features/*/services FrontEnd/lib/features/admin`
Expected: mọi lời gọi đều khớp một route còn lại ở Step 4 (notifications: `GET /`, `GET /count/unread`, `PUT /read/:id`, `PUT /read-all`, `DELETE /:id`, `POST /`, `POST /broadcast/all`; news: `GET /`, `GET /:id`, `GET /:id/related`; notebook: 9 route ở Step 4; report: 7 route ở Step 4). Lời gọi nào không khớp thì dừng lại hỏi.

- [ ] **Step 4: Thay bốn file routes**

`notification.routes.js`:

```js
import express from 'express';
import { authenticateUser, authenticateAdmin } from '../../middleware/auth.middleware.js';
import * as controller from './notification.controller.js';

const router = express.Router();

router.get('/', authenticateUser, controller.getRoot);
router.get('/count/unread', authenticateUser, controller.getCountUnread);
router.put('/read/:id', authenticateUser, controller.putReadById);
router.put('/read-all', authenticateUser, controller.putReadAll);
router.delete('/:id', authenticateUser, controller.deleteById);
router.post('/', authenticateAdmin, controller.postRoot);
router.post('/broadcast/all', authenticateAdmin, controller.postBroadcastAll);

export default router;
```

`news.routes.js`:

```js
import express from 'express';
import * as controller from './news.controller.js';

const router = express.Router();

router.get("/", controller.getRoot);
router.get("/:id", controller.getById);
router.get("/:id/related", controller.getByIdRelated);

export default router;
```

`notebook.routes.js`:

```js
import express from 'express';
import { authenticateUser } from '../../middleware/auth.middleware.js';
import * as controller from './notebook.controller.js';

const router = express.Router();

router.get("/", authenticateUser, controller.getRoot);
router.get("/:id", authenticateUser, controller.getById);
router.post("/", authenticateUser, controller.postRoot);
router.put("/:id", authenticateUser, controller.putById);
router.delete("/:id", authenticateUser, controller.deleteById);
router.delete("/", authenticateUser, controller.deleteRoot);
router.get("/related/:item_type/:item_id", authenticateUser, controller.getRelatedByItemTypeByItemId);
router.get("/tags/all", authenticateUser, controller.getTagsAll);
router.get("/stats/me", authenticateUser, controller.getStatsMe);

export default router;
```

`report.routes.js`:

```js
import express from 'express';
import { authenticateUser, authenticateAdmin } from '../../middleware/auth.middleware.js';
import * as controller from './report.controller.js';

const router = express.Router();

router.post("/create", authenticateUser, controller.postCreate);
router.get("/my-reports", authenticateUser, controller.getMyReports);
router.delete("/:id", authenticateUser, controller.deleteById);
router.get("/admin/all", authenticateAdmin, controller.getAdminAll);
router.put("/admin/:id/status", authenticateAdmin, controller.putAdminByIdStatus);
router.delete("/admin/:id", authenticateAdmin, controller.deleteAdminById);
router.get("/admin/stats", authenticateAdmin, controller.getAdminStats);

export default router;
```

- [ ] **Step 5: Xoá handler (kể cả comment ngay trên mỗi khối)**

- `notification.controller.js`: `getById`, `deleteClearRead`, `postBroadcast`, và từ `getAdminAll` tới hết file (`getAdminAll`, `getAdminStats`, `putAdminById`, `deleteAdminById`, `deleteAdminBulkDelete`).
- `news.controller.js`: từ `getCategoriesAll` tới hết file (`getCategoriesAll`, `getAdminAll`, `postRoot`, `putById`, `deleteById`, `deleteRoot`, `getAdminStats`).
- `notebook.controller.js`: từ `getAdminAll` tới hết file (`getAdminAll`, `getAdminStats`, `deleteAdminById`).
- `report.controller.js`: `getById`, `putAdminByIdPriority`, `deleteAdminBulkDelete`.

Run (từ `BackEnd/`): với mỗi file trên, `grep -nE "^import|^const " <file>` rồi với mỗi tên được import hoặc khai báo `const` không export, `grep -cw <tên> <file>` phải lớn hơn 1; tên nào chỉ còn 1 lần thì xoá. (Rà ở mốc xuất phát không thấy import/helper nào mồ côi ở bốn file này.)
Run: `for f in notifications/notification news/news notebook/notebook reports/report; do node --check src/modules/$f.controller.js; done` → Expected: không lỗi.

- [ ] **Step 6: Cập nhật contract**

Run: `node $TOOLS/route-signatures.mjs` → Expected `count=173`, `hash=593e5ebc29270d8da307af0b4bee7360cb81ecf49ea65df6f76e1fb51895e9ac`. Ghi kèm chú thích `… gỡ 21 route notifications/news/notebook/reports …`.

- [ ] **Step 7: Chạy toàn bộ test backend**

Run: `npm test` → Expected `# fail 0`.

- [ ] **Step 8: Commit**

```bash
git add BackEnd/src/modules/notifications BackEnd/src/modules/news BackEnd/src/modules/notebook BackEnd/src/modules/reports BackEnd/tests/route-contract.test.js BackEnd/tests/app.smoke.test.js
git commit -m "refactor: remove unused notification, news, notebook and report endpoints" -m "No screen manages news or notifications from the admin side, reads a single report, or uses the notebook admin views. News content comes from seed-news.js. The routes the app calls are unchanged."
```

---

### Task 7: Gỡ route thừa của study-groups, users, grammar

**Files:**
- Modify (thay toàn bộ): `BackEnd/src/modules/study-groups/group.routes.js`, `grammar/grammar.routes.js`
- Modify: `BackEnd/src/modules/users/user.routes.js:66,78,79,84`
- Modify: `group.controller.js:535-585,633-719`; `user.controller.js:99-123,227-286,431-453`; `grammar.controller.js:1-2,85-132`
- Modify: `BackEnd/tests/route-contract.test.js`, `BackEnd/tests/app.smoke.test.js`

- [ ] **Step 1: Thêm dòng vào `REMOVED_ROUTES`**

```js
  // study-groups
  ['get', '/api/group/admin/all'],
  // users
  ['get', '/api/users/me'],
  ['post', '/api/users/admin/users'],
  // grammar
  ['get', '/api/grammar/popular/N5'],
```

Lưu ý: `POST /api/users/admin/users` vẫn còn route `GET /admin/users` cùng path nhưng khác method — Express trả 404 cho method không khai báo.

- [ ] **Step 2: Chạy để thấy đỏ**

Run: `cd BackEnd && node --test tests/app.smoke.test.js` → Expected FAIL (`401`).

- [ ] **Step 3: Rà tham chiếu**

Run: `cd .. && grep -rnE "inviteMember|listAdminGroups|deleteAdminGroup|getAdminGroupStatistics|getMe\b|getAdminUsersById|postAdminUsers|putAdminUsersByIdToggleStatus|getPopularByLevel|postLearnById" BackEnd/src BackEnd/tests BackEnd/scripts`
Expected: chỉ trong routes/controller của ba module.
Run: `grep -rnE "/group/(invite|admin)|/users/me|toggle-status|/grammar/(popular|learn)" FrontEnd/lib` → Expected: không có dòng nào.
Run: `grep -rnE "_client\.(post|get)\('/users/admin/users" FrontEnd/lib` → Expected: chỉ `get('/users/admin/users$query')` (danh sách, giữ).

- [ ] **Step 4: Thay routes**

`group.routes.js`:

```js
import express from 'express';
import { authenticateUser } from '../../middleware/auth.middleware.js';
import { uploadGroupAvatar } from '../../middleware/upload.middleware.js';
import * as controller from './group.controller.js';

const router = express.Router();

router.post("/", authenticateUser, controller.createGroup);
router.get("/", authenticateUser, controller.listGroups);
router.get("/me", authenticateUser, controller.listMyGroups);
router.get("/:groupID", authenticateUser, controller.getGroup);
router.put("/:groupID", authenticateUser, controller.isGroupAdmin, controller.updateGroup);
router.delete("/:groupID", authenticateUser, controller.deleteGroup);
router.post("/join/:groupID", authenticateUser, controller.joinGroup);
router.post("/leave/:groupID", authenticateUser, controller.leaveGroup);
router.delete("/kick/:groupID/:userID", authenticateUser, controller.isGroupAdmin, controller.kickMember);
router.put("/promote/:groupID/:userID", authenticateUser, controller.isGroupAdmin, controller.promoteMember);
router.put("/demote/:groupID/:userID", authenticateUser, controller.demoteMember);
router.get('/:groupID/stats', authenticateUser, controller.getGroupStats);
router.put("/:groupID/avatar", authenticateUser, controller.isGroupAdmin, uploadGroupAvatar, controller.updateGroupAvatar);

export default router;
```

`grammar.routes.js`:

```js
import express from 'express';
import { authenticateUser, authenticateAdmin } from '../../middleware/auth.middleware.js';
import * as controller from './grammar.controller.js';

const router = express.Router();

router.get('/', authenticateUser, controller.getRoot);
router.get('/:id', authenticateUser, controller.getById);
router.post('/', authenticateAdmin, controller.postRoot);
router.put('/:id', authenticateAdmin, controller.putById);
router.delete('/:id', authenticateAdmin, controller.deleteById);

export default router;
```

`user.routes.js`: xoá đúng bốn dòng
`router.get("/me", authenticate, controller.getMe);`,
`router.get("/admin/users/:id", authorizeAdmin, controller.getAdminUsersById);`,
`router.post("/admin/users", authorizeAdmin, controller.postAdminUsers);`,
`router.put("/admin/users/:id/toggle-status", authorizeAdmin, controller.putAdminUsersByIdToggleStatus);`.

- [ ] **Step 5: Xoá handler (kể cả comment ngay trên mỗi khối)**

- `group.controller.js`: `inviteMember`, `listAdminGroups`, `deleteAdminGroup`, `getAdminGroupStatistics`. `GroupChat` vẫn còn được `joinGroup` và `getGroupStats` dùng — giữ import.
- `user.controller.js`: `getMe`, `getAdminUsersById`, `postAdminUsers`, `putAdminUsersByIdToggleStatus`.
- `grammar.controller.js`: `getPopularByLevel`, `postLearnById`; xoá import `Lesson` (dòng 2, vốn đã thừa).

Run: `cd BackEnd && grep -nw Lesson src/modules/grammar/grammar.controller.js` → Expected: không in dòng nào.
Run (từ `BackEnd/`): với `group.controller.js` và `user.controller.js`, mọi tên import và `const` không export phải có `grep -cw` lớn hơn 1; tên nào chỉ còn 1 thì xoá. (Rà ở mốc xuất phát không thấy tên nào mồ côi.)
Run: `for f in study-groups/group users/user grammar/grammar; do node --check src/modules/$f.controller.js; done` → Expected: không lỗi.

- [ ] **Step 6: Cập nhật contract**

Run: `node $TOOLS/route-signatures.mjs` → Expected `count=163`, `hash=2d31e5117b3c119a3d58e733bcab0cbd38fe966f413fcb5461fc1c1c4147124c`. Ghi kèm chú thích `… gỡ 10 route study-groups/users/grammar …`.

- [ ] **Step 7: Chạy toàn bộ test backend**

Run: `npm test` → Expected `# fail 0`.

- [ ] **Step 8: Commit**

```bash
git add BackEnd/src/modules/study-groups BackEnd/src/modules/users BackEnd/src/modules/grammar BackEnd/tests/route-contract.test.js BackEnd/tests/app.smoke.test.js
git commit -m "refactor: remove unused group, user and grammar endpoints" -m "Group invites and admin group views, /users/me, admin user create/lookup/toggle, and grammar popular/learn have no caller in the app. The user admin screen keeps list, update and delete."
```

---

### Task 8: Gỡ route thừa của vocabulary và lessons (module đã theo khuôn)

**Files:**
- Modify: `BackEnd/src/modules/vocabulary/vocabulary.routes.js`, `vocabulary.controller.js`, `vocabulary.service.js`, `vocabulary.repository.js`, `vocabulary.schema.js`, `vocabulary-import.service.js:88-117`
- Modify: `BackEnd/src/modules/lessons/lesson.routes.js:44-49,67-72,79-84`, `lesson.controller.js`, `lesson.service.js:82-87,97-99`, `lesson.repository.js`, `lesson.schema.js:55-57,85-90`
- Test: `BackEnd/tests/vocabulary.routes.test.js`, `vocabulary.service.test.js`, `vocabulary-import.service.test.js`, `lesson.routes.test.js`, `lesson.service.test.js`, `route-contract.test.js`, `app.smoke.test.js`

**Interfaces:**
- Produces: `createVocabularyService` không còn `listByLevel`, `listSituations`, `searchBySituation`, `randomPractice`, `learnInLesson`, `stats`, `buildExportWorkbook`; tham số `importer` chỉ còn `{ readWorkbookRows, toVocabularyRows }`. `createLessonService` không còn `getByType`, `createMany`.

- [ ] **Step 1: Viết test đỏ**

Thêm vào `REMOVED_ROUTES`:

```js
  // vocabulary
  ['get', '/api/vocabulary/random/practice'],
  ['post', '/api/vocabulary/learn/507f1f77bcf86cd799439011'],
  // lessons
  ['get', '/api/lesson/type/ngu-phap'],
  ['patch', '/api/lesson/507f1f77bcf86cd799439011'],
```

Thêm vào `BackEnd/tests/vocabulary.routes.test.js`, ngay sau test `tìm kiếm thiếu từ khoá trả về 400`:

```js
test('đường cũ /situations giờ rơi vào /:id và bị validate chặn 400, không chạm service', async () => {
  const app = buildApp({ getById: async () => assert.fail('không được gọi service') });

  const response = await request(app).get('/api/vocabulary/situations');

  assert.equal(response.status, 400);
});
```

- [ ] **Step 2: Chạy để thấy đỏ**

Run: `cd BackEnd && node --test tests/app.smoke.test.js tests/vocabulary.routes.test.js`
Expected: FAIL ở smoke (`401`) và ở test mới (`500`, không phải `400`: `/situations` còn là route riêng và service giả không có `listSituations`).

- [ ] **Step 3: Rà tham chiếu**

Run: `cd .. && grep -rnE "listSituations|listByLevel|searchBySituation|randomPractice|learnInLesson|adminStats|adminExport|buildExportWorkbook|findForExport|distinctUsageContexts|getByType|createMany|findByTypePattern|getTypeByLoaiBaiHoc|postBulk" BackEnd/src/modules/vocabulary BackEnd/src/modules/lessons BackEnd/scripts`
Expected: chỉ trong hai module này. Lưu ý `listSituations` của **lessons** (route `GET /lesson/situations`) được giữ — chỉ xoá bản của vocabulary.
Run: `grep -rnE "/vocabulary/(situations|level|situation|random|admin|learn)|/lesson/(type|bulk)|\.patch\('/lesson" FrontEnd/lib` → Expected: không có dòng nào.

- [ ] **Step 4: Vocabulary — routes, controller, schema**

- `vocabulary.routes.js`: xoá 7 khối `router.*(...)` có path `'/situations'`, `'/level/:levelEnum'`, `'/situation/search'`, `'/random/practice'`, `'/admin/stats'`, `'/admin/export'`, `'/learn/:id'`.
- `vocabulary.controller.js`: xoá method `listSituations`, `listByLevel`, `searchBySituation`, `randomPractice`, `learnInLesson`, `adminStats`, `adminExport`.
- `vocabulary.schema.js`: xoá export `situationSearchQuery`, `randomPracticeQuery`, `exportQuery`, `levelParams`, `learnBody`.

- [ ] **Step 5: Vocabulary — service, repository, import**

- `vocabulary.service.js`: xoá method `listByLevel`, `listSituations`, `searchBySituation`, `randomPractice`, `learnInLesson` (kèm JSDoc), `stats`, `buildExportWorkbook`. Import từ `./vocabulary-import.service.js` còn `readWorkbookRows, toVocabularyRows`; mặc định của tham số `importer` còn `{ readWorkbookRows, toVocabularyRows }`.
- `vocabulary.repository.js`: xoá `distinctUsageContexts` (kèm JSDoc), `sample`, `stats` (kèm JSDoc), `findForExport`.
- `vocabulary-import.service.js`: xoá `buildExportWorkbook` (kèm JSDoc `/** Tạo workbook xuất Excel với header tiếng Việt. */`). Giữ `import Excel from 'exceljs';` (còn dùng để đọc file).

Run: `cd BackEnd && grep -nwE "buildWorkbook|buildExportWorkbook|findForExport|sample|distinctUsageContexts" src/modules/vocabulary/*.js` → Expected: không in dòng nào.

- [ ] **Step 6: Lessons**

- `lesson.routes.js`: xoá khối `'/type/:loaiBaiHoc'` (GET), khối `'/bulk'` (POST), khối `router.patch('/:id', …)`.
- `lesson.controller.js`: xoá method `getTypeByLoaiBaiHoc`, `postBulk`. Giữ import `created` (còn dùng ở `postRoot`, `postByIdDuplicate`).
- `lesson.service.js`: xoá `getByType`, `createMany`. Giữ `escapeRegExp` (còn dùng trong `list`).
- `lesson.repository.js`: xoá `findByTypePattern`, `createMany`.
- `lesson.schema.js`: xoá `loaiBaiHocParams`, `bulkBody`.

Run: `grep -nwE "getByType|createMany|findByTypePattern|loaiBaiHocParams|bulkBody" src/modules/lessons/*.js` → Expected: không in dòng nào.

- [ ] **Step 7: Sửa test đang dùng code đã xoá**

- `tests/vocabulary.routes.test.js`: xoá test `danh sách theo cấp độ rỗng vẫn là 200`, `cấp độ không hợp lệ trả về 400`, `học từ vựng trong bài học yêu cầu lessonId`.
- `tests/vocabulary.service.test.js`: trong `fakeVocabularyRepository` xoá `distinctUsageContexts`, `sample`, `stats`, `findForExport`; trong test `danh sách rỗng vẫn là danh sách, không phải lỗi` xoá hai dòng `assert.deepEqual(await service.listByLevel('N1'), []);` và `assert.deepEqual(await service.searchBySituation('không có'), []);`; trong hai importer giả của test `import Excel rỗng trả về lỗi 400` và `import Excel gắn lesson/level cho mọi dòng hợp lệ` xoá dòng `buildExportWorkbook: () => ({}),`.
- `tests/vocabulary-import.service.test.js`: xoá `buildExportWorkbook,` khỏi import và xoá test `workbook xuất ra có đủ 6 cột và một dòng cho mỗi từ`.
- `tests/lesson.routes.test.js`: xoá test `GET /type/:loaiBaiHoc rỗng vẫn là 200 và mảng rỗng` và `POST /bulk tạo nhiều bài, giới hạn 1-100 phần tử`; thay test `PUT /:id và PATCH /:id gọi cùng một service.update` bằng:

```js
test('PUT /:id gọi service.update, PATCH /:id không còn', async () => {
  const calls = [];
  const app = buildApp({
    update: async (id, body) => { calls.push([id, body]); return { _id: id, ...body }; },
  });

  const put = await request(app).put(`/api/lesson/${VALID_ID}`).send({ title: 'A' });
  const patch = await request(app).patch(`/api/lesson/${VALID_ID}`).send({ title: 'B' });

  assert.equal(put.status, 200);
  // App test không gắn notFoundHandler: method không khai báo rơi về 404 mặc định của Express.
  assert.equal(patch.status, 404);
  // updateBody chuẩn hoá qua normalizeLessonBody nên body có thêm khoá undefined — chỉ so trường gửi lên.
  assert.equal(calls.length, 1);
  assert.equal(calls[0][0], VALID_ID);
  assert.equal(calls[0][1].title, 'A');
});
```
- `tests/lesson.service.test.js`: trong `fakeRepository` xoá `findByTypePattern` và `createMany`.

- [ ] **Step 8: Cập nhật contract**

Run: `node $TOOLS/route-signatures.mjs` → Expected `count=153`, `hash=ca403daf7d140e9664b75f5124bc924dfbcbb131d19f8d78041f5dff8ad4a2fe`. Ghi kèm chú thích `… gỡ 10 route vocabulary/lessons …`.

- [ ] **Step 9: Chạy toàn bộ test backend**

Run: `npm test` → Expected `# fail 0`.

- [ ] **Step 10: Commit**

```bash
git add BackEnd/src/modules/vocabulary BackEnd/src/modules/lessons BackEnd/tests
git commit -m "refactor(vocabulary,lessons): remove endpoints with no client" -m "Level/situation/random listings, the learn-in-lesson redirect stub, admin stats and Excel export for vocabulary, and lesson type/bulk/PATCH have no caller. The admin screen keeps vocabulary CRUD and Excel import. A request to the old /vocabulary/situations path now falls into /:id and is rejected by validation before any service call."
```

---

### Task 9: Flutter — xoá lời gọi tới endpoint không tồn tại và file không ai import

**Files:**
- Modify: `FrontEnd/lib/features/achievements/services/achievement_service.dart:61-70`
- Modify: `FrontEnd/lib/features/grammar/services/grammar_service.dart:98-129`
- Modify: `FrontEnd/lib/features/grammar/providers/grammar_provider.dart:80-81,181-208`
- Delete: `FrontEnd/lib/core/config/constants.dart`

- [ ] **Step 1: Rà tham chiếu**

Run: `cd FrontEnd && grep -rnE "AchievementService\(\)\.createAchievement|_achievementService\.createAchievement|incrementGrammarView|favoriteGrammar|unfavoriteGrammar|AppConstants|config/constants.dart" lib test`
Expected: chỉ các định nghĩa trong ba file trên, lời gọi `incrementGrammarView` trong `grammar_provider.dart` và chính `constants.dart`. `AdminService.createAchievement` / `AdminProvider.createAchievement` là bản đang dùng — **không** đụng.

- [ ] **Step 2: Xoá**

- `achievement_service.dart`: xoá comment `// Create achievement (admin)` và method `createAchievement` (gọi `POST /achievement/create` không tồn tại).
- `grammar_service.dart`: xoá `incrementGrammarView`, `favoriteGrammar`, `unfavoriteGrammar` kèm doc comment của từng method.
- `grammar_provider.dart`: trong `loadGrammarDetail` xoá hai dòng `// Tăng view count` và `await _grammarService.incrementGrammarView(grammarId);`; xoá method `favoriteGrammar` và `unfavoriteGrammar` kèm doc comment.
- Xoá file `lib/core/config/constants.dart`; nếu thư mục `lib/core/config/` rỗng thì xoá luôn thư mục.

- [ ] **Step 3: Phân tích và test**

Run: `dart analyze` → Expected: `No issues found!`
Run: `flutter test` → Expected: `All tests passed!`

- [ ] **Step 4: Commit**

```bash
git add -A FrontEnd/lib
git commit -m "refactor(flutter): drop calls to endpoints that do not exist" -m "AchievementService.createAchievement posted to /achievement/create and the grammar view/favorite methods hit /grammar/:id/view and /favorite; none of these routes exist, so every call failed silently. The admin screen already creates achievements through AdminService. constants.dart was imported nowhere."
```

---

### Task 10: Tài liệu và kiểm tra tổng

**Files:**
- Modify: `docs/api/API_OVERVIEW.md:23`

- [ ] **Step 1: Sửa tài liệu API**

Trong bảng "Nhóm endpoint chính", thay dòng

```text
| `/group`, `/group-chat` | Nhóm học tập và tin nhắn |
```

bằng

```text
| `/group` | Nhóm học tập |
```

 Phần "Quy ước response" để nguyên — viết lại ở đợt 6 khi contract đã thống nhất.

- [ ] **Step 2: Đối chiếu danh sách route với spec**

Run: `cd BackEnd && node $TOOLS/route-signatures.mjs --list > $TOOLS/route-signatures-after.txt && diff <(grep -E '^(GET|POST|PUT|PATCH|DELETE) ' $TOOLS/route-signatures-before.txt) <(grep -E '^(GET|POST|PUT|PATCH|DELETE) ' $TOOLS/route-signatures-after.txt) | grep -c '^<'`
Expected: `104`, và `grep -c '^>'` trên cùng diff ra `0` (không route nào mới xuất hiện). Đọc lướt danh sách `<` so với bảng §6.1 của spec.

- [ ] **Step 3: Chạy đủ quality gate**

Run: `cd BackEnd && npm test` → Expected `# fail 0`.
Run: `cd ../FrontEnd && dart analyze && flutter test` → Expected `No issues found!` và `All tests passed!`.

- [ ] **Step 4: Chạy thử thật (chủ dự án thực hiện)**

Bật backend (`cd BackEnd && npm run dev`) và app (`cd FrontEnd && flutter run`), đăng nhập tài khoản thường rồi admin, mở lần lượt: danh sách + làm một bài tập; danh sách đề JLPT + nộp một đề + xem lời giải; dashboard tiến độ; tin tức + tin liên quan; thông báo (đếm, đánh dấu đã đọc); sổ tay; gửi báo cáo; nhóm học (danh sách, chi tiết); ngữ pháp (danh sách, chi tiết); từ vựng (danh sách, tìm kiếm, bộ học, chi tiết); bài học; thanh toán; màn admin: quản lý nội dung, người dùng, giao dịch, báo cáo, thành tích, analytics. Không màn nào được hiện lỗi 404.

- [ ] **Step 5: Commit**

```bash
git add docs/api/API_OVERVIEW.md
git commit -m "docs(api): drop group-chat from the endpoint overview" -m "The group chat API was removed in wave 0 of the one-style refactor."
```
