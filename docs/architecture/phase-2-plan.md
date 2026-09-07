# Giai đoạn 2 — Khôi phục vòng lặp học và thêm luyện nói cùng AI

Kế hoạch này là tài liệu thi công trọng tâm của Giai đoạn 2 (tuần 5–9) trong
[lộ trình thiết kế lại](redesign-roadmap.md). Mọi thay đổi phải theo
[quy ước code](conventions.md); ưu tiên dùng lại khuôn mẫu đã hoàn thiện ở
`BackEnd/src/modules/vocabulary/` và `FrontEnd/lib/features/vocabulary/`.

## 1. Mục tiêu và nguyên tắc

### Mục tiêu

1. Khôi phục các chức năng thuộc vòng lặp học: đánh dấu đã học → ôn SRS → ghi nhận tiến độ
   bài học → hiển thị lịch sử.
2. Chuẩn hóa tìm kiếm để frontend nhận kết quả thật, cùng một response contract.
3. Thêm một feature luyện nói có AI, nhưng giữ audio ở phía client và giữ API key ở backend.
4. Không làm vỡ dữ liệu hiện có, route đang được dùng hoặc màn hình ngoài phạm vi.

### Nguyên tắc bắt buộc

- **Đối chiếu model trước khi viết query.** Tên field mới dùng `snake_case`; các field tiếng
  Việt của `User` và dữ liệu legacy chỉ được dùng qua adapter, không đổi tên hàng loạt trong
  giai đoạn này.
- **Contract trước implementation.** Mỗi endpoint phải có schema zod, response mẫu, test
  contract và danh sách consumer. Một tài nguyên trả `{ data }`; danh sách trả `{ data, total }`;
  danh sách phân trang trả `{ data, page, limit, total, totalPages }`.
- **Service không biết `req`/`res`; repository là nơi duy nhất query Mongoose.** Controller
  chỉ map HTTP và dùng `req.valid`.
- **Không tự động tin dữ liệu do AI trả về.** Từ mới phải được kiểm tra với `Vocabulary`
  trước khi tạo SRS; transcript phải giới hạn độ dài và có chính sách xóa.
- **Không hard-code nhà cung cấp, model AI hoặc chi phí trong business logic.** Tất cả nằm ở
  biến môi trường và có giá trị kiểm tra được khi khởi động.
- **Feature cốt lõi phải demo được với một user.** Tính năng xã hội chỉ được mở lại nếu vẫn
  có trạng thái hữu ích với 1–2 tài khoản seed; Phase 2 không phụ thuộc matching hay realtime.

## 2. Hiện trạng cần ghi nhận trước khi sửa

Tạo một issue/checklist `phase-2-baseline` và lưu kết quả trước commit đầu tiên:

| Khu vực | Sự thật trong code hiện tại | Hệ quả cho kế hoạch |
| --- | --- | --- |
| SRS model | `SRSProgress` dùng `user`, `item_id`, `item_type` (`Vocabulary`/`Kanji`), `box`, `next_review`, `streak` | Không dùng các field legacy như `user_id`, `status`, `interval`, `quality` hay `grammar` |
| SRS repository | Đã có tìm/tạo/xóa cơ bản; chưa có due, count, answer hoặc thao tác idempotent | A4 phải mở rộng repository trước khi viết controller |
| SRS Flutter | `srs_service.dart` còn gọi `/progress`, `/review`, `/statistics`, `/upcoming-count` không tồn tại | A4 bắt buộc kèm migration service/model/provider của Flutter |
| JLPT history | `LearningHistory` là lượt thi, dùng `user`, `exam`, `taken_at`; một số hàm admin còn query `user_id`, `exam_id`, `completed_at` | A2 phải quét toàn bộ module, không chỉ sửa một query |
| Lesson progress | `LessonProgress` là model đúng cho tiến độ bài học và đã có module riêng | A3 dùng model này, không tái sử dụng `LearningHistory` |
| Search | Frontend fan-out 5 endpoint; vocabulary/kanji có contract riêng, list vocabulary bỏ qua `search` | A5 chuẩn hóa thành một endpoint global và giữ endpoint domain cũ nếu còn consumer |
| Ngoài lõi | Notification, news admin và billing có schema/consumer riêng | Chỉ ghi nhận phạm vi; không xóa route đang được payment/admin sử dụng |

Trước khi xóa hoặc đổi route, chạy `rg` trên cả `FrontEnd/`, `BackEnd/`, tài liệu và test.
Nếu phát hiện consumer ngoài repo, giữ route cũ ở trạng thái deprecated trong một release.

