# Thiết kế — Chuyển toàn bộ code về một kiểu

Ngày: 2026-09-28 · Trạng thái: chờ duyệt

Tài liệu này là spec tổng cho đợt chuyển toàn bộ backend và phần luồng dữ liệu của Flutter về
**một khuôn mẫu duy nhất**, đồng thời xoá code không còn ai dùng. Mỗi đợt bên dưới vẫn có spec
ngắn và implementation plan riêng trước khi code. Khi mâu thuẫn với
[out-of-scope.md](../../architecture/out-of-scope.md) hoặc phần Tier A/B của
[redesign-roadmap.md](../../architecture/redesign-roadmap.md), tài liệu này thay thế các quyết
định đó; hai tài liệu kia được cập nhật ở đợt 6.

## 1. Mục tiêu và các quyết định đã chốt

**Mục tiêu:** người đọc code chỉ phải học **một** cách tổ chức, từ route backend tới màn hình
Flutter, để nắm được luồng xử lý của bất kỳ tính năng nào. Không có hạn chót; ưu tiên làm đúng
và kiểm chứng được sau mỗi bước.

| Câu hỏi | Quyết định |
| --- | --- |
| Hình dạng JSON thành công | Đổi hẳn sang contract `{ data }` ở mọi endpoint; Flutter sửa theo trong cùng commit |
| Phạm vi Flutter | Đồng đều luồng dữ liệu: service trả model, provider dùng `ViewState`, screen dùng `AsyncView`. **Không** tách/vẽ lại screen dài ở đợt này (để giai đoạn redesign UI, tránh làm hai lần) |
| Code không ai dùng | Xoá hết: route không có consumer trong Flutter, handler/helper/test chỉ phục vụ chúng, lời gọi Flutter tới endpoint không tồn tại, file Dart không ai import |
| API quản trị JLPT, bài tập, tin tức | Xoá cùng quy tắc trên. Nội dung thêm bằng script seed; khi cần màn quản trị thì viết mới theo khuôn này |
| Cách tiến hành | Dọn trước, rồi chuyển từng module theo lát dọc; mỗi module một commit gồm cả backend và Flutter; app chạy được sau mọi commit |

## 2. Hiện trạng (đo ngày 2026-09-28)

| Chỉ số | Giá trị |
| --- | --- |
| Route công khai | 257 (CLAUDE.md ghi 261 là số cũ) |
| Route không có consumer trong Flutter | 104 — danh sách đầy đủ ở §6 |
| Module backend chưa theo khuôn | 15: chat, exercise, flashcards, grammar, jlpt, kanji, news, notebook, notifications, progress, reports, settings, study-groups, transactions, users (exercise, jlpt, users mới chuyển phần nộp bài / đăng nhập) |
| Route không bọc `asyncHandler` | 189 |
| Khối `try` trong controller | 195 |
| Controller dài hơn 150 dòng | 15 (kể cả `vocabulary.controller.js` — 162 dòng) |
| Provider Flutter | 28 file: 8 dùng `ViewState` (3 trong đó còn lẫn cờ cũ), 16 tự quản `_isLoading`/`_error`, 4 kiểu riêng |
| Screen Flutter dài hơn 300 dòng | 40 (ngoài phạm vi, xem §8) |
| Lời gọi Flutter tới endpoint không tồn tại | 4 — xem §6.2 |

Cách đo route không có consumer: script đọc tham số đầu của mọi lời gọi `ApiClient` trong
`FrontEnd/lib`, dựng path pattern, so khớp với 257 route theo segment (tham số `:x` chỉ khớp
phần động, ưu tiên route cụ thể nhất như Express). Bốn lời gọi truyền biến `endpoint` được tra
tay. Mỗi route vẫn được kiểm tra lại bằng tay trước khi xoá (§6.3).

## 3. Khuôn backend

### 3.1. File của một module

