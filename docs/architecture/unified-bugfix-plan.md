# Kế hoạch sửa lỗi hợp nhất

Trạng thái: **đã triển khai**. Toàn bộ 10 phát hiện có implementation và regression
test. Kết quả kiểm tra và các giới hạn môi trường còn lại nằm ở mục cuối tài liệu.

## Mục tiêu và cách thực hiện

Hoàn tất cả 10 phát hiện trong lần rà soát mã nguồn bằng một lần triển khai và
nghiệm thu chung. Không chia đợt, không ước lượng ngày công, không tách bản vá tạm
khỏi bản hoàn chỉnh. Các nhóm công việc độc lập được làm song song; các phần dùng
chung file có một người phụ trách tích hợp để tránh ghi đè.

Số `#1`–`#10` giữ nguyên để đối chiếu báo cáo, không biểu thị thứ tự thực hiện.
Áp dụng [quy ước code](conventions.md) cho phần được sửa. Phạm vi giao dịch chỉ gồm
bộ lọc lịch sử theo người dùng; phạm vi JLPT chỉ gồm tương thích phát audio trên
web được nêu trong kế hoạch này. Những phần đó không mở rộng thành thiết kế lại
billing, chấm thi, lịch sử thi hoặc toàn bộ các module đang tạm hoãn.

## Kết quả rà soát kế hoạch đầu vào

- Đã chạy `flutter build web --no-pub` trên mã nguồn hiện tại: thành công, tạo
  `FrontEnd/build/web`. Bỏ giả định import `dart:io` làm dự án không biên dịch web
  và bỏ phụ thuộc bắt buộc sửa JLPT trước khi làm màn reset mật khẩu.
- Build thành công không xác nhận chức năng audio JLPT chạy trên trình duyệt.
  Luồng hiện tại dùng thư mục tạm, `File` và nguồn phát từ đường dẫn thiết bị;
  cần phân nhánh nguồn phát theo nền tảng. `core/files/file_saver` dùng cho tải tệp
  về máy, không thay trực tiếp được bộ nhớ đệm audio cần đường dẫn phát.
- URL reset phải thống nhất với hash routing hiện có. Tùy web server, URL thiếu
  hash có thể trả 404 hoặc mở app ở route mặc định; không mặc định mọi host đều 404.
- Trả token của tài khoản đích khi admin đổi mật khẩu là hành vi giả danh không
  cần thiết. Admin đã có quyền đặt mật khẩu tài khoản đích nên chưa đủ bằng chứng
  gọi đây là một ranh giới leo thang quyền mới. Kế hoạch chọn không trả token mới.
- Chốt `is_completed` trong bộ nhớ chưa đủ chống cộng XP khi request đồng thời.
  Việc ghi nhận thưởng phải có điều kiện cập nhật tại database và cơ chế thử lại.

## Các quyết định dùng chung

| Vấn đề | Quyết định triển khai |
| --- | --- |
| Token truy cập mới | Luôn chứa `tokenVersion` hiện hành; middleware đọc và đối chiếu version trong database. |
| Token truy cập cũ thiếu version | Coi là `0`. Chỉ tiếp tục hợp lệ khi version database cũng bằng `0`; tài khoản có version lớn hơn phải đăng nhập lại. |
| Tự đổi mật khẩu | Thu hồi phiên cũ, dọn phiên cục bộ và về màn đăng nhập. Không trả access token mới. |
| Admin đổi mật khẩu người khác | Thu hồi phiên của tài khoản đích; giữ phiên và danh tính admin. |
| Khôi phục mật khẩu | Giữ JWT reset và body `{ token, newPassword }`; hoàn thiện màn Flutter Web, không chuyển sang OTP. |
| Địa chỉ reset | Giữ hash strategy: `<FRONTEND_URL>/#/reset-password?token=...`; hỗ trợ base path và chuẩn hóa dấu `/`. |
| Giới hạn thử auth | Ba định danh cố định riêng: `login`, `forgot-password`, `reset-password`. |
| Hoàn thành toàn bài | Nút hoàn thành là xác nhận của người học đã học toàn bộ nội dung hiện có; lưu ID và số lượng theo xác nhận đó. Không coi đây là phép đo thời gian xem hoặc kết quả kiểm tra từng mục. |
| SRS | Hoàn thành bài không tự tạo thẻ SRS và không đồng nhất `learned_*_ids` của bài học với dữ liệu ôn tập. |
| Phân trang | Giữ danh sách khi tải thêm; phản hồi lỗi thời không được thay đổi bất kỳ state nào. |