## 3. Data safety và migration gate

Đây là bước 0, phải hoàn thành trước A1–A4:

1. Sao lưu collection liên quan hoặc export mẫu ở môi trường development; không chạy migration
   trực tiếp trên production.
2. Đếm các document SRS thiếu `user`, `item_id`, `item_type`, `next_review`. Nếu có dữ liệu
   legacy, viết script migration có `--dry-run`, log số bản ghi đọc/ghi/lỗi và đường lui; không
   tuyên bố “dữ liệu cũ dùng nguyên vẹn” trước khi có số liệu.
3. Kiểm tra index hiện tại. Model đang unique theo `{ user, item_id }`, trong khi mọi query đều
   phân biệt `item_type`; quyết định và test migration sang `{ user, item_id, item_type }` để
   Vocabulary và Kanji không va chạm. Chỉ drop index cũ sau khi kiểm tra duplicate.
4. Ghi snapshot response của các route frontend đang dùng. Snapshot là chuẩn để viết adapter,
   không lấy tên field legacy làm chuẩn dữ liệu mới.

## 4. Phần A — Khôi phục chức năng chết

Mỗi mục dưới đây là một commit độc lập, có unit test/service test và cập nhật contract trong
cùng commit.

### A1. Kanji SRS

**Vấn đề:** controller Kanji còn query trực tiếp bằng `itemId`/`itemType`, trong khi model dùng
`item_id`/`item_type`.

**Cách làm:**

- Đưa thao tác tìm/tạo/xóa qua `srsRepository`; mở rộng repository bằng `ensureProgress` hoặc
  thao tác tương đương có thể chạy an toàn khi request lặp.
- Dùng literal canonical `item_type: 'Kanji'`; không tạo enum chữ thường hoặc `Grammar` trong
  SRS.
- Không cộng XP ở endpoint đánh dấu học nếu LessonProgress đã chịu trách nhiệm cộng XP.
- Test service với repository giả cho: tạo mới, đã tồn tại, xóa của đúng user, không xóa được
  card của user khác.

### A2. JLPT history

**Vấn đề:** các hàm trong `jlpt.controller.js` không nhất quán với `LearningHistory`; phần
admin còn dùng `user_id`, `exam_id`, `completed_at`.

**Cách làm:**

- Lập inventory tất cả query/aggregate của `LearningHistory` trong module JLPT.
- Đổi filter/populate/lookup sang `user` và `exam`; dùng `taken_at` hoặc `createdAt` theo đúng
  ý nghĩa nghiệp vụ, không tạo field `completed_at` giả.
- Nếu Flutter đang chờ `completed_at`, tạo DTO adapter ở service/response mapper và đánh dấu
  đây là compatibility field; không ghi ngược field đó vào model.
- Giữ behavior của các route thi hiện có; thêm test cho list history, detail, statistics và
  admin results, bao gồm trường hợp rỗng.

### A3. Lesson progress và learning history

**Vấn đề:** `progress.controller.js` dùng `LearningHistory` như tiến độ bài học với các field
`NguoiHocID`, `BaiHocID`, `TienDo`, `NgayHoc`, `ThoiGianHoc`. Những field này không tồn tại ở
model hiện tại.

**Cách làm:**

- Tách rõ hai bounded context:

  | Nghiệp vụ | Model |
  | --- | --- |
  | Lượt thi JLPT | `LearningHistory` (`user`, `exam`, `score`, `section_scores`, `taken_at`) |
  | Tiến độ bài học | `LessonProgress` (`user`, `lesson`, các counter/list learned, trạng thái) |

- Dùng `LessonProgress` repository/service cho các route progress cá nhân và admin; thống nhất
  ownership bằng `user` và `lesson`.
- Giữ path cũ trong giai đoạn này nhưng trả DTO tương thích với Flutter. Các field không có dữ
  liệu thật phải trả `null`/giá trị được định nghĩa trong contract, không bịa dữ liệu.
- `study-time` chỉ báo cáo metric có thể suy ra từ model hiện tại. Nếu cần số giây học thật,
  tạo migration field riêng (`study_seconds`) ở một issue khác; không nhét `ThoiGianHoc` vào
  `LessonProgress`.
- Viết contract fixture từ `learning_history_screen.dart` và provider, sau đó test get/list/
  update/delete/admin. Không lấy kích thước màn hình làm tiêu chí thành công; tiêu chí là JSON
  ổn định và dữ liệu thật.

### A4. SRS theo Leitner

