# Mốc 1 — Khôi phục vòng ôn tập SRS cho từ vựng

Ngày: 2026-09-09 · Trạng thái: đã chỉnh sửa sau đối chiếu; chưa triển khai.
Chương trình: [learning-loop-program-design.md](2026-09-09-learning-loop-program-design.md).

Tài liệu này chốt thiết kế để viết implementation plan. Với mốc 1, contract dưới đây thay
cho các quyết định khác về route/phạm vi SRS trong
[phase-2-plan §A4](../../architecture/phase-2-plan.md). Giữ quy ước kiến trúc và kiểm thử chung.
Sửa spec không đồng nghĩa chức năng đã hoạt động hoặc dữ liệu Atlas đã được kiểm.

Phần ghi hoạt động, XP và ngày dùng chung
[spec streak Phần A](2026-09-09-streak-integrity-design.md). Bản đồng bộ này chốt 2 XP/lượt
SRS hợp lệ, thay quyết định 0 XP trước đó; không triển khai một writer streak riêng cho SRS.

## 1. Hiện trạng và mức độ kiểm chứng

Đã đọc mã hiện tại và chạy `node --test tests/srs-scheduling.test.js` trong `BackEnd`:
8/8 test đạt. Chưa truy vấn Atlas, chưa kiểm chứng lịch sử sử dụng các endpoint.

| Thành phần | Điều kiểm được từ mã |
| --- | --- |
| `srs-scheduling.js` | Leitner, hộp 1–5, các hàm thuần và test lịch đã có |
| `srs.repository.js` | Dùng đúng `user`, `item_id`, `item_type`, `box`, `next_review`, `streak`; được `vocabulary.service.js` gọi khi đánh dấu đã học |
| Controller cũ | Query `user_id`/`next_review_date`; ghi `interval`/`ease_factor`/`repetitions`; những trường này không nằm trong model |
| Tạo thẻ qua controller cũ | Thiếu `user` và `next_review` bắt buộc, đồng thời dùng item type chữ thường; không tạo được document hợp lệ theo model hiện tại |
| Flutter `SRSService` | Không tìm thấy consumer trong `FrontEnd/lib`; gọi các đường `/srs/progress/:id`, `/srs/statistics`, `/srs/upcoming-count` không có trong router |
| Flashcard | Luồng lật thẻ thủ công riêng, chưa nối với `SRSProgress` |
| Kanji | `kanji.controller.js:postLearnById` trả thông báo chuyển sang lesson-progress, không tạo tiến độ SRS |

Không kết luận toàn bộ SRS đều không chạy: đường đánh dấu từ vựng đã học đã tạo tiến độ.
Điều còn thiếu là vòng ôn tập SRS qua API và giao diện người học.

### Bốn route admin hiện tại

| Route | Kết luận từ mã và kiểm tra cục bộ, không phải kết quả Atlas |
| --- | --- |
| `DELETE /admin/:id` | Dùng `findByIdAndDelete(id)`, không mắc lỗi tên trường trên; có thể xóa bản ghi tồn tại |
| `GET /admin/all` | Lọc `user_id` sai model. Với Mongoose 8.19.0 cài trong dự án, populate đường không có trong schema có thể ném `StrictPopulateError` khi có kết quả, làm API trả 500; không phải luôn trả `null` |
| `GET /admin/stats` | Đếm người dùng bằng `distinct('user_id')` sai model; với dữ liệu đúng schema, không có user ID ở trường này |
| `DELETE /admin/user/:userId/clear` | Query sai `user_id`; với dữ liệu đúng schema sẽ xóa 0 bản ghi nhưng vẫn trả thông báo thành công |

Kiểm tra populate dùng collection stub với model thật, không kết nối MongoDB. Không suy
ra số bản ghi hay kết quả các route trên Atlas; dữ liệu legacy có thể khác schema hiện tại.

## 2. Mục tiêu và phạm vi