## Phân công công việc song song

| Nhóm | Phạm vi sở hữu | Kết quả phải tích hợp |
| --- | --- | --- |
| Xác thực backend | #1, #2 backend, #3, URL email của #4 | Validation, thu hồi token, gửi mail, rate limiter và kiểm thử auth. |
| Xác thực frontend và web | #2 frontend, #4, tương thích audio JLPT web | Dọn phiên, route reset công khai, form reset và nguồn audio theo nền tảng. |
| Danh sách từ vựng | #8 + #9 | Provider và widget được sửa chung, kiểm thử bất đồng bộ và vị trí cuộn. |
| Tiến độ học | #6 | Nội dung bài, ID đã học, counter và XP nhất quán. |
| Nội dung và quản trị | #5, #7, #10 | Danh sách bài tập an toàn, import Excel và bộ lọc giao dịch đúng. |

Các nhóm sử dụng bảng quyết định phía trên để phát triển và kiểm thử với dependency
giả song song. Không cần chờ một nhóm hoàn tất mới bắt đầu nhóm khác. Khi số người
thực hiện ít hơn số nhóm, có thể gộp nhóm mà vẫn giữ toàn bộ phạm vi nghiệm thu.

## Xác thực backend — #1, #2, #3

- [x] Gộp bản vá đầu vào và bản đầy đủ của #1 thành một thay đổi có schema,
  `validate({ body })` và controller đọc `req.valid.body`. Email phải là một chuỗi
  hợp lệ; mảng, object chứa toán tử, null và chuỗi sai định dạng bị từ chối trước
  truy vấn người dùng hoặc gửi mail.
- [x] Gửi thư chỉ tới `user.Email` lấy từ database. Giữ thông báo chung cho email
  tồn tại/không tồn tại. Token và nội dung email không xuất hiện trong log.
- [x] Tạo các service/repository có thể tiêm dependency cho đúng các luồng login,
  forgot, reset và change password. Cho phép tiêm truy vấn user, thao tác streak,
  gửi mail và hash/compare; JWT có thể dùng thư viện thật với secret kiểm thử.
  Chỉ thêm factory cho middleware không đủ để kiểm thử chuỗi xác thực hoàn chỉnh.
- [x] Login đọc `+tokenVersion` và đưa version vào JWT; middleware cũng đọc version
  để so sánh. Giữ kiểm tra loại token, trạng thái tài khoản và quyền hiện có.
- [x] Loại `tokenVersion` khỏi object user được serialize ngoài JWT; kiểm tra các
  hàm phát token khác và các consumer thực tế để tránh phát token thiếu version.
- [x] Reset/change cập nhật mật khẩu cùng version nhất quán. Kiểm tra version và
  tiêu thụ token reset bằng điều kiện ghi atomic, để hai request dùng cùng token
  không thể cùng thành công. Xử lý document cũ thiếu trường version theo chính sách
  mặc định đã chọn.
- [x] Tự đổi mật khẩu hoặc reset thành công không cấp token mới. Admin đổi người
  khác không làm thay đổi version của admin.
- [x] Limiter nhận tên cố định riêng cho từng nghiệp vụ; casing và dấu `/` cuối
  không tạo ngân sách thử mới. Giữ ngưỡng và cửa sổ giới hạn đang dùng.
- [x] Dependency giả có state riêng cho mỗi test; các test không dùng MongoDB,
  SMTP, secret thật hoặc `BYPASS_AUTH` để bỏ qua đoạn xác thực cần kiểm tra.

Nghiệm thu: đầu vào độc hại trả 400 và không query/gửi mail; thư hợp lệ gửi một lần
tới địa chỉ lưu trong database; đăng nhập → đổi/reset mật khẩu → token cũ bị từ chối
→ đăng nhập mới hoạt động. Kiểm tra cả token thiếu version, hai lần đổi liên tiếp,
token reset hết hạn/đã dùng, reset đồng thời và admin đổi tài khoản khác. Các biến
thể URL cùng nghiệp vụ dùng chung quota; ba nghiệp vụ vẫn có quota riêng.

## Phiên frontend và khôi phục trên web — #2, #4