```text
src/modules/<domain>/
  <domain>.routes.js      create<Domain>Routes({ service, authenticate, authorizeAdmin }) — chỉ path + middleware
  <domain>.schema.js      schema zod cho params / query / body
  <domain>.controller.js  create<Domain>Controller(service) — đọc req.valid, req.user; trả response qua respond.js
  <domain>.service.js     create<Domain>Service({ repository, ... }) — rule nghiệp vụ, ném ApiError
  <domain>.repository.js  create<Domain>Repository({ Model }) — nơi DUY NHẤT import model
  <domain>-<rule>.js      (tuỳ) hàm thuần, như srs-scheduling.js, exercise-scoring.service.js
```

Mỗi route: `authenticate | authorizeAdmin → validate({ params, query, body }) → asyncHandler(controller.x)`.
File routes export cả factory (để test dựng router với service và auth giả) lẫn bản dựng sẵn
làm `default`. Controller không `try/catch`; service không chạm `req`/`res`; repository không
chứa rule. Ghi nhiều collection trong một thao tác thì dùng `unitOfWork` như SRS và
lesson-progress.

Controller **luôn** gọi service, kể cả khi service chỉ chuyển tiếp xuống repository (ví dụ
settings). Cho controller gọi thẳng repository ở module "đơn giản" sẽ tạo lại kiểu thứ hai mà
đợt này đang xoá. Quy tắc "không tạo file rỗng cho đủ sơ đồ" trong `CLAUDE.md` được hiểu là
không tạo file không có code; một service mỏng vẫn có code.

### 3.2. Response contract

Mọi response thành công đều có `data`:

| Trường hợp | Dạng |
| --- | --- |
| Một tài nguyên / kết quả một thao tác | `200 { data }` |
| Tạo mới | `201 { data }` |
| Danh sách | `{ data, total }` |
| Danh sách phân trang | `{ data, page, limit, total, totalPages }` |
| Xoá một | `{ data: { deleted: true } }` |
| Xoá nhiều | `{ data: { deletedCount } }` |
| Lỗi | `{ message, code?, details? }` do `errorHandler` dịch từ `ApiError` / lỗi Mongoose |

- Chỉ response của **thao tác ghi** được kèm `message`.
- Trường thêm khác (như SRS `{ data, limit }`) phải có chú thích lý do ngay tại controller.
- Tải file (export Excel) là ngoại lệ duy nhất không trả JSON.
- Danh sách rỗng luôn `200` với mảng rỗng; `404` chỉ cho một tài nguyên định danh cụ thể.
- Path của route được giữ nguyên khi chuyển kiểu; chỉ đợt 0 thay đổi tập route.

### 3.3. Cải tiến nhỏ đi kèm

1. **`shared/http/schemas.js`** export `objectId` (và các schema dùng chung khác khi xuất hiện
   lần thứ hai). Bảy file schema hiện tự định nghĩa `objectId` với thông báo lỗi khác nhau.
2. **Multer chỉ nằm ở `middleware/upload.middleware.js`.** Không controller nào tự cấu hình
   multer (exercise đang làm vậy; phần đó bị xoá ở đợt 0).
3. **`tests/architecture.test.js`** — máy kiểm "một kiểu", không cần MongoDB:
   - `*.controller.js`: không chứa `try {`, không import `model/` hay `mongoose`.
   - `*.service.js`: không import `model/` hay `mongoose`, không khớp `/\b(req|res)\./`.
   - `*.routes.js`: mọi lời khai `router.<method>(...)` đều có `asyncHandler(`.
   - Mỗi module có đủ `routes`, `schema`, `controller`, `service`, `repository`.

   Module chưa chuyển nằm trong hằng `LEGACY_MODULES` của test. Hằng này được khởi tạo sao
   cho test xanh ngay khi thêm, mỗi module chuyển xong thì bị gỡ khỏi danh sách, và phải rỗng
   khi kết thúc đợt 6. Test thứ hai kiểm rằng mọi tên trong `LEGACY_MODULES` vẫn là thư mục có
   thật, để danh sách không mục dần.

