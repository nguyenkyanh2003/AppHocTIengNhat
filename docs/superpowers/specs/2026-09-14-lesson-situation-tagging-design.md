# Thiết kế — Gắn nhãn tình huống thực tế cho bài học

Ngày: 2026-09-14 · Trạng thái: đã duyệt qua brainstorming, chưa triển khai

Tài liệu này chốt cách thêm một trục phân loại "tình huống thực tế" (đi siêu thị, đi tàu,
đi bệnh viện, làm giấy tờ hành chính...) vào feature bài học (`Lesson`), lấy cảm hứng từ cách
tổ chức nội dung của [つながる（Tsunagaru）](https://tsunagarujp.mext.go.jp/level00/d03) — 39
tình huống đời sống, độc lập với cấp độ ngôn ngữ. Đây là bổ sung, không thay thế, cho tổ chức
theo cấp độ JLPT hiện có; xem thêm [redesign-roadmap.md](../../architecture/redesign-roadmap.md)
và [phase-2-plan.md](../../architecture/phase-2-plan.md) cho bối cảnh chung của dự án.

## 1. Bối cảnh và lý do

Nội dung `Lesson` hiện tổ chức thuần theo **chủ điểm ngữ pháp/từ vựng đúng thứ tự giáo trình
JLPT** (ví dụ: "Chào hỏi cơ bản", "Số đếm 1-100" ở N5; "Thể て", "Thể た" ở N3). Đây là mô hình
hợp lý cho việc học ngữ pháp tuần tự, nhưng khác hẳn trục tổ chức theo **tình huống đời sống**
mà Tsunagaru dùng — nơi một tình huống như "đi siêu thị" gom đúng từ vựng/mẫu câu cần dùng
trong tình huống đó, không quan tâm nó thuộc cấp độ ngữ pháp nào.

Lý do thêm trục này ngay bây giờ dù nội dung tình huống thật chưa có: nó khớp với hướng đi đã
định trong `phase-2-plan.md` §5 (luyện nói AI tổ chức theo `topic`) — nếu bài học cũng có khái
niệm "tình huống", về sau có thể kể một câu chuyện nhất quán "học từ vựng theo tình huống → luyện
nói cùng tình huống → chọn từ vào SRS". Tài liệu này **không** giả định trước hình dạng module
luyện nói (chưa tồn tại) — chỉ chuẩn bị đúng một trục dữ liệu cho lessons, độc lập.

## 2. Hiện trạng (đối chiếu mã nguồn ngày 2026-09-14)

| Thành phần | Thực trạng |
| --- | --- |
| `BackEnd/model/Lesson.js` | `title` (unique), `level` (enum N5-N1), `order`, `description`, `content_html` (một khối HTML tự do), `type` (string tự do, có index nhưng không dùng trong seed), tham chiếu `vocabularies`/`grammars`/`kanjis` |
| `BackEnd/src/modules/lessons/lesson.controller.js` | 275 dòng, **không theo khuôn 4 tầng** của dự án: tự query Mongoose trực tiếp trong controller, tự `try/catch` + `sendError` viết tay, không có schema zod. 11 hàm export tương ứng 11 route. |
| `BackEnd/src/modules/lessons/lesson.routes.js` | 11 route: `GET /`, `GET /level/:capDo`, `GET /type/:loaiBaiHoc`, `GET /stats/overview`, `GET /:id`, `POST /`, `POST /bulk`, `PUT /:id`, `PATCH /:id`, `DELETE /:id`, `DELETE /`, `POST /:id/duplicate` |
| `BackEnd/scripts/seed-lessons.js` | 10 lesson mẫu, tất cả là chủ điểm ngữ pháp/từ vựng — **không bài nào là một tình huống đời sống thật** (chào hỏi, số đếm, gia đình, thời gian, động từ nhóm I, tính từ đuôi い, thể て, thể た, kính ngữ, câu điều kiện) |
| Flutter `features/lessons/` | `Lesson`/`LessonDetail` model đọc field theo tên, bỏ qua field lạ; `lesson_list_screen.dart`, `lesson_detail_screen.dart`, `lesson_study_screen.dart` (773–806 dòng, đã vượt giới hạn 300 dòng của `conventions.md` — nợ kỹ thuật có sẵn, không thuộc phạm vi đợt này) |
| Phase 2 speaking AI | Mới có thiết kế (`phase-2-plan.md` §5), **chưa có code** — `src/modules/speaking/` chưa tồn tại. `speaking-topics.js` dự kiến 3 chủ đề mẫu (tự giới thiệu, sinh hoạt, ăn uống), chưa chốt taxonomy đầy đủ |

## 3. Quyết định thiết kế

Chốt qua brainstorming ngày 2026-09-14:

| Câu hỏi | Quyết định | Vì sao |
| --- | --- | --- |
| Tình huống thay thế hay bổ sung cho level? | **Bổ sung, song song.** Giữ `level` làm trục chính | 10 lesson hiện có và mọi liên kết SRS/progress đều dựa vào level; thay thế đòi thiết kế lại IA + soạn lại toàn bộ nội dung ngay, không cần thiết ở bước hạ tầng |
| `content_html` có đổi thành dialogue có cấu trúc? | **Không, giữ nguyên** | Đợt này chỉ mở hạ tầng phân loại; cấu trúc hội thoại/audio là quyết định content lớn hơn, để lại khi thật sự cần (ví dụ khi nối với luyện nói AI) |
| Danh sách tình huống lưu ở đâu? | **Enum cố định trong code**, không phải collection admin | Quy mô một người làm, 10-15 giá trị khởi điểm; thêm tình huống mới là sửa một hằng số, không cần CRUD admin |
| Catalog có dùng chung với `speaking-topics.js` không? | **Không giả định trước** — đặt riêng trong `modules/lessons/` | `speaking` module chưa tồn tại, chưa có spec taxonomy; thiết kế trước cho một module chưa có hình dạng là đoán mò, vi phạm ranh giới module trong `conventions.md` |
| Có sửa UI Flutter đợt này? | **Không** — chỉ backend + seed | Tách việc thêm field khỏi việc tách lại 2 screen đã quá khổ; Flutter đọc field lạ vẫn an toàn vì bỏ qua field không nhận diện |
| 10 lesson cũ và lesson mẫu mới xử lý thế nào? | **Chỉ hạ tầng, để `situation` trống hết**, không ép gán bừa cho 10 bài cũ, không thêm bài mẫu mới | 10 bài cũ thật sự không phải tình huống — gán bừa là làm sai dữ liệu. Soạn nội dung tình huống thật là việc riêng, ngoài phạm vi |
| Có refactor `lesson.controller.js` về 4 tầng không? | **Có** — vì đằng nào cũng phải sửa controller để thêm filter | Đúng yêu cầu bắt buộc trong CLAUDE.md/`conventions.md` cho mọi thay đổi code, và đúng tinh thần "clean nhất có thể" của yêu cầu gốc |

## 4. Data model

`BackEnd/src/modules/lessons/situation-catalog.js` (file mới):

```js
export const SITUATIONS = Object.freeze([
  'supermarket',       // đi siêu thị
  'convenience_store', // cửa hàng tiện lợi
  'train',             // đi tàu/ga
  'bus',               // đi xe buýt
  'hospital',          // đi khám bệnh
  'pharmacy',          // hiệu thuốc
  'city_hall',         // làm giấy tờ hành chính (phường/quận)
  'bank',              // ngân hàng
  'post_office',       // bưu điện
  'restaurant',        // nhà hàng/quán ăn
  'school',            // trường học/lớp học
  'part_time_job',     // công việc làm thêm
  'phone_call',        // gọi điện thoại
  'real_estate',       // tìm/thuê nhà
  'emergency',         // tình huống khẩn cấp/thiên tai
]);
```

Danh sách khởi điểm, không nhằm phủ đủ 39 tình huống của Tsunagaru — thêm giá trị mới chỉ là
sửa mảng này, không cần migration vì field không bắt buộc và không có logic phụ thuộc số lượng.

`BackEnd/model/Lesson.js` — thêm một field, không đổi field nào khác:

```js
situation: { type: String, enum: SITUATIONS, default: null, index: true },
```

Field optional, không `required`. Vì không có ràng buộc bắt buộc và không có giá trị mặc định
khác `null`, 10 document hiện có **không cần ghi lại** — Mongoose đọc field vắng mặt thành
`null`/`undefined` tự nhiên. **Không có bước migration dữ liệu nào trong đợt này.**

## 5. Refactor `lessons` về 4 tầng

Route giữ nguyên đúng 11 method+path đang có (bảng ở §2) — `route-contract.test.js` chỉ khoá
method/path nên không cần đổi `expectedCount`/`expectedSignatureHash`, chỉ cần chạy `npm test`
để xác nhận.

```text
BackEnd/src/modules/lessons/
├── lesson.routes.js         # 11 route như cũ, đổi import sang controller mới
├── lesson.schema.js         # zod: query list, body create/update
├── lesson.controller.js     # chỉ map HTTP, đọc req.valid, gọi service — < 150 dòng
├── lesson.service.js        # rule nghiệp vụ, không biết req/res
├── lesson.repository.js     # mọi Lesson.find/create/update/delete + query chéo Vocabulary/Grammar/Kanji
└── situation-catalog.js     # SITUATIONS
```

### `lesson.schema.js`

- `listQuery`: `page` (int ≥1, mặc định 1), `limit` (int 1-100, mặc định 10), `level` (enum
  N5-N1, optional), `type` (string, optional), `situation` (enum `SITUATIONS`, optional),
  `search` (string, optional, trim).
- `createBody`/`updateBody`: `title` (string, required khi create), `level` (enum, required
  khi create), `order` (int ≥1, optional), `description`, `content_html`, `type`, `situation`
  (enum, optional) — validate ở middleware trước khi tới controller, thay cho các `if
  (!LEVELS.includes(...))` viết tay rải rác hiện tại.
- `bulkBody`: mảng 1-100 phần tử theo `createBody`.
- `idsBody` (cho `DELETE /`): mảng 1-100 ObjectId string.

Input hợp lệ `situation` không nằm trong `SITUATIONS` → 400 ở tầng validate, controller không
bao giờ thấy giá trị sai.

### `lesson.repository.js`

Giữ nguyên các thao tác đang có trong controller cũ, đưa nguyên văn logic (không đổi hành vi):
`findMany({ level, type, situation, search, page, limit })`, `findByIdWithRelations(id)` (bao
gồm fallback query `Vocabulary`/`Grammar`/`Kanji` theo `lesson`/`lesson_id`/`lessonId` khi mảng
tham chiếu rỗng — đúng như `getById` hiện tại), `findByLevel`, `findByTypePattern`,
`aggregateStats`, `create`, `createMany`, `updateById`, `deleteById`, `deleteMany`, `duplicate`,
`countRelated(lessonIds)`.

`situation` lọc bằng so khớp chính xác (`query.situation = situation`), **không** dùng regex
như `type` — vì đây là enum, không phải chuỗi tự do cần tìm gần đúng.

### `lesson.service.js`

- `list(filters)` → gọi repository, tính `totalPages`.
- `getDetail(id)` → 404 qua `ApiError.notFound` nếu không có; giữ nguyên logic fallback populate.
- `create`/`update`/`duplicate` → validate nghiệp vụ còn lại (nếu có), gọi repository.
- `remove(id)`/`removeMany(ids)` → gọi `countRelated` trước, ném `ApiError.conflict` nếu còn
  vocabulary/kanji/grammar tham chiếu — giữ đúng hành vi 409 hiện tại.
- Không còn `try/catch` nào — mọi lỗi là `ApiError` hoặc lỗi Mongoose được `error.middleware.js`
  dịch (đã xử lý `ValidationError`/`CastError`/duplicate key ở tầng chung, theo `conventions.md`).

### `lesson.controller.js`

Chỉ còn: đọc `req.valid.query`/`req.valid.params`/`req.valid.body`, gọi service tương ứng, trả
qua `respond.js` (`ok`/`list`/`paginated`). Giữ nguyên hình dạng response hiện tại
(`totalItems/totalPages/currentPage/data` ở list, object phẳng kèm `tuvungs`/`nguphaps` ở
detail) để **không phá consumer Flutter** — chuẩn hoá sang `{ data, page, limit, total,
totalPages }` là việc khác, ngoài phạm vi vì Flutter chưa được đụng tới ở đợt này.

## 6. Rollout

1. Thêm `situation-catalog.js`, field `situation` vào model — không migration, không downtime.
2. Refactor 4 tầng theo §5, hành vi giữ nguyên 100% cho mọi field/route đã có.
3. `scripts/seed-lessons.js`: cho phép object lesson có thêm key `situation` (optional) — không
   bắt buộc điền, 10 bài mẫu hiện tại **không đổi**, không gán `situation` cho bài nào.
4. Flutter: không đổi gì. `Lesson.fromJson` hiện tại bỏ qua field lạ, response có thêm
   `situation` không ảnh hưởng.

## 7. Test bắt buộc

Theo bộ test tối thiểu của `conventions.md`, không test nào chạm MongoDB:

- `lesson.service.test.js` (repository giả): list lọc đúng theo `level`/`type`/`situation`/
  `search` kết hợp; `situation` không nằm trong enum bị chặn ở schema chứ không rơi tới service;
  xoá bị chặn 409 khi còn vocabulary/kanji/grammar tham chiếu; xoá qua khi không còn tham chiếu
  nào; `getDetail` áp đúng fallback populate như hành vi cũ.
- `lesson.routes.test.js` (Express + supertest, service giả): `GET /?situation=supermarket` khi
  chưa có lesson nào → 200 + `data: []` (không phải 404); `GET /?situation=khong-hop-le` → 400;
  toàn bộ 11 route vẫn đúng method/path và mã trạng thái như trước refactor.
- `route-contract.test.js`: chạy lại, xác nhận `expectedCount`/`expectedSignatureHash` **không
  đổi** — nếu đổi thì đã lỡ tay đổi path, phải xem lại chứ không sửa hash cho xanh.
- `npm test` toàn bộ + `dart analyze --fatal-infos` + `flutter test` (Flutter không đổi code
  nhưng phải xanh vì đây là cổng bắt buộc trước khi coi task xong).

## 8. Ngoài phạm vi

- Cấu trúc hội thoại (`dialogue`, `audio_url`, `can_do_goals`) cho `content_html` — quyết định
  content riêng, làm khi thật sự cần (ví dụ khi thiết kế module luyện nói AI).
- Soạn nội dung bài học theo tình huống thật (60 từ, 3+ chủ đề như `learning-loop-program-design.md`
  §4.2 đã định cho luyện nói) — dự án nội dung riêng, không phải phần hạ tầng này.
- Sửa Flutter (`lesson_list_screen.dart`, `lesson_detail_screen.dart`, `lesson_study_screen.dart`)
  để hiển thị/lọc theo `situation` — kể cả việc tách 2 screen đã vượt 300 dòng, thuộc Giai đoạn 3
  (redesign UI) theo `redesign-roadmap.md`, không phải đợt này.
- Chuẩn hoá response contract của `lessons` sang `{ data, page, limit, total, totalPages }` —
  đổi contract cần rà consumer Flutter trước, ngoài phạm vi khi Flutter chưa đổi.
- Dùng chung taxonomy tình huống với `speaking-topics.js` — quyết định khi module `speaking`
  thực sự được thiết kế.
- Collection `Situation` có CRUD admin — cân nhắc lại nếu số tình huống vượt xa quy mô enum
  tiện quản lý (ví dụ tiến gần 39 mục và cần một người khác ngoài dev chỉnh sửa).

## 9. Rủi ro và điểm mở

- **Refactor 4 tầng đụng cả các hàm không liên quan `situation`** (CRUD admin, `duplicate`,
  `stats/overview`) — rủi ro thấp vì hành vi giữ nguyên và có test route/service bao phủ đủ
  các nhánh trước khi coi refactor xong, nhưng phạm vi review lớn hơn một patch thêm field đơn
  thuần.
- **Danh sách 15 tình huống khởi điểm là suy đoán**, chưa đối chiếu với nguồn nội dung thật nào
  — khi soạn nội dung thật (ngoài phạm vi đợt này), có thể cần đổi tên/gộp/tách một số giá trị
  enum. Vì chưa có document nào gán `situation`, đổi enum ở giai đoạn này không tốn migration.
- **Không có tiêu chí "xong" bằng hành vi người học** cho riêng đợt hạ tầng này — nghiệm thu là
  kỹ thuật (test xanh, route contract không đổi), vì giá trị với người học chỉ xuất hiện khi có
  nội dung thật + UI Flutter, cả hai đều ngoài phạm vi đã nêu ở §8.