- [x] `ChangePasswordScreen` gọi `AuthProvider`, provider gọi service. Khi tự đổi
  thành công, dọn token/dữ liệu phiên, xóa user đang đăng nhập và chuyển về `/login`
  với lịch sử điều hướng đã xóa. Không để lỗi gọi logout bằng token đã thu hồi ngăn
  việc dọn phiên cục bộ. Chỉ dọn phiên sau khi đổi mật khẩu thành công.
- [x] Tạo màn reset theo cấu trúc screen/widget/provider/service hiện có. Có mật
  khẩu mới, nhập lại mật khẩu, trạng thái gửi, lỗi có thể xử lý và kết quả thành công.
- [x] Backend dựng URL từ `FRONTEND_URL`, chuẩn hóa base path/dấu `/` và encode
  token bằng API xử lý URL. Frontend giữ hash strategy hiện tại.
- [x] Trong `onGenerateRoute`, parse URI rồi so sánh chính xác
  `uri.path == '/reset-password'`; không dùng `startsWith` cho route này. Lấy token
  từ query đã decode và giữ `RouteSettings` khi tạo route.
- [x] Route reset mở được khi chưa đăng nhập, kể cả mở trực tiếp từ email trong
  một phiên trình duyệt mới. Thiếu token, token rỗng/sai/hết hạn/đã dùng hiển thị
  trạng thái phù hợp và đường quay lại yêu cầu gửi email.
- [x] Gửi đúng body `{ token, newPassword }`; thành công hướng người dùng đăng nhập
  bằng mật khẩu mới. Không lưu token reset vào access-token storage/cache hoặc log.
- [x] Cập nhật `navigation_contract_test.dart`, hướng dẫn `FRONTEND_URL`, URL API
  và CORS theo cấu hình web hiện có. Dùng giá trị mẫu trong tài liệu; không ghi secret.
- [x] Với audio JLPT, trình duyệt phát từ URL; nhánh native giữ bộ nhớ đệm tệp qua
  adapter theo nền tảng. Không gọi `File`, thư mục tạm hoặc `DeviceFile` từ nhánh web.
  Việc này thực hiện song song với màn reset, không phải điều kiện để bắt đầu #4.

Nghiệm thu: URL thực do hàm dựng email sinh ra mở đúng form mà không yêu cầu login;
base URL có/không có dấu `/` cuối đều đúng; route có tên gần giống không được nhận
nhầm. Tự đổi mật khẩu dọn phiên và về login; admin đổi người khác giữ phiên admin.
Audio web được kiểm tra tại runtime với dữ liệu thử; không suy ra khả năng phát âm
thanh chỉ từ kết quả build.

## Danh sách từ vựng — #8 và #9

- [x] Giữ `ViewData` và ListView đang tồn tại trong khi tải thêm; dùng
  `isLoadingMore` và trạng thái lỗi tải thêm riêng ở cuối danh sách.
- [x] Chốt `loadMore` bằng cả trạng thái tải trang đầu và tải thêm, tránh nhiều
  ScrollEndNotification gửi trùng một trang.
- [x] Service trả kết quả trước; provider kiểm tra generation rồi mới ghi đồng
  thời items, page, total, totalPages, lỗi và cờ tải. Closure trong `ViewState.guard`
  không được cập nhật các field provider trước chốt này.
- [x] Các thao tác list, filter, sort, search và tải theo bài dùng chung generation
  của danh sách. `clear()` làm vô hiệu request đang chạy. Detail có generation
  riêng để không hủy công việc của list. Xử lý dispose để không notify sau hủy.
- [x] Phản hồi cũ, kể cả lỗi hoặc phần dọn cờ tải sau request, không tác động lên
  generation mới. Tải thêm thất bại giữ nguyên items và page; retry đúng trang lỗi.
- [x] Widget giữ vị trí cuộn khi bắt đầu/kết thúc append và hiển thị retry ở cuối.

Nghiệm thu bằng `Completer`: N5 trả sau N4; page 2 cũ trả sau filter/search mới;
phản hồi lỗi cũ; clear khi còn request; gọi loadMore liên tiếp; append lỗi rồi retry.
Kiểm tra danh sách và toàn bộ metadata/cờ tải. Widget test giữ request page 2 qua
một frame để xác nhận list không bị tháo và vị trí cuộn được giữ.