### 3.4. Test bắt buộc cho mỗi module

1. `tests/<domain>.service.test.js` — rule nghiệp vụ với repository giả.
2. `tests/<domain>.routes.test.js` — supertest với service và auth giả: status code, hình dạng
   response, lỗi validate.
3. `tests/route-contract.test.js` — cập nhật `expectedCount` và `expectedSignatureHash` trong
   cùng commit nếu tập route đổi.

## 4. Khuôn Flutter

### 4.1. Thư mục của một feature

```text
lib/features/<feature>/
  models/     fromJson có kiểu; Map không lọt ra ngoài thư mục này
  services/   <Feature>Service({ApiClient? client}) — gọi ApiClient, bóc { data }, trả model
  providers/  <Feature>Provider({<Feature>Service? service}) — giữ ViewState<T>, gọi service qua ViewState.guard
  screens/    bố cục + điều hướng; đọc provider, hiển thị state qua AsyncView
  widgets/    thành phần trình bày; không gọi service
```

Một lần tải dữ liệu: `screen → provider.load() → ViewState.loading → ViewState.guard(service.x())
→ ViewData | ViewFailure → AsyncView` vẽ một trong bốn nhánh (tải / lỗi kèm "Thử lại" / rỗng /
có dữ liệu).

### 4.2. Quy tắc từng tầng

- **Service** nhận `ApiClient` qua constructor (như `SrsService` hiện nay). Query dựng bằng
  `Uri(queryParameters:)`, không nối chuỗi tay. Không bắt lỗi — `ApiException` bay lên cho
  `guard`. Phương thức public trả model, `List<Model>` hoặc `Paged<Model>`, không trả `Map`.
- **Provider** không có trường `_isLoading` / `_error`; mỗi dữ liệu là một `ViewState<T>`. Cờ
  phụ có tên riêng vẫn được phép khi có lý do (ví dụ `_isLoadingMore` giữ danh sách hiện tại
  trong lúc tải trang sau). **Thao tác ghi** (nộp, xoá, đánh dấu) cũng chạy qua
  `ViewState.guard` và trả `ViewState<T>` về cho screen.
- **Screen** không import service, không tự viết `if (isLoading) … else if (error != null)`.
  Sau thao tác ghi, screen đọc `result.errorOrNull` để hiện SnackBar — không `try/catch`. Màu,
  khoảng cách, bo góc lấy từ `app_tokens.dart`.

### 4.3. Cải tiến nhỏ đi kèm

1. **`lib/core/network/api_envelope.dart`**:
   - `Object? dataOf(Object? response)` — trả `response['data']`; ném `ServerException` nếu
     response không phải Map có khoá `data`.
   - `List<T> listOf<T>(Object? response, T Function(Map<String, dynamic>) fromJson)`.
   - `class Paged<T>` với `items, page, limit, total, totalPages` và
     `Paged.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson)`.

   Thay dần các lớp trang tự viết (`VocabularyPage`, …) khi chạm tới feature đó.
2. **`test/architecture_test.dart`** — quét `lib/features/`:
   - file trong `providers/` không khai trường `_isLoading` hay `_error` (so khớp nguyên từ);
   - file trong `screens/` và `widgets/` không import thư mục `services/`;
   - phương thức trong `services/` không có kiểu trả về `Map<String, dynamic>`.

   Có hằng `legacyFeatures` giống backend, gỡ dần và rỗng khi xong đợt 6.

### 4.4. Test bắt buộc cho mỗi feature

1. `test/<feature>_service_test.dart` — `ApiClient` giả trả JSON `{ data }` thật → đúng model;
   response thiếu `data` → lỗi rõ ràng. Đây là lưới chặn rủi ro chính của việc đổi contract.