Người học đánh dấu một từ vựng đã học → sau 24 giờ thẻ đến hạn → tự nhớ đáp án, lật thẻ và
chọn nhớ/chưa nhớ → lịch được cập nhật → xem số thẻ còn đến hạn và phân bố theo hộp.

**Mốc 1 chỉ nghiệm thu Vocabulary từ đầu đến cuối.** Sáu endpoint mới chỉ nhận
`item_type=Vocabulary`; không truyền thì mặc định giá trị này. `Kanji`, `Grammar` và
giá trị sai chữ hoa bị từ chối ở schema API. Model vẫn giữ enum `Vocabulary`/`Kanji`;
không xóa dữ liệu Kanji hợp lệ nếu có.

Kanji SRS cần spec riêng xác định đường học → tạo tiến độ và quan hệ với lesson-progress.
Ngoài mốc này còn có nối luyện nói, Grammar SRS, SM-2, màn xem lịch sử từng lượt ôn và ôn
offline. Event ôn vẫn được lưu ở Phần A để chống trùng, cấp XP và tính số liệu đã chốt.

## 3. Các quyết định thiết kế

### 3.1 Giữ Leitner và một nơi tính lịch

Giữ nguyên `srs-scheduling.js` và test hiện có:

| Hộp mới | Khoảng cách từ thời điểm xử lý đến lần ôn tiếp |
| --- | --- |
| 1 | 1 ngày |
| 2 | 3 ngày |
| 3 | 7 ngày |
| 4 | 14 ngày |
| 5 | 30 ngày |

Đúng lên một hộp, tối đa 5; sai về hộp 1 và đặt chuỗi đúng của thẻ về 0.
Một ngày trong lịch là 24 giờ; `next_review <= now` là đến hạn. Server cấp `now`,
service nhận clock qua tham số để test; Flutter chỉ hiển thị lịch server trả về.