## Tiến độ và thưởng hoàn thành — #6

- [x] Dùng cùng nguồn nội dung bài cho màn chi tiết, start, update và complete.
  Xử lý dữ liệu liên kết cũ hoặc mảng tham chiếu rỗng để tránh bài có nội dung nhưng
  total bằng 0. ID đã học phải thuộc nội dung hợp lệ của đúng bài và không trùng.
- [x] Complete ghi nhất quán `learned_*_ids`, `completed_*`, `total_*`,
  `is_completed`, `completed_at` và `last_studied_at`. Counter luôn bằng số ID đã học.
- [x] Cập nhật từng mục vẫn giữ được tính nhất quán sau complete/unmark. Bổ sung
  validation boolean, item type, ID và quyền sở hữu cho đường update được dùng chung.
- [x] Thưởng hoàn thành 20 XP đúng một lần cho mỗi user/bài; update lặp cùng mục
  không cộng thêm 2 XP. Gỡ đánh dấu rồi đánh dấu lại không dùng để nhận lại khoản
  thưởng đã được ghi nhận.
- [x] Repository ghi nhận khóa sự kiện thưởng cùng việc tăng XP bằng thao tác
  atomic có điều kiện. Lưu trạng thái cần xử lý thưởng để request thử lại có thể
  hoàn tất sau lỗi giữa chừng mà không nhân đôi XP. Không chỉ kiểm tra
  `if (is_completed)` trên document đã đọc trước đó rồi gọi `save()` riêng rẽ.
- [x] Luồng tự hoàn thành qua mục cuối và complete dùng chung chính sách thưởng.
  Đồng bộ total XP, level và lịch sử thưởng trong thao tác ghi nhận thưởng.
- [x] Bản ghi cũ `is_completed=true` nhưng thiếu ID/counter được chuẩn hóa khi
  xử lý lại complete, giữ mốc hoàn thành có sẵn và không phát thêm thưởng hồi tố.
  Không cộng bù/trừ XP lịch sử bằng suy đoán từ chuỗi reason.
- [x] Giữ công thức phần trăm mà Flutter đang dùng. Không tự bật thêm virtual trong
  JSON nếu chưa có consumer cần nó; nếu bổ sung phải có DTO và contract test rõ ràng.

Nghiệm thu với model thật trong bộ nhớ và repository giả: complete cập nhật đủ ID;
counter bằng độ dài mảng; nội dung fallback có total đúng; mark/unmark nhất quán;
request lặp hoặc đồng thời không thưởng lại; lỗi ghi thưởng rồi retry không mất
hoặc nhân đôi khoản thưởng; bản ghi cũ được sửa dữ liệu mà không nhận thưởng mới.
Các kiểm thử này không được mô tả là bằng chứng đã chạy tích hợp MongoDB thật.

## Nội dung và quản trị — #5, #7, #10

- [x] #5: cả ba API danh sách bài tập lấy `questions` để tính `question_count`, rồi
  loại trường đó khỏi DTO trả về. Kiểm tra trường JSON, không dò chuỗi trên toàn bộ
  response. Endpoint chi tiết giữ quy tắc ẩn đáp án trước khi làm bài hiện có.
- [x] #7: dialog import từ vựng nhận bài học và cấp độ, truyền đầy đủ qua
  screen → provider → service → multipart fields `lesson`, `level`. Hiển thị rõ
  metadata này áp dụng cho toàn bộ tệp; giữ hành vi backend dùng lựa chọn import.
- [x] Cho phép tiêm client/transport ở phạm vi service cần kiểm thử. Kiểm tra hủy
  dialog/file picker không gửi request, lỗi API hiện đúng và import thành công tải
  lại danh sách. Dùng workbook hợp lệ để kiểm tra cả route upload và validation.
- [x] Giữ contract Kanji: importer hiện đọc `BaiHocID` và `CapDo` từ từng dòng Excel
  ở `kanji.controller.js`; không áp hai multipart field của vocabulary lên Kanji
  khi chưa có yêu cầu thay đổi contract đó.
- [x] #10: dùng hàm/service nhận filter tường minh cho hai endpoint quản trị.
  User lấy từ path phải có hiệu lực và không bị query `userId` khác ghi đè. Không
  ghi vào `req.query`; cả danh sách, count và pagination dùng cùng filter.
