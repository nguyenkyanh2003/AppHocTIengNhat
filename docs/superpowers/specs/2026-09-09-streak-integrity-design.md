# Streak — độ tin cậy và cơ chế duy trì việc học

Ngày: 2026-09-09 · Trạng thái: đã chỉnh sửa sau đối chiếu; chưa triển khai.
Chương trình: [learning-loop-program-design.md](2026-09-09-learning-loop-program-design.md).

- **Phần A thuộc mốc 1:** thống nhất ghi hoạt động, quyền cấp XP, lịch ngày và migration.
- **Phần B là mốc 1B:** lịch, freeze, mục tiêu ngày và nhắc học; không chặn luyện nói ở mốc 2.

Spec này cùng [spec SRS](2026-09-09-srs-revival-design.md) là một thiết kế mốc 1.
Quyết định XP mới: **một lượt SRS đến hạn được ghi thành công nhận 2 XP**, đúng/sai như nhau.
Điều này thay quyết định 0 XP ở bản SRS trước; không để hai tài liệu áp dụng hai chính sách.

## 1. Hiện trạng và điều cần đính chính

Đối chiếu mã trong checkout ngày 2026-09-09; chưa truy vấn Atlas.

| Điều thấy trong mã | Hệ quả |
| --- | --- |
| Login gọi `user.repository.recordLoginStreak`, ghi ngày và 10 XP | Có thể nối chuỗi bằng đăng nhập, cần bỏ hành vi ghi này |
| GET `/streak/my-streak` tạo ngày học đầu khi thiếu document, có thể reset khi đọc | Đường đọc cần thuần đọc, user mới nhận tóm tắt số 0 |
| POST `/streak/add-xp` nhận số XP từ client; hai route test mở cho user | Phải đóng các đường ghi không dựa trên hoạt động hợp lệ |
| JLPT upsert `LearningHistory` theo `(user, exam)`; khối streak chỉ khởi tạo và ghi field lạ `xp` | Chưa ghi ngày học đúng; ID history không định danh riêng mỗi lần thi |
| `ExerciseResult.create` sinh ID mới mỗi lần POST | Dùng result ID để chống trùng sau khi tạo chưa chặn retry của cùng lần nộp |
| `lesson-progress.service.js` dùng XP mở bài 3, mục học 2, hoàn thành 20 | Số 15/5 trong bản phân tích cũ không phải chính sách của service hiện tại |
| `reward_keys` đang bảo vệ các khoản theo nội dung bài học | Không được suy ra nó có chặn trên nếu thêm khóa cho mọi lần nộp bài |
| `achievement/update-progress` cho client gửi tiến độ, có thể dẫn tới cấp XP | Bỏ add-xp chưa đóng hết đường tự cấp thưởng |
| `activity_dates`/`xp_history` tăng trong UserStreak; GET trả cả document | Cần tách lịch sử và sửa consumer, chưa có số liệu cho thấy sắp quá giới hạn |
| Leaderboard tuần/tháng lọc ngày lịch sử rồi sort `total_xp` cả đời | Khi đổi nguồn lịch sử cần tính đúng điểm trong kỳ và hạng trên cùng tập |
| Model chuyển giờ Việt Nam qua chuỗi rồi parse theo timezone host | Cần một cách biểu diễn ngày và migration có căn cứ |

Mốc huy hiệu `[7,14,30,50,100,365]` đã có, nhưng chỉ một số đường ghi gọi kiểm mốc.
Thưởng định kỳ và huy hiệu có thể là hai chính sách khác nhau; mốc này chọn bỏ bonus ngày/
bội số để giảm số luật, không khẳng định hai thang mốc là lỗi kỹ thuật tự thân.

## 2. Quyết định sản phẩm