`srs-scheduling.js` đã có hàm thuần `initialProgress`, `applyAnswer`, `nextBox`,
`nextReviewDate`, `nextStreak`, `isDue`; mọi rule lịch ôn phải dùng các hàm này.

#### Contract mới

| Method | Path | Body/query | Kết quả |
| --- | --- | --- | --- |
| GET | `/api/srs/due` | `item_type?`, `page`, `limit` | `{ data, page, limit, total, totalPages }`, item được hydrate theo type |
| GET | `/api/srs/due/count` | không bắt buộc | `{ data: { total, Vocabulary, Kanji } }` |
| POST | `/api/srs/cards` | `{ item_id, item_type }` | Tạo hoặc trả card hiện có; idempotent |
| POST | `/api/srs/answer/:id` | `{ is_correct: boolean }` | Card mới + XP/streak đúng một lần |
| DELETE | `/api/srs/cards/:id` | không có body | Xóa card thuộc user hiện tại |

`item_type` chỉ nhận `Vocabulary` hoặc `Kanji`. `POST /cards` là cần thiết cho nút “thêm vào
ôn tập” và cho speaking; không dùng lại `/review` với schema legacy.

#### Backend work items

- Viết `srs.schema.js`, repository methods `findDue`, `countDue`, `ensureProgress`, `answer`,
  `deleteOwned`; mọi query đều lọc `user`.
- Hydrate nội dung theo batch query, không `findById` trong vòng lặp; item đã bị xóa phải được
  xử lý rõ ràng (bỏ card mồ côi hoặc trả warning theo contract).
- Answer dùng `is_correct`, optimistic/version check hoặc thao tác atomic để hai request đồng
  thời không cộng XP hai lần. Streak/XP đi qua adapter được inject để test không cần MongoDB.
- Sau khi Flutter migration hoàn tất và đã quét consumer, deprecate rồi xóa `/review`,
  `/my-cards`, `/stats`, `/reset/:id`, `/admin/*` của module cũ. Cập nhật
  `route-contract.test.js` bằng giá trị sinh từ route thực tế; không sửa hash cho test xanh.

#### Flutter migration

- Cập nhật model/service/provider để đọc `{ data }` và pagination; xóa các method gọi route
  không tồn tại.
- Dùng canonical type và body `is_correct`; thêm test parse response, empty state, 401/404 và
  retry.

### A5. Global search

Không vá bằng cách thêm một query tùy ý vào mọi list schema. Các domain hiện có contract khác
nhau (`/vocabulary/search?keyword=`, `/kanji/search?keyword=`, list lesson/grammar/news).

**Thiết kế:** tạo module `BackEnd/src/modules/search/` và endpoint:

```text
GET /api/search?q=<text>&types=vocabulary,kanji,lesson,grammar,news&limit=5
→ { data: [{ id, type, title, subtitle?, description?, image_url?, level? }], total }
```

- `q` dài 1–100 ký tự, trim và escape regex; `types` là enum; giới hạn tổng số kết quả.
- Repository dùng projection/field map riêng cho từng model; không trả toàn bộ document hoặc
  nội dung HTML của news.
- Kết quả rỗng là 200 với `data: []`; không để một domain 404 làm hỏng toàn bộ tìm kiếm.
- Flutter `SearchService` gọi một endpoint, không fan-out; test sort/relevance, duplicate và
  partial failure.
- Giữ endpoint search riêng của domain nào còn consumer; thêm route contract và test mới.

### A6. Phạm vi ngoài lõi

Tạo [out-of-scope.md](out-of-scope.md), nhưng không xóa mù quáng route đang được dùng:

- **Notifications:** model chỉ có broadcast theo `target_level`, còn controller có logic
  recipient/read state chưa được model hóa. Tạm không sửa; ẩn các entrypoint read/unread nếu
  chúng hiển thị sai và ghi issue thiết kế lại.
- **News admin:** giữ phần đọc tin; CRUD admin và schema publish/category/tags là một milestone
  riêng. Model hiện có `image_url`, không tự đổi thành `thumbnail`.
- **Transactions/billing:** giữ nguyên vì có payment screen và admin consumer; chỉ không đụng
  trong Phase 2.
- **Notebook/report/settings và các màn admin còn lại:** giữ nguyên behavior; không kéo vào
  refactor cơ học chỉ vì còn thời gian. Muốn ưu tiên lại phải sửa roadmap và bảng out-of-scope
  trước khi code.