2. `test/<feature>_provider_test.dart` — service giả: tải thành công, lỗi API, lỗi lạ, danh
   sách rỗng, tải thêm (nếu có), thao tác ghi thành công/thất bại.
3. Cập nhật `test/navigation_contract_test.dart` nếu route điều hướng đổi.

## 5. Quy trình một module

**Trước mỗi đợt:** spec ngắn cho đợt, gồm route còn lại của từng module, **mọi** nơi Flutter
gọi chúng (tìm theo tiền tố path trên toàn `lib/`, vì `admin_service.dart`,
`search_service.dart`, `home_service.dart`, `export_service.dart` gọi chéo nhiều domain), và
các quyết định riêng của module. Duyệt xong mới làm.

**Mỗi module:**

1. **Đối chiếu** — đọc controller cũ, so từng field với model trong `BackEnd/model/`, ghi lại rule
   nghiệp vụ đang có. Method service/provider Flutter không ai gọi được xoá ở bước này.
2. **Test backend trước** — service test mô tả đúng rule vừa ghi; routes test với hình dạng
   `{ data }` mới. Test đỏ.
3. **Backend** — repository → service → controller → routes → schema tới khi test xanh; xoá
   controller cũ.
4. **Flutter** — service test với JSON mới → model/service → provider (`ViewState`) → phần screen
   đọc state (`AsyncView`) → provider test. Sửa luôn các lời gọi chéo trong `admin_service`,
   `search_service`, `home_service`, `export_service` của domain này để màn quản trị, tìm kiếm,
   trang chủ và xuất dữ liệu không gãy.
5. **Siết** — gỡ module khỏi `LEGACY_MODULES` và `legacyFeatures`.
6. **Kiểm tra** — `npm test`; `dart analyze` (0 error, 0 warning, 0 info); `flutter test`; chạy
   thử backend thật và gọi từng endpoint của module; mở màn hình liên quan trên app.
7. **Commit** — một commit cho module (backend + Flutter), Conventional Commits tiếng Anh, thân
   commit giải thích vì sao. Sau commit, tóm tắt luồng chính của module (route → service →
   repository → màn hình) trong 5–10 dòng.

**Định nghĩa hoàn thành một module:** controller < 150 dòng, không `try`; mọi route có
`validate` + `asyncHandler`; response đúng §3.2; field trong repository khớp model; provider
dùng `ViewState`, screen đọc state qua `AsyncView`; đủ 4 file test (§3.4, §4.4); module không
còn trong hai danh sách miễn; ba lệnh kiểm tra xanh.

**Khi gặp phức tạp ngoài dự kiến** (cần đổi model, migrate dữ liệu, đổi hành vi người dùng
thấy được ngoài việc sửa lỗi field): dừng và hỏi, không tự mở rộng phạm vi.

**Nhánh:** commit và push thẳng lên `main`, không tạo nhánh riêng (quyết định của chủ dự án
ngày 2026-09-29, sau khi đợt 0 được gộp vào `main`). Mỗi commit vẫn phải tự xanh vì không còn
nhánh nào che chắn.

## 6. Đợt 0 — xoá code không ai dùng

Mỗi nhóm module một commit backend (route, handler, helper chỉ phục vụ chúng, test liên quan,
`route-contract.test.js` cập nhật trong cùng commit), cuối cùng 257 → 153 route; một commit cho
Flutter. Chia nhỏ để mỗi commit tự xanh và đọc lại được. **Không xoá model hay
collection nào**, không đụng dữ liệu MongoDB. Seed script đọc thẳng model nên không phụ thuộc
các route bị xoá.

### 6.1. Route xoá (104)