Lý do giữ Leitner là phù hợp phạm vi, model và các test đã có. Không dùng lập luận
“SM-2 bắt buộc giao diện bốn nút”: [SM-2 gốc](https://www.super-memory.com/english/ol/sm2.htm)
dùng điểm 0–5; thuật toán và cách trình bày mức đánh giá là hai quyết định riêng.
Chuyển thuật toán sau này cần thiết kế dữ liệu, migration và UX riêng.

### 3.2 Dựng lại module theo bốn tầng

Theo [conventions.md](../../architecture/conventions.md), lấy vocabulary làm mẫu:

```text
BackEnd/src/modules/srs/
├── srs.routes.js                # route, authenticateUser, validate, asyncHandler
├── srs.schema.js                # params/query/body và giới hạn request
├── srs.controller.js            # map HTTP, không query DB
├── srs.service.js               # inject repository, clock, activity, unit of work
├── srs.repository.js            # giữ hàm cũ; thêm đọc đợt, CAS, reset, thống kê
└── srs-scheduling.js            # giữ thuật toán và test hiện có
```

Inject `streaks/streak.service.recordActivity` và unit of work trong `shared/db/`.
Repository SRS chỉ truy cập SRS/nội dung cần hydrate; việc ghi UserStreak, ActivityEvent,
StreakDay thuộc repository module streaks. Không mở transaction lồng nhau.

Xóa `srs-progress.controller.js` và `srs-progress.routes.js` khi thay thế xong.
Đổi import ở `src/app.js` cùng commit đổi router. Repository được **mở rộng**, không
ghi “giữ nguyên file” rồi yêu cầu thêm hàm. Không dự đoán số dòng controller mới.

### 3.3 Sáu route, phân biệt tạo tiến độ, ôn, reset và xóa

Tất cả route yêu cầu `authenticateUser`; user lấy từ phiên đăng nhập.
Các định danh item dưới đây là `Vocabulary._id`, không phải `SRSProgress._id`.

| Method | Path dưới `/api/srs` | Input | Response thành công |
| --- | --- | --- | --- |
| GET | `/due` | `item_type?`, `limit?`, `exclude_item_ids?` | 200 `{ data: SrsCard[], limit }` |
| GET | `/due/count` | `item_type?` | 200 `{ data: { item_type: "Vocabulary", total } }` |
| POST | `/review` | `{ item_id, item_type?, is_correct, expected_next_review }` | 200 `{ data: SrsProgress }` |
| GET | `/stats` | `item_type?` | 200 `{ data: { item_type, total_cards, due_count, by_box } }` |
| POST | `/items/:itemId/reset` | `{ item_type?, expected_next_review }` | 200 `{ data: SrsProgress }` |
| DELETE | `/items/:itemId` | `item_type?` ở query | 200 `{ data: { deleted: boolean } }` |

`SrsProgress` gồm `_id, item_id, item_type, box, next_review, streak`; ngày trả ISO 8601 UTC.
`SrsCard` thêm `item` chứa nội dung Vocabulary để vẽ hai mặt; nếu nội dung đã mất,
`item=null` và `unavailable=true`. `by_box` có đủ khóa `"1"` đến `"5"`, kể cả số lượng 0.

`expected_next_review` là giá trị nguyên vẹn từ thẻ đang thấy, không phải giờ client tự tính.
Nó ngăn request cũ bị áp dụng vào lịch ôn mới khi gửi lại muộn. Quyết định đến hạn vẫn dùng
giờ server; field này là điều kiện so khớp lịch, không cấp quyền hay quyết định giờ ôn.

Đường tạo tiến độ là `POST /api/vocabulary/:id/mark-learned`, dùng `initialProgress(now)`.
Review/reset chỉ sửa tiến độ tồn tại, không upsert. Đánh dấu đã học nhiều lần không đổi lịch
đã có; trường hợp tạo đồng thời dùng unique index và đọc lại bản ghi đúng user khi gặp
duplicate key. Đây là phần cần bổ sung test cho đường vocabulary hiện có.

Xóa đưa dấu đã học độc lập của từ vựng về chưa học. Gọi xóa lần nữa trả `deleted=false`.
Không hoàn tác điểm hay lịch sử hoàn thành bài học. Reset giữ từ trong lịch và dấu đã học.

Bỏ bốn route admin vì chưa tìm thấy consumer Flutter và ngoài demo, không vì “chưa bao giờ
chạy”. Bỏ `/my-cards` nghĩa là mốc này không có màn quản lý toàn bộ thẻ. Muốn mở lại admin
phải có nghiệp vụ và test quyền riêng. Tổng route **12 → 6**, cập nhật route contract.

### 3.4 Lấy lại đợt đầu, có loại trừ trong phiên

Không dùng `page`/`skip` cho luồng ôn. Mỗi request lấy tối đa `limit` thẻ còn đến hạn,
sắp xếp `{ next_review: 1, _id: 1 }`; mặc định 20, tối đa 100. Làm hết đợt cục bộ rồi
lấy lại đợt đầu. Đây là lựa chọn đơn giản cho luồng này, không phải kết luận mọi cursor sai:
cursor giữ giá trị khóa cũ vẫn có thể được thiết kế đúng. Đây là suy luận thiết kế từ
[cách dùng mốc đã lưu cho range query](https://www.mongodb.com/docs/manual/reference/method/cursor.skip/),
không phải cam kết mọi cursor trên dữ liệu thay đổi đều an toàn.

Offset có thể bỏ sót: 40 thẻ, ôn 20 thẻ đầu rồi `skip=20` bỏ qua 20 thẻ còn lại.
Trả lời sai cũng đưa thẻ khỏi tập đến hạn vì hẹn sau 24 giờ.

Client giữ `handledItemIds` trong bộ nhớ phiên. Thêm ID khi review/reset/xóa thành công,
khi chọn “Bỏ qua trong phiên”, hoặc xử lý xong thẻ 404/409 chưa đến hạn.
Không thêm khi lỗi mạng hoặc lỗi máy chủ chưa xác định kết quả.

Gửi tập này qua `exclude_item_ids` dạng các ObjectId ngăn bằng dấu phẩy, dựng URL bằng
`Uri.queryParameters`. Backend validate, dedupe, áp dụng `item_id: { $nin: ids }`
**trước sort/limit**. Chỉ lọc client sau khi nhận đợt đầu không đủ: N thẻ bỏ qua có thể
chiếm hết đợt và chặn toàn bộ thẻ phía sau.

Giới hạn thiết kế: tối đa 200 ID loại trừ và 200 thẻ xử lý trong một phiên. Client giảm
`limit` theo số chỗ còn lại; đạt giới hạn thì kết thúc và cho mở phiên mới. Vượt giới hạn
request trả 400. Đây là giới hạn được chọn cho mốc 1, không phải số liệu sử dụng hiện tại.

Batch rỗng kết thúc phiên kể cả khi badge >0 vì đã bỏ qua các thẻ còn đến hạn.
Phiên mới xóa tập loại trừ; thẻ bỏ qua xuất hiện lại. Bỏ qua không đổi DB.
`countDue` đếm toàn bộ Vocabulary đến hạn của user, không nhận tập loại trừ, không bằng
`data.length`. Batch/count đọc ở hai thời điểm, không hứa snapshot chung; refresh badge
khi vào hub, sau mutation và khi kết thúc phiên.

Thẻ có `item=null` hiển thị “Nội dung không còn tồn tại”, không cho trả lời; cho bỏ qua
hoặc xóa tiến độ. Không âm thầm xóa trong GET. Review thẻ này trả 409 `ITEM_UNAVAILABLE`.

### 3.5 Review nguyên tử, request trùng và xung đột

Chỉ nhận boolean `is_correct`. Người dùng tự nhớ, lật đáp án, chọn “Nhớ”/“Chưa nhớ”;
không mô tả đây là tự động chấm kiến thức.

Giữ `applyAnswer` ở JavaScript nghĩa là cần **đọc tiến độ trước khi tính**, sau đó ghi có
điều kiện. Luồng thành công đã có đọc + ghi. Tính ngay trong DB sẽ cần viết lại thuật toán
thành update pipeline, trái quyết định giữ một nơi tính lịch.

1. Đọc theo user, item và type. Không có tiến độ thuộc user hiện tại → 404.
2. `next_review > now` → 409 `SRS_NOT_DUE`; vẫn đến hạn nhưng lịch khác
   `expected_next_review` → 409 `SRS_PROGRESS_CHANGED`.
3. Kiểm tra nội dung tồn tại, tính `applyAnswer(progress, isCorrect, now)`.
4. Ghi bằng `findOneAndUpdate`, không upsert, lấy bản sau cập nhật. Điều kiện đồng thời:
   đúng `user`, `item_id`, `item_type`, `_id` của document đã đọc; `box`, `streak`
   bằng giá trị đã đọc; `next_review` bằng giá trị kỳ vọng **và** `<= now`.
5. Không khớp thì kết thúc/rollback transaction đó và đọc mới **vẫn theo user**: không còn → 404; chưa đến hạn → 409
   `SRS_NOT_DUE`; còn đến hạn nhưng đổi trạng thái → 409 `SRS_PROGRESS_CHANGED`.
   Không kết luận mọi `null` đều là “chưa đến hạn”.

Không phân loại conflict bằng cách đọc lại snapshot cũ trong transaction đã lỗi.
Write conflict của MongoDB được unit of work xử lý bằng retry transaction có giới hạn;
mỗi lần chạy lại phải đọc/kiểm lại lịch kỳ vọng, không phát lại update tính từ snapshot cũ.

Ghi so sánh trạng thái đã đọc bảo vệ lượt trả lời đồng thời và cạnh tranh với reset/xóa;
không tạo lại thẻ vừa bị xóa. Xem
[MongoDB: ghi nguyên tử và điều kiện trên giá trị hiện tại](https://www.mongodb.com/docs/manual/core/write-operations-atomicity/).

Hai request cùng lượt đến hạn chỉ một request được ghi. Request gửi lại sau mất response
nhận trạng thái hiện tại, không tăng hộp lần nữa. Request cũ đến vào kỳ ôn sau cũng bị chặn
bởi `expected_next_review`. Đây là chống ghi lặp có trả conflict, không lưu/phát lại
response 200 bằng idempotency key.

409 dùng contract lỗi có sẵn:
`{ message, code, details: { current_progress: SrsProgress } }`.
Flutter phải giữ được `statusCode`, `code`, `details` trong lỗi có kiểu; đưa thay đổi
`ApiException`/`ApiClient` và test tương thích vào implementation plan.

`SRS_NOT_DUE`: cập nhật trạng thái, thông báo và chuyển thẻ, không tăng số trả lời thành công.
`SRS_PROGRESS_CHANGED` khi vẫn đến hạn: tải trạng thái mới, yêu cầu chọn lại, không tự bỏ qua.
`ITEM_UNAVAILABLE`: cho bỏ qua/xóa. Không lộ dữ liệu user khác trong conflict.

### 3.6 Reset là thao tác riêng

Reset dùng `initialProgress(now)`: `box=1`, `streak=0`, `next_review=now+24h`.
Có thể reset khi chưa đến hạn; giữ `_id`, user, item, `createdAt` và dấu đã học.
Không upsert, không đổi nội dung, không tăng số lượt trả lời, hoạt động ngày hay XP.

Tên UI là “Đặt lại lịch ôn”, nói rõ lần tiếp theo sau 24 giờ. Muốn “học lại ngay” cần
quyết định khác về lịch; không ngầm coi `applyAnswer(false)` đáp ứng nhu cầu đó.

Reset nhận `expected_next_review`, đọc và ghi có điều kiện theo document/trạng thái đã
đọc, nhưng **không yêu cầu đến hạn**. Không còn → 404; trạng thái đã đổi → 409
`SRS_PROGRESS_CHANGED` kèm tiến độ hiện tại. Không tự gửi lại reset với lịch mới sau
conflict, tránh request cũ liên tục đẩy ngày ôn ra sau.

### 3.7 Chưa xác định có cần migrate dữ liệu

Schema hiện tại không chứng minh dữ liệu lịch sử sạch. Import trực tiếp, update cũ hoặc
phiên bản model trước có thể tạo document khác. Audit Atlas: **chưa chạy**.

Trước migration/cutover mốc 1 trên dữ liệu thật, plan phải có audit chỉ đọc bằng native
collection để xem dữ liệu thô, ghi database/collection, thời điểm và số lượng theo nhóm.
Có thể viết code và test trên fixture/DB kiểm thử trước khi audit Atlas hoàn tất:

- Thiếu/sai kiểu `user`, `item_id`; tham chiếu User/Vocabulary/Kanji không tồn tại.
- Thiếu, null hoặc sai kiểu Date của `next_review`.
- `item_type` ngoài enum; phân biệt Kanji hợp lệ với dữ liệu hỏng.
- `box` không nguyên trong 1–5; `streak` không nguyên không âm.
- Trường legacy `user_id`, `next_review_date`, `interval`, `ease_factor`, `repetitions`,
  `status` hoặc trường cũ khác của controller.
- Trùng `(user, item_id)` theo unique index hiện tại; kiểm tra index thực tế tồn tại.

Không log credential hoặc toàn bộ document cá nhân. Có bất thường thì bổ sung migration/
sửa index với phân loại, dry-run, backup, quy tắc giữ dữ liệu và kiểm sau chạy.
Không xóa/chuyển Kanji hợp lệ để làm sạch số liệu. Chỉ kết luận không cần migration khi
mọi kiểm tra đạt, và chỉ áp dụng kết luận cho tập dữ liệu đã kiểm.

## 4. Flutter và điều hướng

```text
FrontEnd/lib/features/srs/
├── models/                      # progress/card/batch/stats đúng contract
├── services/srs_service.dart     # sáu endpoint, lỗi có kiểu, không tính lịch
├── providers/srs_provider.dart  # ViewState tải; state riêng cho mutation/phiên
├── screens/srs_review_screen.dart
└── widgets/                     # thẻ, thao tác, thống kê, tóm tắt
```

Dùng `AppScaffold`, `ContentPane`, token và `AsyncView` cho tải ban đầu:
loading/lỗi/rỗng/có dữ liệu. Lỗi gửi câu trả lời giữ nguyên thẻ/danh sách, hiển thị lỗi
thao tác cùng nút thử lại; không thay session bằng `ViewFailure` mất dữ liệu.
Khóa nút khi gửi. Chỉ chuyển thẻ/tăng bộ đếm sau khi xử lý response đúng quy tắc.
Không cache offline danh sách đến hạn hoặc xếp hàng mutation tự phát lại.

Giữ `/review` làm hub cho các hình thức ôn, thêm “Ôn tập hôm nay” → `/srs` và badge
Vocabulary đến hạn. Lý do là giữ cấu trúc sử dụng của hub; chi phí sửa test là yếu tố phụ.
Badge nằm trong provider, không đặt dữ liệu động trong metadata `app_navigation.dart`.

Reset/xóa có menu và xác nhận hậu quả trên thẻ. Thẻ chưa đến hạn vẫn có thể reset ở
màn chi tiết từ vựng: mở rộng response `GET /api/vocabulary/:id` bằng
`data.srs_progress: SrsProgress | null`, lấy từ truy vấn progress đã có trong
`vocabulary.service.getById`. Giữ các field hiện có; thêm test HTTP/model parsing.
Lấy chi tiết mới từ server trước thao tác, không lấy lịch cá nhân từ cache cũ; không
gọi mark-learned chỉ để đọc vì nó có thể tạo thẻ. Không cần route SRS thứ bảy.

Sau mutation làm mới badge/stats, tóm tắt streak/XP và dấu đã học; không đổi hoàn thành bài học.
Các điểm tích hợp: `app/router/app_router.dart`, `app/shell/app_navigation.dart`,
`app/shell/hub_screen.dart`, provider, detail Vocabulary cả hai đầu và lớp lỗi HTTP.
Screen mục tiêu dưới 250 dòng; tách widget theo trách nhiệm.
Cập nhật navigation contract cùng commit; kiểm tra web deep-link/reload/back.

## 5. Hoạt động ngày và luồng dữ liệu

`SRSProgress.streak` là chuỗi đúng của thẻ; `UserStreak.current_streak` là chuỗi ngày học.
Đúng/sai thành công đều ghi hoạt động theo `Asia/Ho_Chi_Minh`, không tăng ngày thêm lần nữa
nếu đã học hôm đó. **Mỗi lượt đến hạn được commit nhận 2 XP**, đúng/sai như nhau.
Reset, xóa, bỏ qua, 404/409 không ghi event học và không XP.

Ghi lịch, ActivityEvent, StreakDay và tóm tắt XP/ngày trong cùng transaction. Gọi
`recordActivity` sau khi thắng CAS nhưng trước commit, truyền cùng session và now.
Khóa event ghép `SRSProgress._id` + lịch `expected_next_review` cũ; không dùng ID thẻ một
mình và không thêm một khóa vào mảng reward_keys cho mỗi lượt ôn.

Lỗi ghi event/XP/ngày rollback cả lịch SRS; không trả lỗi sau khi đã commit một nửa.
Hai event khác nhau cùng ngày đều nhận 2 XP, ngày chỉ tăng một lần. Cạnh tranh/khởi tạo
summary dùng revision và unique index theo spec streak, không chỉ kiểm last_activity_day.

Nguồn ghi từ login/bài học/bài tập/JLPT/achievement, cách chuyển ngày legacy và bảo toàn số
dư nằm trong spec streak Phần A. SRS phụ thuộc phần này; không giữ writer cũ sau cutover và
không tự viết thêm một chính sách XP/timezone. Hoàn thành phần nền trước khi nối UI SRS.

```text
Đã học Vocabulary → tạo initialProgress, hoặc trả tiến độ đã có
Mở/lấy đợt → lọc user + Vocabulary + đến hạn + loại trừ → hydrate nội dung
Trả lời → transaction: đọc → kiểm → applyAnswer → CAS → recordActivity (2 XP/lượt, ngày học) → commit
        → trả tiến độ → chuyển thẻ, refresh badge/stats/streak
Reset → đọc → initialProgress → CAS không yêu cầu đến hạn, không hoạt động
Xóa → deleteProgress theo user/item/type → cập nhật dấu đã học, badge
```

Giữ API các hàm repository mà vocabulary đang dùng; thêm đọc đợt/count/CAS/reset/stats.
Unit of work và activity service dùng lại từ Phần A; không tạo adapter ghi UserStreak thứ hai.

## 6. Validation và lỗi

- Dùng `ApiError`, `asyncHandler`, `error.middleware.js`, helper `ok`.
- ID/ngày/boolean sai, query lạ, giới hạn sai → 400. Thiếu đăng nhập → 401.
- Không có tiến độ thuộc user hiện tại → 404, không tiết lộ user khác.
- Chưa đến hạn/đổi trạng thái/nội dung mất → 409 theo các mã ở §3.5–3.6.
- Batch rỗng → 200 `{ data: [], limit }`; DELETE lặp → 200 `{ data: { deleted: false } }`.
- Lỗi DB/transaction → middleware xử lý; Flutter giữ dữ liệu, cho thử lại.

Batch là ngoại lệ có chủ đích với phân trang chung: không trả `page`/`totalPages`,
không lấy `items.length` làm số đến hạn. Mọi endpoint, kể cả stats/count, scope Vocabulary.

## 7. Kiểm thử

Test mặc định không gọi Atlas/dịch vụ ngoài. Giữ test scheduler; service nhận repository,
clock, activity và unit of work giả. Test repository dùng model/collection stub để kiểm
tra truy vấn thật được dựng, không chỉ fake repository.

| Nhóm | Điều phải kiểm |
| --- | --- |
| Schema | Vocabulary mặc định/chữ hoa; từ chối Kanji/Grammar; ID/ngày/boolean; limit/exclusions |
| Repository | Đúng user/next_review/type; loại trừ trước limit; sort kép; guard CAS; không upsert; trả bản mới; DB session truyền đúng |
| Service | Đúng/sai; 404; chưa đến hạn; gửi trùng; request cũ sang kỳ ôn sau; cạnh tranh review/reset/delete; conflict vẫn đến hạn |
| Tạo tiến độ | Mark-learned lặp/đồng thời không trùng và không đổi lịch đã có |
| Reset/delete | Reset hẹn +24h, giữ dấu đã học, không activity/XP; retry không dời lịch; delete lặp |
| Batch | 40 thẻ/đợt 20; bỏ qua hết đợt đầu vẫn tới thẻ sau; tất cả bỏ qua thì dừng dù badge còn; giới hạn phiên; nội dung mất |
| Activity/unit of work | Sai vẫn tính ngày và 2 XP; hai thẻ cùng ngày nhận đủ 4 XP nhưng một ngày; cùng lượt retry không thêm XP; dùng chung activity với bài học; lỗi event/XP/ngày rollback lịch |
| HTTP | Router thật với middleware/controller và service stub: status/shape batch, stats, conflict; owner từ auth; route bỏ trả 404; Vocabulary detail thêm progress đúng user |
| Route contract | Đổi count/hash cho 12 → 6 route SRS cùng commit; hash không thay test HTTP |
| Flutter model/service | Ngày/type/nội dung thiếu; sáu endpoint; progress trong detail; giữ code/details lỗi |
| Flutter provider/screen | Bốn nhánh tải; lật trước tự đánh giá; lỗi mutation giữ thẻ; bấm đôi; 404/409; bỏ qua/reset/delete; conflict không tính câu đúng |
| Flutter tích hợp | Badge tổng/refresh; dấu đã học; reset khi chưa đến hạn; tóm tắt; navigation; overflow; web deep-link/reload/back |

Dùng clock giả ở `next_review-1ms`, bằng/sau hạn và chuỗi 1/3/7/14/30 ngày.
Số đúng/sai/bỏ qua của phiên nằm ở client, không trình bày thành lịch sử nhiều ngày.
Số liệu nhiều ngày nếu dùng phải đọc từ event/StreakDay đã commit theo spec streak;
không dùng bộ đếm phiên để suy ra tổng lịch sử.

Trước nghiệm thu thêm smoke test trên DB kiểm thử riêng hỗ trợ transaction: tạo fixture,
review đồng thời, đọc lại lịch/hoạt động, xác minh rollback. Stub không chứng minh hành vi
MongoDB thật. Không dùng Atlas dữ liệu người dùng làm fixture hoặc để test mặc định kết nối DB.

## 8. Tiêu chí hoàn thành

- Vocabulary đã học tạo một tiến độ hộp 1; trước 24 giờ chưa đến hạn, bằng hạn thì có.
- Ba lượt đúng ở ba lần đến hạn liên tiếp cho khoảng tiếp theo 3, 7, 14 ngày; sai về hộp 1
  và +24h. Kiểm bằng clock giả.
- Bấm đôi, retry, hai tab không tăng hộp/hoạt động/XP lặp cho cùng lượt đến hạn.
- Lịch, event, ngày và 2 XP cùng commit hoặc rollback trong smoke test DB kiểm thử.
- Nhiều đợt không bỏ sót do offset, không mắc vòng lặp do bỏ qua.
- Badge bằng tổng Vocabulary đến hạn, độc lập batch và tập loại trừ.
- Reset/xóa có hành vi/thông báo riêng; dấu đã học cập nhật đúng, reset được khi chưa đến hạn.
- Đủ luồng mạng lỗi, nội dung mất, conflict; không còn import thực thi controller/router cũ.
- Flutter SRS gọi đúng backend; Kanji không được quảng cáo như phần đã nghiệm thu.
- `npm test`, `dart analyze --fatal-infos`, `flutter test`, `flutter build web --release`
  đạt; navigation, overflow và web integration liên quan đạt.

## 9. Điểm chặn và giới hạn

| Điểm | Cách xử lý |
| --- | --- |
| Audit Atlas chưa chạy | Viết code/test với fixture được; audit phải đạt trước migration/cutover thật |
| Kanji chưa có đường vào SRS | Spec riêng trước khi mở API/UX Kanji; giữ dữ liệu hợp lệ |
| Transaction SRS chưa có | Dùng unit of work chung và smoke trên DB kiểm thử hỗ trợ transaction |
| Nhiều nơi ghi UserStreak | Phần A streak chuyển mọi writer, ngày legacy và contract đọc trước cutover |
| Bỏ route admin | Quyết định phạm vi; mở lại cần quyền và query đúng schema |
| Nội dung nói→SRS | Cổng nội dung trước mốc 2 trong spec chương trình; không tự tạo từ bằng AI ở mốc 1 |