- **Study groups/group chat:** đóng băng implementation hiện có. Không refactor theo
  `conventions.md`, không thêm matching, Pomodoro/presence, WebSocket hay route mới trong Phase
  2. Kịch bản bảo vệ chỉ mở danh sách/chi tiết nhóm đã seed ở mức xem; không demo chat hoặc
  upload media. Vì chat không thuộc bản demo, Giai đoạn 4 không có task hardening riêng cho nó;
  muốn kích hoạt lại phải cập nhật roadmap, acceptance test và security plan trước khi code.
- **Grammar SRS, cloud STT, audio upload:** ngoài contract hiện tại; chỉ mở khi có thiết kế
  model/quota/privacy riêng.

## 5. Phần B — Luyện nói cùng AI

### 5.1 Luồng người dùng

1. Chọn topic và JLPT level.
2. Backend tạo session và trả lời mở đầu bằng tiếng Nhật.
3. Client dùng STT để chuyển lời nói thành text; TTS đọc phản hồi của AI.
4. Backend chấm một lượt: reply, sửa câu, giải thích tiếng Việt, điểm và candidate words.
5. Người dùng chọn từ muốn ôn; backend kiểm tra Vocabulary rồi gọi `srsRepository.ensureProgress`.
6. Kết thúc phiên: tổng điểm, lỗi lặp lại, số lượt, token usage và trạng thái.

Audio không được gửi tới backend trong Phase 2. Tuy nhiên `speech_to_text` và `flutter_tts`
phụ thuộc engine của từng nền tảng; không quảng cáo tuyệt đối là “offline/miễn phí”. Hiển thị
privacy notice và luôn có ô nhập chữ làm fallback.

### 5.2 Backend module

```text
BackEnd/src/modules/speaking/
├── speaking.routes.js
├── speaking.schema.js
├── speaking.controller.js
├── speaking.service.js
├── speaking.repository.js
├── speaking-ai.service.js       # nơi duy nhất gọi Anthropic
└── speaking-topics.js
```

Model `SpeakingSession` dùng snake_case và giới hạn kích thước:

```js
{
  user, topic_id, level,
  status: 'active' | 'finished' | 'expired',
  turns: [{ role, text_ja, corrected_ja, explanation_vi, score, spoken_at }],
  average_score, total_turns,
  new_words: [{ vocabulary_id, word, reading, meaning }],
  usage: { input_tokens, output_tokens },
  started_at, ended_at, expires_at
}
```

Quy tắc: tối đa 20 lượt/session, giới hạn ký tự mỗi turn, `user` bắt buộc, query history chỉ
trả session của user, `finish` idempotent, transcript không ghi vào log, và user có thể xóa
session của mình.

#### API

| Method | Path | Ghi chú |
| --- | --- | --- |
| GET | `/api/speaking/topics?level=N5` | Topic tĩnh, validate level |
| POST | `/api/speaking/sessions` | Tạo session, gọi AI mở đầu |
| POST | `/api/speaking/sessions/:id/turns` | Append một turn, quota + ownership check |
| POST | `/api/speaking/sessions/:id/finish` | Chốt điểm và danh sách candidate được chọn |
| GET | `/api/speaking/sessions` | Phân trang lịch sử của user |
| DELETE | `/api/speaking/sessions/:id` | Xóa transcript của chính user |

Response phải dùng helper `ok/list/paginated`; lỗi AI được map thành `ApiError` có mã retryable
hoặc non-retryable, không trả stack trace.

### 5.3 Anthropic integration

- Thêm `@anthropic-ai/sdk` ở backend và kiểm tra version tương thích với `zod` hiện tại.
- Chỉ `speaking-ai.service.js` được tạo/call client; nhận client qua dependency injection để
  test bằng fake.
- Dùng Structured Outputs (`output_config.format` + `zodOutputFormat` hoặc JSON Schema helper
  tương ứng với version SDK). Luôn kiểm tra `parsed_output`, `stop_reason === 'refusal'` và
  `stop_reason === 'max_tokens'`; structured output không có nghĩa là mọi refusal đều parse được.
- `SPEAKING_MODEL`, `SPEAKING_MAX_TOKENS`, `SPEAKING_DAILY_TURN_LIMIT`,
  `SPEAKING_MAX_INPUT_CHARS` là biến môi trường. Chọn model trong console tại thời điểm deploy;
  không ghi `claude-opus-5` hay một giá cố định vào code/plan như một sự đảm bảo lâu dài.
- `ANTHROPIC_API_KEY` chỉ nằm trong backend `.env`; `.env.example` chỉ có placeholder.
- Retry tối đa một lần cho timeout/5xx với backoff; không retry refusal/validation. Rate-limit
  theo user, log token counts và model, redact transcript khỏi log. Prompt injection trong text
  người học phải được coi là dữ liệu không tin cậy.