| Module | Route |
| --- | --- |
| chat (9/9 — xoá cả module) | `POST /group-chat/:groupID`, `POST /group-chat/:groupID/upload`, `GET /group-chat/:groupID`, `GET /group-chat/:groupID/latest`, `PUT /group-chat/:groupID/:messageID`, `DELETE /group-chat/:groupID/:messageID`, `GET /group-chat/:groupID/search`, `GET /group-chat/:groupID/statistics`, `DELETE /group-chat/admin/:groupID/clear` |
| jlpt (21/26) | `POST /jlpt`, `PUT /jlpt/:id`, `DELETE /jlpt/:id`, `PUT /jlpt/publish/:id`, `POST /jlpt/importExcel/:id`, `POST /jlpt/submit/:id` (trùng với `/:id/submit`), `POST /jlpt/:id/moji-goi`, `POST /jlpt/:id/bunpou`, `POST /jlpt/:id/dokkai`, `POST /jlpt/:id/choukai`, `PUT /jlpt/reading/:groupId`, `PUT /jlpt/listening/:groupId`, `PUT /jlpt/question/:questionId`, `DELETE /jlpt/question/:questionId/:type`, `DELETE /jlpt/group/:groupId/:type`, `GET /jlpt/answers/:id`, `GET /jlpt/history/me`, `GET /jlpt/history/:historyId`, `GET /jlpt/stats/:id`, `GET /jlpt/results/:id`, `GET /jlpt/admin/all` |
| progress (12/18) | `POST /progress/lesson/:lessonID`, `POST /progress/lesson/:lessonID/update`, `DELETE /progress/lesson/:lessonID`, `GET /progress/study-time`, `GET /progress/achievements`, `GET /progress/admin`, `GET /progress/admin/user/:userID`, `GET /progress/admin/stats`, `PUT /progress/admin/:id`, `DELETE /progress/admin/:id`, `DELETE /progress/admin/bulk/delete`, `DELETE /progress/admin/user/:userID/clear` |
| transactions (11/14) | `GET /transactions/my-transactions`, `GET /transactions/:id`, `PUT /transactions/:id/cancel`, `GET /transactions/stats/me`, `GET /transactions/admin/:id`, `PUT /transactions/admin/:id`, `DELETE /transactions/admin/:id`, `DELETE /transactions/admin/bulk/delete`, `GET /transactions/admin/stats/overview`, `GET /transactions/admin/user/:userId`, `POST /transactions/admin/:id/refund` |
| exercise (10/17) | `POST /exercise/lesson/:lessonID`, `PUT /exercise/:id`, `DELETE /exercise/:id`, `POST /exercise/questions/:id`, `PUT /exercise/questions/:id`, `DELETE /exercise/questions/:id`, `POST /exercise/upload/:id`, `GET /exercise/check-answers/:id`, `GET /exercise/my-results/:id`, `GET /exercise/admin/result/:id` |
| notifications (8/15) | `GET /notifications/:id`, `DELETE /notifications/clear/read`, `POST /notifications/broadcast`, `GET /notifications/admin/all`, `GET /notifications/admin/stats`, `PUT /notifications/admin/:id`, `DELETE /notifications/admin/:id`, `DELETE /notifications/admin/bulk/delete` |
| news (7/10) | `POST /news`, `PUT /news/:id`, `DELETE /news/:id`, `DELETE /news`, `GET /news/categories/all`, `GET /news/admin/all`, `GET /news/admin/stats` |
| vocabulary (7/20) | `GET /vocabulary/situations`, `GET /vocabulary/level/:levelEnum`, `GET /vocabulary/situation/search`, `GET /vocabulary/random/practice`, `POST /vocabulary/learn/:id`, `GET /vocabulary/admin/stats`, `GET /vocabulary/admin/export` |
| study-groups (4/17) | `POST /group/invite/:groupID/:userID`, `GET /group/admin/all`, `DELETE /group/admin/:groupID`, `GET /group/admin/statistics` |
| users (4/18) | `GET /users/me`, `GET /users/admin/users/:id`, `POST /users/admin/users`, `PUT /users/admin/users/:id/toggle-status` |
| lessons (3/13) | `GET /lesson/type/:loaiBaiHoc`, `POST /lesson/bulk`, `PATCH /lesson/:id` |
| notebook (3/12) | `GET /notebook/admin/all`, `GET /notebook/admin/stats`, `DELETE /notebook/admin/:id` |
| reports (3/10) | `GET /report/:id`, `PUT /report/admin/:id/priority`, `DELETE /report/admin/bulk/delete` |
| grammar (2/7) | `GET /grammar/popular/:level`, `POST /grammar/learn/:id` |