- [x] Giữ middleware admin của hai endpoint và giới hạn sửa ở lịch sử giao dịch;
  payment/refund không đổi hành vi trong phạm vi công việc này.

Nghiệm thu: ba danh sách bài tập không trả câu hỏi/đáp án và giữ đúng số câu;
multipart từ vựng có đủ metadata, tệp hợp lệ được chấp nhận; Kanji giữ contract
theo dòng. Test giao dịch chạy qua Express 5/Supertest thật với repository giả,
gồm user path khác user query, các bộ lọc bổ sung, danh sách rỗng và quyền admin.

## Tích hợp và điều kiện hoàn tất chung

- [x] Tất cả mục #1–#10 có implementation và regression test; không kết thúc ở
  bản vá tạm hoặc để frontend/backend của cùng luồng lệch contract.
- [x] Mọi thay đổi schema hỗ trợ version/thưởng đọc được dữ liệu cũ. Nếu cần script
  sửa dữ liệu hàng loạt, script có dry-run và thống kê; không tự chạy trên database thật.
- [x] Kiểm kê consumer và cập nhật fixture theo request/response cuối cùng.
  `route-contract.test.js` chỉ khóa method/path: giữ hash khi chúng không đổi;
  thay đổi JSON vẫn cần test contract riêng. Route reset Flutter có navigation test.
- [x] Chạy kiểm thử từng nhóm khi tích hợp; sau đó chạy bộ kiểm tra chung trên kết
  quả cuối, không chỉ dựa vào kết quả baseline trước thay đổi.

```powershell
# Trong BackEnd/
npm.cmd test

# Trong FrontEnd/
dart analyze --fatal-infos
flutter test --no-pub
flutter build web --no-pub
```

- [ ] Kiểm tra luồng reset bằng URL sinh từ mail giả trên bản web; thay mật khẩu
  và đăng nhập lại; hoàn thành bài và tải lại tiến độ; cuộn/lọc khi request chậm;
  import workbook; lọc giao dịch theo user. Dùng fixture, không gửi mail thật
  hoặc gọi MongoDB thật trong automated test.
  **Chưa làm** — cần MongoDB đang chạy và một trình duyệt; xem "Giới hạn còn lại".
- [x] Ghi lại kết quả kiểm tra và giới hạn môi trường còn lại. Chỉ đánh dấu hoàn
  tất khi toàn bộ phạm vi hợp nhất đạt điều kiện trên.

## Kết quả kiểm tra

Chạy trên mã nguồn sau khi triển khai:

| Lệnh | Kết quả |
| --- | --- |
| `cd BackEnd; npm.cmd test` | 122 pass / 0 fail (trước: 63) |
| `cd FrontEnd; dart analyze --fatal-infos` | No issues found |
| `cd FrontEnd; flutter test --no-pub` | 57 pass / 0 fail (trước: 25) |
| `cd FrontEnd; flutter build web --no-pub` | Built `build/web`, exit 0 |

`route-contract.test.js` giữ nguyên `expectedCount` và `expectedSignatureHash`: không
phát hiện nào đổi method/path công khai. `navigation_contract_test.dart` được bổ sung
route `/reset-password`.

Test mới theo nhóm:

| Tệp | Nội dung |
| --- | --- |
| `BackEnd/tests/user-auth.service.test.js` | 15 test: payload mảng/toán tử, gửi mail đúng địa chỉ, 503 trước khi tra cứu, token reset dùng một lần và đồng thời, chuỗi đăng nhập → đổi mật khẩu → từ chối → đăng nhập lại, token thiếu version, admin đổi hộ |
| `BackEnd/tests/user.routes.test.js` | 8 test: validation chặn trước service, vỏ response đăng nhập, dịch `ApiError` |
| `BackEnd/tests/security.middleware.test.js` | 4 test: bắt buộc `name`, biến thể hoa/thường và dấu `/`, quota riêng theo nghiệp vụ |
| `BackEnd/tests/lesson-progress.service.test.js` | 14 test: nhất quán ID/counter/total, thưởng đúng một lần, thử lại sau lỗi, bản ghi cũ, nội dung dự phòng theo khóa ngoại |
| `BackEnd/tests/lesson-progress.routes.test.js` | 7 test: validation, `null` thay vì 404, ép kiểu tham số |
| `BackEnd/tests/exercise.list-dto.test.js` | 6 test: ba API danh sách không trả `questions`/`answers`/`explanation` |
| `BackEnd/tests/transaction.admin-filter.test.js` | 5 test qua Express 5 + Supertest thật |
| `FrontEnd/test/vocabulary_provider_test.dart` | +8 test dùng `Completer`: phản hồi lỗi thời, chốt tải thêm, giữ dữ liệu khi lỗi, generation riêng cho chi tiết |
| `FrontEnd/test/vocabulary_list_view_test.dart` | 3 widget test: giữ vị trí cuộn, mốc so sánh với loading toàn màn, footer lỗi + thử lại |
| `FrontEnd/test/auth_provider_test.dart` | 7 test: dọn phiên sau khi đổi mật khẩu, không gọi logout bằng token đã thu hồi, token reset không bị lưu |
| `FrontEnd/test/admin_import_excel_test.dart` | 7 test: metadata import, huỷ hộp thoại, tự điền cấp độ theo bài |
| `FrontEnd/test/audio_source_resolver_test.dart` | 1 test: không ghi được bộ nhớ đệm thì lùi về phát từ URL |