Duolingo mô tả việc tách streak khỏi mục tiêu ngày trong
[Improving the streak](https://blog.duolingo.com/improving-the-streak/), và cơ chế nghỉ có
bảo vệ trong [bài về Streak Freeze](https://blog.duolingo.com/how-duolingo-streak-builds-habit/).
Không lấy giới hạn vật phẩm hoặc kết quả thử nghiệm của họ làm bằng chứng tối ưu cho app này.

| Quyết định | Chốt cho bản đầu |
| --- | --- |
| Login, GET, mở bài, mở nội dung | Không nối chuỗi, không XP |
| SRS đúng/sai | Một lượt đến hạn hợp lệ đủ nối chuỗi và nhận 2 XP |
| Bài tập/JLPT | Lần nộp hợp lệ do server chấm đủ nối chuỗi, không yêu cầu đỗ |
| Bài học | Hoàn thành mục/bài được server xác thực; thao tác lặp lại đã xử lý không tạo ngày mới |
| Đánh dấu từ độc lập/reset/xóa/bỏ qua | Không tính hoạt động học, không XP |
| Mục tiêu ngày | Mặc định 20 XP học trực tiếp; chọn 10/20/30/50; không chặn streak |
| Freeze | 1 vật phẩm bảo vệ 1 ngày đã kết thúc; tối đa 2; không đổi lịch SRS |
| Nguồn freeze | Bắt đầu 0; tặng 1 ở các mốc 7/14/30/50/100/365 sau khi bật Phần B; mỗi mốc một lần, đầy kho thì bỏ phần vượt |
| Chuỗi cũ | Không chấm lại theo luật học mới; bảo toàn baseline có kiểm chứng, xem migration |
| Vacation mode/repair/bạn bè | Ngoài phạm vi; không tự dời `next_review` để bảo vệ streak |

Các mức XP, mục tiêu và freeze là lựa chọn khởi đầu để nghiệm thu, chưa phải kết quả đo.
Hoàn thành mục/bài học vẫn có phần tự xác nhận của người học; server kiểm trạng thái và
nội dung, không được quảng cáo đã chứng minh người dùng nhớ kiến thức.

## 3. Phần A — một đường ghi, một nguồn sự kiện

### 3.1 Ranh giới module và transaction

`streaks/streak.service.js` cung cấp cổng nội bộ:

```js
recordActivity({ userId, type, sourceId, occurrenceKey, context }, { session, now })
```

Caller là service nghiệp vụ đã xác thực user/nội dung/kết quả. Không có endpoint cho client
gửi trực tiếp một “activity”, số XP, ngày học hay trạng thái huy hiệu.

Dùng routes → controller → service → repository theo
[conventions.md](../../architecture/conventions.md). Chỉ repository trong module streaks
import các model streak/event/day; ngoại lệ là khai báo model, migration và test.
Service nhận repository, clock và policy qua tham số; không import Mongoose model trực tiếp.

**Thứ tự trong cùng transaction:** ghi kết quả nghiệp vụ hoặc thắng CAS SRS → ghi event →
ghi ngày/tóm tắt/XP/huy hiệu → commit. “Sau khi nghiệp vụ ghi thành công” ở đây chưa phải
sau commit. Lỗi bất kỳ bước nào rollback tất cả; không nuốt lỗi để trả thành công một phần.

Một unit of work dùng chung trong `shared/db/`; module streaks nhận DB session hiện có,
không mở transaction lồng trong SRS. Phần callback retry chỉ chứa thao tác DB/tính toán thuần.
Mọi writer users, lesson-progress, exercise, JLPT, achievements phải chuyển cùng đợt cutover.
Không để một đường cũ tiếp tục đọc/sửa/save đè lên tóm tắt mới.

### 3.2 Nhật ký sự kiện thay mảng khóa và mảng XP

Dùng **ActivityEvent** làm nhật ký hoạt động đã được chấp nhận, kể cả sự kiện 0 XP.
Lịch sử XP là một cách đọc các event có XP; không tạo thêm XpEvent chứa dữ liệu trùng.

| Model | Trường và vai trò chính |
| --- | --- |
| `ActivityEvent` | `user, event_key, type, source_id, occurred_at, day_key, xp_delta, reason, counts_as_study, policy_version`; thêm fingerprint/receipt nhỏ khi cần cho retry nộp bài |
| `StreakDay` | `user, day_key, status, origin, direct_xp, review_count, correct_self_reports, wrong_self_reports` |
| `UserStreak` | Tóm tắt `current_streak, longest_streak, last_activity_day, total_xp, level, total_active_days, legacy_day_count, tracking_started_day, revision, policy_version`; không chứa lịch sử tăng theo thời gian |

Index bắt buộc: unique `ActivityEvent(user,event_key)`, index lịch sử
`(user,occurred_at,_id)`, unique `StreakDay(user,day_key)`, unique `UserStreak(user)`.
Không đặt TTL cho khóa sự kiện đang bảo vệ việc không phát thưởng lại.

Collection có thể tăng theo hoạt động; điều được loại bỏ là tăng không giới hạn trong
**một document** và GET tóm tắt. Không hứa một collection lịch sử tự nhiên có chặn trên.

`StreakDay.status`: `studied`, `frozen`, hoặc `legacy` cho ngày cũ không chứng minh được
có học. Ngày nghỉ suy từ ngày đã kết thúc không có record, sau thời điểm bắt đầu theo dõi.
Không diễn giải ngày tương lai hoặc thời gian trước tracking là nghỉ.

`tracking_started_day` là ngày bắt đầu áp dụng luật mới với user legacy, hoặc ngày học
đầu tiên với user mới. Các record legacy trước đó vẫn đọc/xuất được; khoảng trống trước
tracking không chứng minh nghỉ học. `total_active_days` chỉ đếm ngày `studied` theo luật mới.
Nếu ngày legacy trùng ngày có hoạt động mới, chuyển thành studied, giữ dấu nguồn legacy,
tăng total_active_days và giảm legacy_day_count đúng một lần; không tăng lại độ dài chuỗi
đã tính ngày đó ở baseline. Không lấy số record lịch thay cho số ngày học đã xác minh.

### 3.3 Định danh và chống trùng

Không giữ hai cơ chế “một lần dùng reward_keys, lặp lại không khóa”. Mọi event được chấp
nhận có định danh ổn định; khóa ở collection, không đẩy vào UserStreak.

| Nguồn | Định danh và quy tắc |
| --- | --- |
| SRS | Ghép `SRSProgress._id` và `expected_next_review` của lượt vừa thắng CAS; ID thẻ một mình không đủ định danh lượt ôn |
| Mục/bài học | Giữ ngữ nghĩa khóa hiện có `lesson-item:<lesson>:<type>:<item>`, `lesson-complete:<lesson>`; reset không tạo quyền thưởng lại |
| Exercise/JLPT | `attempt_id` UUID được giữ nguyên cho cùng lần nộp/retry, scope theo user + loại; một lần làm mới có UUID mới |
| Huy hiệu/thưởng mốc | Khóa theo user + loại thưởng + mốc/achievement, chỉ cấp một lần, không tính ngày học |
| Dữ liệu legacy | Dòng XP dùng khóa theo nguồn snapshot; khóa quyền thưởng giữ định danh nghiệp vụ cũ để chặn phát lại; lưu phiên bản migration riêng |

Với bài tập/JLPT, client tạo `attempt_id` khi bắt đầu lượt làm và gửi lại đúng ID khi retry.
Server kiểm schema, quyền, bài làm và fingerprint nội dung đã chuẩn hóa. Cùng ID/cùng
payload trả kết quả đã ghi; cùng ID/payload khác trả 409. Kiểm receipt **trước khi** tạo/
cập nhật kết quả, rồi commit receipt và kết quả cùng transaction.

Exercise có thể đọc lại response từ ExerciseResult bất biến. JLPT hiện ghi đè một history
theo user/exam: giữ response điểm của từng lần nộp trong receipt nhỏ ở ActivityEvent, để
retry lần A không nhận kết quả lần B. Không dùng `LearningHistory._id` làm khóa lần nộp.
Việc xây đầy đủ lịch sử mọi bài thi là phạm vi khác; không cần đổi unique index history
chỉ để làm streak. Bổ sung `attempt_id` vào Flutter và test HTTP cùng commit.

Không có event mới khi chỉ gọi lại thao tác mục/bài đã được ghi nhận. Muốn luyện lại dùng
SRS/bài tập; xóa rồi tạo lại progress không xóa khóa đã nhận thưởng.
Chống retry không đồng nghĩa chống mọi kiểu cố tình làm nhanh; giới hạn thưởng rộng hơn
cần policy riêng, không giả vờ UUID chứng minh người dùng đã học đủ thời gian.

### 3.4 XP và huy hiệu

Một `streak-policy.js` tại server quyết định XP từ **kết quả đã chấm**, không từ amount
hoặc isPassed do client tự khai:

| Event | XP trực tiếp |
| --- | --- |
| SRS đến hạn đúng hoặc sai | 2 |
| Mục bài học mới được hoàn thành | 2 |
| Hoàn thành bài học lần đầu | 20 |
| Bài tập đã nộp hợp lệ | 10 nếu server chấm đạt, 5 nếu chưa đạt |
| JLPT đã nộp hợp lệ | 20 |
| Login/mở bài/đánh dấu từ độc lập/reset/xóa/bỏ qua | 0, không tạo event học |

Bỏ thưởng mở bài 3 XP và login 10 XP từ cutover; không trừ XP đã có.
Một hành động hoàn thành mục cuối có thể sinh cả event mục và event hoàn thành bài;
hai khóa riêng, ngày học vẫn chỉ tính một ngày.

Dùng thang huy hiệu streak `[7,14,30,50,100,365]`, bỏ bonus ngày và `%7`/`%30`.
XP của huy hiệu lấy từ cấu hình Achievement tại server, qua cùng policy/cơ chế chống lặp;
không đồng thời cộng thêm một bonus mốc khác. Fixture phải có định nghĩa huy hiệu cần demo.

Event thưởng có `counts_as_study=false`, không tăng XP mục tiêu ngày, không gọi lại
recordActivity và không tạo vòng lặp phát thưởng. Mốc XP được đánh giá trên snapshot trước
bonus; không tự lặp đệ quy vì XP vừa thưởng. Ngày học/cấp huy hiệu/XP cùng transaction.
Các huy hiệu khác chưa có tiêu chí server xác minh thì chưa tự cấp, không nhận progress từ client.

### 3.5 Ngày và cạnh tranh cùng ngày

`dayKey(now)` dùng `Intl.DateTimeFormat` với timezone `Asia/Ho_Chi_Minh`, calendar
Gregorian, chữ số Latin, year/month/day rõ ràng; lấy `formatToParts()` rồi ghép
`YYYY-MM-DD`. Không dựa vào `format('en-CA')` luôn trả một dấu phân cách/thứ tự cố định.
Kiểm ngày hợp lệ, tính khoảng cách bằng thành phần ngày UTC; không parse chuỗi giờ locale.

Dùng `revision` tăng mỗi lần ghi tóm tắt, cùng transaction/unique event. Chỉ CAS trên
`last_activity_day` là **chưa đủ**: hai event khác nhau cùng ngày có cùng khóa ngày nhưng
cả hai đều phải cộng XP; không được làm mất một event khi ghi đè balance cũ.

Request thua cạnh tranh đọc lại/retry với trạng thái mới. Event đã tồn tại là no-op; event
khác chưa ghi phải được xử lý đủ. Khởi tạo UserStreak khi thiếu cũng theo unique user và retry.
GET/login trả projection; không tạo event, không ghi ngày, không tiêu băng, không cấp thưởng.

### 3.6 Đóng đường tự cấp thưởng

Bỏ đúng ba route trong **module streaks**:
`POST /add-xp`, `POST /test/reset-yesterday`, `GET /test/debug`.
Xóa `StreakService.addXP`/`StreakProvider.addXP` không có consumer màn hình trong checkout.

Bỏ thêm `POST /api/achievement/update-progress`: nó nhận progress client và có thể cấp XP,
nên giữ lại sẽ làm hỏng mục tiêu integrity. Xóa hàm service/provider tương ứng sau đối chiếu
consumer; các đường đọc và CRUD admin Achievement giữ nguyên.
Như vậy Phần A bỏ **4 route toàn ứng dụng**, không phải 3; riêng module streak bỏ 3.
Route contract phải tính cả thay đổi này và 12 → 6 route SRS, không dùng grep toàn repo
“không còn addXP” vì helper nội bộ/test hồi quy vẫn có thể nhắc tên cũ.

## 4. Migration và contract đọc — bắt buộc trong Phần A

### 4.1 Audit và chuyển dữ liệu

**Chưa audit Atlas, chưa chạy migration.** Có thể viết hàm/test với fixture trước; audit
phải hoàn tất trước migration hoặc chạy bản mới trên dữ liệu thật.

1. Audit SRS theo spec SRS; audit UserStreak: kiểu ngày, số XP, các mảng, reward_keys,
   trùng user; UserAchievement; các trạng thái thưởng pending/granted của bài học.
2. Xác định timezone host từng giai đoạn đã ghi ngày legacy. Timestamp “nửa đêm host”
   không được đoán luôn là nửa đêm Việt Nam. Không xác định được thì báo nhóm cần xử lý.
3. Backup có kiểm tra khôi phục; dry-run và báo số lượng/số dư trước–sau trên DB kiểm thử.
4. Chọn `cutover_at` và dừng các writer cũ trong lúc chuyển. Không dual-write ngầm.
5. Copy xp_history thành event `legacy.xp`, giữ amount/reason/thời điểm; khóa theo
   `UserStreak._id + vị trí trong snapshot mảng` để không gộp nhầm hai khoản giống nhau.
   Copy reward_keys thành event đánh dấu đã nhận, XP 0, giữ đúng `event_key` mà writer
   mới sẽ kiểm; không thêm prefix legacy làm mất khả năng chặn phát lại. UserAchievement
   đã hoàn thành cũng cần khóa đánh dấu tương ứng, không cấp lại XP nếu thiếu lịch sử.
   Ghi phiên bản migration trong metadata; không gọi hàm cấp thưởng khi copy.
6. Copy activity_dates thành `StreakDay(status=legacy, origin=legacy_unverified)`;
   không gán thành học thật vì có thể chỉ là login. Giữ baseline current/longest/total_xp.
7. Đối chiếu: số lượng, khóa trùng, số dư giữ nguyên, quyền user, huy hiệu đã có. Chênh giữa
   tổng lịch sử XP và total_xp phải ghi báo cáo; không tự sửa total_xp theo phép cộng lịch sử.
8. Chỉ bỏ ba mảng legacy khi kiểm đạt và bản mới đã chuyển mọi writer/consumer. Migration
   chạy lại không tạo thêm event/XP. Ghi schema/policy version và kế hoạch rollback về backup.

Không hạ chuỗi đang còn hiệu lực chỉ vì các ngày cũ là login; cũng không phục hồi chuỗi
đã hết hiệu lực trước cutover. Ngày cũ đã được tính không cộng lần hai nếu hôm cutover có
hoạt động mới. Test riêng last-day=hôm nay, hôm qua và đã đứt trước cutover.
Tổng ngày học thật và retention mới chỉ tính event sau cutover, tách baseline chưa xác thực.

Đây là migration **dữ liệu tiến độ**, khác với nhập thêm nội dung Vocabulary.

### 4.2 Giữ đường đọc, chuyển consumer có chủ đích

| Endpoint | Contract và consumer |
| --- | --- |
| `GET /streak/my-streak` | Tóm tắt phẳng, giữ current/longest/total_xp/level/virtual hiện dùng; thêm `last_activity_day, total_active_days, legacy_day_count, studied_today`. Bỏ hai mảng khỏi response cùng lúc sửa model/provider/screen/export |
| `GET /streak/xp-history` không query | Giữ array đầy đủ và các field `amount, reason, earned_at`, đọc từ ActivityEvent có XP; đường tương thích cũ, không mặc định giới hạn 20/100 làm thiếu export |
| `GET /streak/xp-history?mode=page&limit=100&cursor=...` | Chế độ mới trả `{ data, next_cursor, as_of }`; default limit 20, max 100, sort `occurred_at DESC, _id DESC`; cursor có scope user/bộ lọc/mốc thời gian |
| `GET /streak/leaderboard` | Giữ path/envelope; `period=all` dùng total_xp, week/month cộng XP event trong kỳ; trả thêm `period_xp`, hạng và danh sách dùng cùng filter/sort |

`last_activity_date` có thể giữ như alias ISO để client cũ đọc, nhưng không còn là nguồn
tính ngày; UI mới dùng day_key, hiển thị legacy là chưa xác minh. User mới nhận summary 0
và last-day null mà không cần tạo document khi GET.

Flutter streak chỉ tải trang XP cần hiển thị. Export tải chế độ page đến
`next_cursor=null`, ghép thành array `xp_history` trong file như hiện tại, có hủy/lỗi;
lỗi trang giữa không báo xuất thành công một phần. Export còn các nhánh full_stats/streaks/
all_data cần kiểm; thêm ngày lịch bằng endpoint §4.3. Cùng commit sửa model,
`StreakService`, provider, screen và `export_screen.dart`.

`as_of` giới hạn event theo thời điểm, không hứa một snapshot DB tuyệt đối khi có ghi
đồng thời. Dùng cursor ổn định, tránh trùng dòng; test trên dữ liệu yên và nhiều trang.
Ngày/XP legacy vẫn xuất được và được đánh dấu nguồn, không mất lịch sử khi bỏ mảng.

Kỳ week/month lần lượt là 7/30 ngày lịch Việt Nam gồm hôm nay; sort điểm kỳ giảm rồi user ID
làm khóa phụ. Hạng dùng cùng quy tắc. Không đổi `total_xp` thành điểm kỳ dưới cùng tên;
UI phải dùng period_xp khi chọn kỳ. Phân trang/profile query không trả toàn bộ event cho trang chủ.

### 4.3 Đường đọc lịch được thêm từ Phần A

Thêm `GET /api/streak/days?from=YYYY-MM-DD&to=YYYY-MM-DD&cursor=...`:
`{ data: StreakDayDto[], next_cursor }`; khoảng tối đa 366 ngày, mỗi trang tối đa 100.
Auth theo user; validate ngày/from<=to. Có từ Phần A để xuất lịch sử sau khi bỏ activity_dates;
màn lịch Phần B dùng lại. Export chia dải năm nếu cần và đọc hết từng trang.

Do đó Phần A: module streaks **6 route cũ − 3 + 1 = 4 route**;
achievements giảm 1 route. Phần B bổ sung endpoint settings riêng, không ghi count chung
“chỉ bỏ ba route” cho toàn bộ thay đổi.

## 5. Phần B — mốc 1B

### 5.1 Mục tiêu ngày và lịch

XP mục tiêu ngày là tổng `direct_xp` từ hoạt động học đã xác thực trong StreakDay;
không gồm login, XP legacy, huy hiệu, freeze hoặc bonus. Mặc định 20; chọn 10/20/30/50.
Mục tiêu không chặn streak. SRS-only vẫn tăng mục tiêu vì mỗi lượt đã chốt 2 XP.

Đổi mức mục tiêu có hiệu lực từ ngày Việt Nam tiếp theo; không thay điều kiện giữa ngày.
Lịch phân biệt studied/frozen/nghỉ cho thời gian mới; ngày legacy có ký hiệu chưa xác minh,
ngày hôm nay chưa học là “chưa học hôm nay”, không phải đã nghỉ. Không tô tương lai là bỏ học.

Settings trong một model `StreakSettings` có unique user: goal, giá trị có hiệu lực,
reminder_enabled mặc định false, reminder_time mặc định 20:00 khi bật.
GET settings chỉ đọc, trả default nếu chưa có; PUT validate, ghi và tăng revision.
Ngày đóng băng có XP học 0 và không tăng số ngày đã học thật.

### 5.2 Freeze: luật ngày, projection và ghi

UserStreak thêm `freezes_available` 0..2 khi bật Phần B. Không hồi tố freeze cho khoảng nghỉ
trước khi tính năng có hiệu lực. Mỗi mốc 7/14/30/50/100/365 sau bật được tặng 1, một lần/user;
tặng sau xử lý ngày và gap, không dùng băng vừa kiếm hôm nay cứu khoảng nghỉ đã qua.
Nếu kho đầy, phần thưởng vượt trần không được lưu để lĩnh lại sau. Không bán băng.
Chỉ xét mốc vừa được vượt qua bằng hoạt động mới (`previous_current < m <= new_current`);
không dùng longest_streak để phát bù mốc cũ. Khóa quà freeze tách khỏi khóa huy hiệu XP,
nên huy hiệu đã nhận trước Phần B không tự cấp băng khi người dùng mở app.

`streak-rules.js` là hàm thuần nhận state, todayKey và policy; không tự đọc clock/DB.
Ngày băng giữ nguyên độ dài chuỗi; ngày học thành công mới tăng 1.
Một chuỗi có ngày được bảo vệ có thể trải qua nhiều ngày lịch hơn con số ngày học trong chuỗi.

| Tình huống khi có hoạt động thật hôm nay | Quyết định |
| --- | --- |
| Chưa có lịch sử | current=1, longest=max(baseline,1), ghi studied |
| Đã học hôm nay | Không tăng ngày; event học khác vẫn ghi và cộng XP đúng policy |
| Ngày học gần nhất là hôm qua | current+1 |
| Bỏ lỡ k ngày đã kết thúc | Đi từ ngày sớm nhất: dùng mỗi băng cho một ngày cho tới khi hết hoặc gặp ngày không được bảo vệ; đủ thì nối chuỗi +1, thiếu thì current=1 |
| Nghỉ 3 ngày, có 2 băng | Hai ngày đầu frozen, tiêu 2; ngày thứ ba nghỉ; hôm nay bắt đầu chuỗi 1 |
| Ngày gửi ngược về quá khứ | Client không chọn ngày; dữ liệu state ở tương lai phải báo lỗi kiểm dữ liệu, không tự trừ băng |

Khi không đủ băng vẫn tiêu số đã bảo vệ các ngày đầu; lựa chọn này được chốt rõ thay vì
để ngỏ giữ hay tiêu một phần. Sau ngày đầu tiên không được bảo vệ, chuỗi đã đứt; không tiêu
thêm băng cho phần còn lại của khoảng nghỉ đó. Không cần lặp qua hàng nghìn ngày vắng mặt.

GET dùng `projectStreak` trên các ngày **đã kết thúc**, không tính hôm nay là ngày bỏ lỡ và
không giả vờ hôm nay đã học. Trả current chiếu, ngày bảo vệ dự kiến, `pending_freezes`,
tồn kho đã ghi và số còn khả dụng sau dự kiến. Đọc không ghi/tiêu băng. Khi người dùng học
trở lại mới commit kết quả: các StreakDay frozen + inventory + studied hôm nay cùng transaction.
UI phân biệt frozen dự kiến với dữ liệu đã ghi; không hiện số tồn kho dự kiến như một lần cấp mới.

CAS phải gồm revision của summary; mọi thưởng/cấp/trừ băng đều tăng revision. Event thua
cạnh tranh không đồng nghĩa đã xử lý: retry event khác, no-op event trùng, không mất XP cùng ngày.
Freeze không đổi next_review, không giảm lượng thẻ đến hạn và không sửa UserAchievement cũ.

### 5.3 Nhắc học

Phần B có `GET/PUT /api/streak/settings`, sau auth/validation. Người dùng chủ động bật nhắc,
chọn giờ theo ngày Việt Nam; kiểm studied_today trước hiển thị. Bản đầu cho chọn trong
08:00–21:59, không nhắc trong 22:00–07:59. Định nghĩa “chưa học” theo event học, không theo
chưa đạt goal. Nếu mở app sau giờ đã chọn nhưng còn trong khung cho phép, nhắc một lần
sau khi đồng bộ trạng thái; không phát bù lời nhắc của ngày cũ.

Phạm vi bản đầu: nhắc trong ứng dụng khi đang mở bằng scheduler client từ settings;
lưu dấu đã nhắc theo user/ngày trên thiết bị để tránh nhắc lại khi reload. Chỉ cam kết tối
đa một lần/ngày trên mỗi thiết bị; chưa có cơ chế chống trùng thông báo trên nhiều thiết bị.
Mất mạng thì hoãn nhắc tới khi đọc lại trạng thái, không tự xác nhận đã học; nội dung nhắc
không khẳng định chắc chuỗi sẽ đứt.
Thông báo khi app đóng cần local notification mobile hoặc Web Push/service worker và
permission riêng, **chưa nằm trong nghiệm thu 1B**. Không hiển thị lời hứa “nhắc khi đóng app”
khi mới có Notification collection hoặc timer. Đồng bộ trạng thái hoàn thành trước khi nhắc.

## 6. Đo lường và giới hạn

Phần A ghi đủ sự kiện để kiểm: ngày có học, số lượt SRS đã commit, đúng/sai tự báo, XP theo
nguồn; Phần B thêm số ngày được bảo vệ. Có test tạo fixture và truy vấn ra số đo kỳ vọng.

Không hứa đã đo D7/D30 khi chưa có người dùng. Không thể tính mẫu số “tổng thẻ đến hạn đầu
ngày” từ next_review hiện tại sau khi lịch đã bị thay đổi. Chỉ số hoàn thành ôn theo ngày
cần snapshot riêng tại thời điểm định nghĩa; **chưa là tiêu chí đo của mốc này**.
Đồ án báo số lượt hoàn tất, số đến hạn tại thời điểm đọc và ghi rõ chúng đo hai thời điểm khác nhau.

SRS dùng tự đánh giá: số đúng/sai không chứng minh trí nhớ. Legacy login không đưa vào cohort
học thật. Mốc kiến thức cần bài kiểm tra đáp án độc lập, ngoài spec.

## 7. Kiểm thử và tiêu chí hoàn thành

| Nhóm | Case phải chặn trước nghiệm thu |
| --- | --- |
| Rules/dayKey | Lần đầu, cùng ngày, ngày kế, gap lớn, tháng/năm nhuận; 23:59/00:01 VN trên host UTC/UTC+7; state ngày tương lai |
| Idempotency | Cùng request nộp chỉ một kết quả/event/XP; cùng ID khác payload 409; hai attempt mới cùng bài đều được ghi; JLPT retry A sau B trả receipt A |
| SRS | Retry/hai tab một lịch chỉ một event + 2 XP; hai thẻ khác nhau cùng ngày đều cộng, streak chỉ tăng ngày một lần |
| Transaction | Lỗi event/XP/huy hiệu rollback kết quả nguồn; retry không phát thưởng hai lần; tạo UserStreak đồng thời |
| Quyền | Login/GET không ghi; add-xp/test/update-progress client không tồn tại; ownership và amount do server |
| Migration | Chạy lại không trùng; giữ số dư/khóa đã thưởng; pending/granted lesson; ngày legacy; cutover hôm nay/hôm qua/đã đứt; khôi phục backup thử |
| API/export | Legacy xp-history array; mode page nhiều trang; my-streak không mảng lớn; xuất đủ XP/ngày và không thành công khi lỗi giữa chừng; leaderboard kỳ/hạng đồng nhất |
| Freeze | 1/2/3 ngày nghỉ; không đủ vẫn tiêu phần đã bảo vệ; thiếu băng không xóa longest; hai event cùng ngày; thưởng khi đầy; không hồi tố; GET không ghi |
| Flutter | Xóa hàm chết; model/summary mới; lỗi giữ dữ liệu; goal ngày kế; lịch pending/legacy; nhắc opt-in; không hứa background notification |
| Regression | Route count theo toàn app; export_screen các nhánh; login response; bài học/bài tập/JLPT và SRS |

Mỗi phần chạy backend test, Flutter analyze/test/build và các test UI/điều hướng bị ảnh hưởng.
Unit/HTTP test dùng adapter giả; transaction và unique index phải có smoke test trên DB kiểm
thử riêng, không dùng Atlas dữ liệu người dùng làm fixture.
Không coi việc grep sạch tên method là bằng chứng không còn đường cấp XP sai.

## 8. Thứ tự triển khai và quyết định đã chốt

Thứ tự chi tiết nằm trong [spec chương trình §4.0](2026-09-09-learning-loop-program-design.md#40-thứ-tự-bắt-đầu-và-dữ-liệu-từ-vựng).
Phần A và SRS nghiệm thu cùng mốc 1; 1B triển khai sau mốc 1 và có thể hoãn sau mốc 3.

Đã chốt: không chấm lại chuỗi cũ; SRS 2 XP/lượt; goal 20 với mức 10/20/30/50; kho freeze
0..2, thưởng 1 tại các mốc đã nêu, không hồi tố; vacation/repair/bạn bè/background reminder ngoài phạm vi.
Còn cần dữ kiện trước cutover: audit DB, timezone legacy, trạng thái thưởng cũ và backup.
Không cần đợi đủ nội dung N5 để bắt đầu viết code với fixture.