Không module nào khác mất route: achievements, flashcards, kanji, lesson-progress, settings,
srs, streaks giữ nguyên. Model `GroupChat` được giữ vì `group.controller.js` còn ghi và đếm
tin nhắn hệ thống; việc giữ hay bỏ các lệnh đó quyết định ở đợt 5.

Hệ quả người dùng thấy được: không có — các route trên không màn hình nào gọi. Hệ quả cho người
vận hành: đề JLPT, bài tập và tin tức chỉ thêm/sửa được bằng script (`seed-jlpt.js`,
`import-jlpt-*.js`, `seed-exercises.js`, `seed-news.js`); admin không còn xuất Excel từ vựng.

### 6.2. Flutter xoá

- `AchievementService.createAchievement` — gọi `POST /achievement/create` không tồn tại; màn
  quản trị thật dùng `AdminService.createAchievement`.
- `GrammarService.incrementGrammarView`, `favoriteGrammar`, `unfavoriteGrammar` và hai method
  tương ứng trong `GrammarProvider` — gọi `/grammar/:id/view` và `/grammar/:id/favorite` không
  tồn tại; không screen nào gọi.
- `lib/core/config/constants.dart` — không file nào import.

### 6.3. Kiểm tra trước và sau khi xoá

- Mỗi route: tìm lại bằng tay theo path và theo tên handler trên `FrontEnd/lib`,
  `BackEnd/scripts`, `BackEnd/tests`.
- Sau khi xoá: ba lệnh kiểm tra xanh; chạy thử các màn hình của những module bị cắt route
  (quản trị nội dung, JLPT, bài tập, tin tức, thanh toán, thông báo, nhóm học, báo cáo, sổ tay).

## 7. Thứ tự các đợt

| Đợt | Nội dung | Quyết định riêng cần chốt trong spec của đợt |
| --- | --- | --- |
| 0 | Xoá theo §6 | — |
| 1 | Hạ tầng chung (§3.3, §4.3) → grammar → kanji → flashcards | Kanji dùng chung SRS với vocabulary: đi qua `srsRepository` |
| 2 | exercise → jlpt (kèm `jlpt_provider`, `jlpt_exam_provider`, `jlpt_practice_provider`) | Rà `getSolutions` và luồng nộp bài với field thật của `LearningHistory` |
| 3 | progress (6 route dashboard + analytics admin) → users (kèm `auth_service`, `auth_provider`, `user_provider`) | Nguồn dữ liệu của dashboard: `LessonProgress` / `ActivityEvent` / `StreakDay` thay cho các field `NguoiHocID`… không tồn tại |
| 4 | settings → news → notebook → reports → notifications → transactions | Notifications: model hiện chỉ broadcast theo `target_level`, không có trạng thái đã đọc theo user — chọn thiết kế cho đếm/đánh dấu đã đọc |
| 5 | study-groups | Giữ hay bỏ việc ghi tin nhắn hệ thống vào `GroupChat` |
| 6 | Provider còn kiểu cũ dù backend đã theo khuôn (admin, achievements, lesson-progress, lesson, streak, search, export); rà lại module đã theo khuôn theo §3.2 (ví dụ `vocabulary` xoá trả về document thay vì `{ deleted }`, `unmarkLearned` trả `{ message }` không có `data`); đổi `OfflineCache.storageKey` sang `v2` để bỏ bản lưu dạng JSON cũ; cập nhật tài liệu (§9) | — |