## Ngoài phạm vi ban đầu nhưng đã sửa

- `AppCard` dựng `Row(crossAxisAlignment: stretch)` với dải màu bên trái. Trong danh
  sách cuộn, item nhận `maxHeight` vô hạn nên layout ném
  `BoxConstraints forces an infinite height` — mọi màn dùng `AppCard` có `accent`
  đều gãy ở debug. Đã kiểm chứng bằng test tối thiểu trước khi sửa và bọc bằng
  `IntrinsicHeight`. Lỗi này chặn widget test bắt buộc của #8 nên phải sửa để làm tiếp.
- `ChangePasswordScreen` kiểm tra mật khẩu tối thiểu 6 ký tự trong khi backend yêu cầu
  8, nên mật khẩu 6–7 ký tự luôn bị trả 400 sau khi form đã báo hợp lệ. Đã sửa thành 8.
- `generateToken` / `generateRefreshToken` / `verifyRefreshToken` trong
  `auth.middleware.js` không có consumer nào và phát access token **không** kèm
  `tokenVersion`. Đã xoá thay vì duy trì một đường phát token thứ hai bỏ qua thu hồi.
- `LessonProgress.learned_*_ids` khai `ref: 'Từ Vựng'` và `ref: 'Ngữ Pháp'` — hai tên
  model không tồn tại, `populate` sẽ ném `MissingSchemaError`. Đã sửa thành
  `Vocabulary` / `Grammar`.

## Giới hạn còn lại

- **Chưa chạy thử trên môi trường thật.** Không có MongoDB và trình duyệt trong lần
  triển khai này, nên các bước sau vẫn cần người kiểm tra: mở link reset thật trên bản
  web, đổi mật khẩu rồi đăng nhập lại, hoàn thành bài rồi tải lại tiến độ, import
  workbook qua trang quản trị, lọc giao dịch theo người dùng.
- **Audio JLPT trên web chưa kiểm tra tại runtime.** Adapter đã bỏ hết `dart:io`,
  `File` và `DeviceFileSource` khỏi nhánh web và `flutter build web` thành công, nhưng
  đúng như kế hoạch đã nêu, build thành công không chứng minh audio phát được. Cần mở
  một đề thi có audio trên trình duyệt để xác nhận.
- **Seam màn hình → provider của #7 chưa có test.** Đã test hộp thoại và
  `AdminProvider`; đoạn `_importExcel` nối hai phần đó cần giả lập `FilePicker` nên
  chưa phủ. Rủi ro thấp vì đoạn nối chỉ truyền tham số.
- **Không có script migration.** Các thay đổi schema (`reward_keys`,
  `completion_reward_state`) đều có giá trị mặc định và đường xử lý cho dữ liệu cũ, nên
  không cần sửa dữ liệu hàng loạt. Bản ghi hoàn thành từ trước được chuẩn hoá ngay lần
  gọi `complete` kế tiếp và không nhận thưởng hồi tố.
- **`register` vẫn kiểm tra tối thiểu 6 ký tự** trong khi backend yêu cầu 8. Cùng loại
  lỗi với `ChangePasswordScreen` nhưng nằm ngoài phạm vi 10 phát hiện nên chưa sửa.