- Prompt caching chỉ là tối ưu sau khi baseline chạy ổn và đo được hit/miss; không gắn
  `cache_control` vào block thay đổi mỗi request.

### 5.4 Flutter feature

```text
FrontEnd/lib/features/speaking/
├── models/           # topic, turn, session
├── services/         # API, speech input, speech output
├── providers/        # ViewState<T>
├── screens/          # topics, session, summary (dưới 250 dòng)
└── widgets/          # mic button, turn bubble, correction, score
```

Thêm package STT/TTS ở version tương thích với Flutter lockfile; thêm permission Android/iOS,
kiểm tra web fallback và test provider. Screen không gọi service trực tiếp, dùng `AsyncView` và
tokens hiện có. Đăng ký `/speaking` và cập nhật `navigation_contract_test.dart` cùng commit.

### 5.5 Nối với SRS và streak

- AI chỉ trả candidate đã map được sang `Vocabulary._id`; word không tồn tại chỉ hiển thị để
  người học xem, không tự tạo SRS.
- `finish` nhận danh sách `vocabulary_id` mà user đã chọn, dedupe rồi gọi SRS service/repository
  idempotent.
- Mỗi turn hợp lệ chỉ cộng XP một lần sau khi ghi thành công; lỗi AI hoặc request retry không
  được cộng XP. Dùng adapter streak inject vào service.

## 6. Kiểm thử và nghiệm thu

### Test tự động

- Backend: test scheduling, SRS service/repository contract, progress/JLPT adapters, search
  normalization, speaking service, speaking AI client giả và route response. Không test nào gọi
  MongoDB thật hay Anthropic thật.
- Flutter: model parsing, provider state, API error/retry, microphone permission denied, web
  text fallback và navigation contract.
- Mỗi route mới hoặc route bị xóa phải cập nhật route hash/count; mỗi route Flutter mới phải
  cập nhật navigation contract.

### Smoke test theo vòng lặp

1. Mark learned Vocabulary và Kanji → card có đúng `item_type`, due count tăng đúng type.
2. Answer đúng/sai → box, streak và `next_review` đúng bảng Leitner; gửi lại request không nhân
   đôi XP.
3. Học một lesson → `/progress` đọc từ LessonProgress; thi JLPT → history đọc từ
   LearningHistory.
4. Search một từ → endpoint global trả kết quả đúng type; không có kết quả → 200 + mảng rỗng.
5. Speaking N5: start → turn → sửa lỗi → chọn word → finish; word đã chọn xuất hiện SRS.
6. Tắt mạng/Anthropic lỗi/permission microphone bị từ chối → thông báo rõ, retry an toàn,
   không mất session và không cộng XP sai.
7. Xác minh ownership: user A không đọc/xóa/answer session hoặc card của user B.

Lệnh tối thiểu trước khi merge:

```powershell
cd BackEnd; npm test
cd ..\\FrontEnd; dart analyze; flutter test
```

## 7. Thứ tự triển khai và commit

| Milestone | Nội dung | Điều kiện hoàn thành |
| --- | --- | --- |
| M0 | Baseline, backup/dry-run, index decision, response snapshots | Có checklist và rollback |
| M1 | A1 Kanji SRS + A2 JLPT field audit | Unit/contract test xanh |
| M2 | A3 LessonProgress adapter/service | Learning history có dữ liệu thật |
| M3 | A5 global search | Flutter chỉ gọi một contract |
| M4 | A4 SRS API + Flutter migration | Due/answer/card flow chạy end-to-end |
| M5 | A6 out-of-scope documentation/UI gating | Không route đang dùng bị xóa nhầm |
| M6 | Speaking backend → Flutter → SRS integration | Smoke test và quota/privacy test xanh |

Commit theo Conventional Commits, tách ít nhất: `fix(kanji)`, `fix(jlpt)`, `fix(progress)`,
`feat(search)`, `refactor(srs)`, `docs(scope)`, `feat(speaking-backend)`,
`feat(speaking-flutter)`. Không gộp A4 và speaking vào cùng commit.

## 8. Điều kiện chốt trước khi triển khai AI

- Có API key test ở backend và giới hạn chi phí/quota của tài khoản.
- Chọn model bằng `SPEAKING_MODEL` sau khi kiểm tra model ID còn active trong tài liệu Anthropic.
- Chốt privacy notice, thời hạn lưu transcript và nút xóa session.
- Chấp nhận fallback text khi STT/TTS không khả dụng.