`admin_provider.dart` (689 dòng) gọi nhiều domain: phần service của nó được sửa theo từng
module ở đợt 1–5 để màn quản trị luôn chạy; phần provider chuyển sang `ViewState` ở đợt 6.

## 8. Ngoài phạm vi

| Việc | Lý do | Làm khi |
| --- | --- | --- |
| Tách/vẽ lại 40 screen dài | Giai đoạn redesign UI sẽ vẽ lại; tách bây giờ là làm hai lần | Giai đoạn 3 của roadmap |
| Đổi tên field tiếng Việt của `User` | Cần migrate dữ liệu, đụng ~190 chỗ | Đợt riêng sau cùng |
| Đăng xuất không thu hồi token (`postLogout` không làm gì, JWT sống 24h) | Lỗi bảo mật, không phải khuôn code | Danh sách việc tiếp theo |
| Cày XP bằng nộp lại cùng bài tập / đề JLPT với `attempt_id` mới | Luật XP, cần quyết định sản phẩm | Danh sách việc tiếp theo |
| Đăng nhập phân biệt "sai tên" và "sai mật khẩu" | Lỗi bảo mật nhỏ | Danh sách việc tiếp theo |
| Rate limit trong RAM theo `req.ip`, không `trust proxy` | Vận hành / triển khai | Giai đoạn 4 của roadmap |
| Import từ vựng từ PDF | Tính năng mới | Khi có nhu cầu; luồng import đã tách bước đọc file nên chỉ cần thêm bộ đọc |
| Màn quản trị JLPT, bài tập, tin tức | Tính năng mới | Khi có nhu cầu, viết theo khuôn này |

Lỗi field sai (query `user_id`, `NguoiHocID`… không có trong model) **nằm trong** phạm vi: đó là
hệ quả bắt buộc của việc repository phải khớp model.

## 9. Tài liệu cập nhật ở đợt 6

- `docs/architecture/conventions.md` — thêm quy tắc response xoá, thao tác ghi ở provider,
  `api_envelope.dart`, `shared/http/schemas.js`, hai architecture test, service nhận
  `ApiClient` qua constructor.
- `CLAUDE.md` — số route, danh sách module, bỏ các "bẫy" không còn đúng. File này không nằm
  trong git (commit `6831420`), nên sửa tại chỗ và không có commit.
- `docs/architecture/out-of-scope.md` và `redesign-roadmap.md` — ghi rằng Tier B và phần
  đóng băng đã được chuyển khuôn theo spec này.
- `docs/architecture/project-structure.md` — thêm các file dùng chung mới.

## 10. Rủi ro

| Rủi ro | Kiểm soát |
| --- | --- |
| Flutter đọc sai JSON sau khi đổi contract | Service test với JSON thật cho mỗi feature; chạy thử màn hình sau mỗi module |
| Consumer chéo bị bỏ sót (`admin_service`, `search_service`, `home_service`, `export_service`) | Bước kiểm kê tìm theo tiền tố path trên toàn `lib/`, không chỉ trong feature cùng tên |
| Xoá nhầm route đang dùng | Kiểm tra tay từng route (§6.3); diff của `route-contract.test.js` được đọc lại trước commit |
| Bản lưu ngoại tuyến dạng JSON cũ | Đổi `storageKey` sang `v2` ở đợt 6, trước khi merge |
| Transaction cần replica set | Test không chạm MongoDB; chạy thử dùng DB phát triển trên Atlas như hiện nay |

## 11. Đo kết quả

| Chỉ số | Trước | Sau đợt 6 |
| --- | --- | --- |
| Route công khai | 257 | 153 |
| Module trong `LEGACY_MODULES` | 15 (chat bị xoá ở đợt 0 → 14) | 0 |
| Route không bọc `asyncHandler` | 189 | 0 |
| Khối `try` trong controller | 195 | 0 |
| Controller > 150 dòng | 15 | 0 |
| Provider tự quản `_isLoading` / `_error` | 19 (16 thuần + 3 lẫn) | 0 |
