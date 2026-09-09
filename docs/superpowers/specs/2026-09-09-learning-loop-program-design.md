# Thiết kế chương trình — Vòng lặp học khép kín

Ngày: 2026-09-09 · Trạng thái: đã sửa sau review, chưa triển khai theo bản sửa này

Tài liệu này chia phần việc "hoàn thiện app học tiếng Nhật có luyện nói AI" thành bảy mốc chính
và mốc phụ 1B có thể hoãn. Tài liệu ghi thứ tự, phụ thuộc và tiêu chí đo, bổ sung cho
[redesign-roadmap.md](../../architecture/redesign-roadmap.md); mỗi mốc vẫn có spec và
implementation plan riêng trước khi code.

Với mốc 1–3, tài liệu này cùng
[spec SRS](2026-09-09-srs-revival-design.md) và
[spec streak](2026-09-09-streak-integrity-design.md) thay thế các quyết định API, phạm vi Kanji và
ranh giới nói → SRS khác với [phase-2-plan.md](../../architecture/phase-2-plan.md).
Các phần khác của Phase 2 vẫn cần được rà khi lập plan; không mặc nhiên coi chúng đã triển khai.

## 1. Bối cảnh và ràng buộc

| Ràng buộc | Giá trị | Hệ quả lên thiết kế |
| --- | --- | --- |
| Mục tiêu kỳ này | Đồ án để bảo vệ | Ưu tiên vòng học có thể demo trọn vẹn |
| Mục tiêu sau đó | Có thể thành sản phẩm | Giữ ranh giới module và ghi rõ điểm mở rộng |
| Thời gian | Không có hạn cứng | Xếp theo giá trị và phụ thuộc; mỗi mốc có kết quả kiểm được |
| Quota AI | Theo yêu cầu dự án: có key, chỉ đủ demo | Giới hạn lượt/ngày; có đường gõ chữ và xử lý hết quota |
| Nhân lực | Một người | Thứ tự không đòi hỏi các mốc phải được làm song song |

## 2. Hiện trạng và giới hạn kiểm chứng

Đối chiếu mã nguồn ngày 2026-09-09. Bảng này mô tả checkout hiện tại, không chứng minh lịch sử
sử dụng hoặc trạng thái dữ liệu Atlas. Đường dẫn backend bên dưới tính từ `BackEnd/`.

| Mảng | Thực trạng trong mã | Bằng chứng |
| --- | --- | --- |
| Lịch ôn tập | Leitner box 1–5, hàm thuần, có test | `src/modules/srs/srs-scheduling.js`, `tests/srs-scheduling.test.js` |
| Truy cập dữ liệu SRS | Repository dùng `user`, `next_review`, được service từ vựng gọi | `src/modules/srs/srs.repository.js`, `src/modules/vocabulary/vocabulary.service.js` |
| Controller SRS | Nhiều đường đọc/ghi dùng trường lệch model; không được suy ra mọi route đều không chạy | `src/modules/srs/srs-progress.controller.js`, `model/SRSProgress.js` |
| UI ôn theo lịch | Chưa thấy provider/screen gọi `SRSService`; flashcard hiện là luồng riêng | `FrontEnd/lib/features/srs/services/srs_service.dart`, tìm tham chiếu trong `FrontEnd/lib` |
| Luyện nói AI | Có thiết kế Phase 2 §5; chưa thấy module `speaking` và SDK Anthropic trong backend | Cây `src/modules/`, `package.json`; đây không phải phép đo "0 dòng code" |
| Bài tập | Model hiện quy định trắc nghiệm với 2–4 đáp án | `model/Exercise.js`, validator của mảng `answers` |
| Hán-Việt | Đã hiển thị ở danh sách/chi tiết Kanji, có CRUD và import CSV admin; chưa có bài học theo cụm và bẫy nghĩa | `FrontEnd/lib/features/kanji/`, luồng quản trị Kanji |
| Nét viết Kanji | Có trường SVG trong model; chưa thấy consumer hiển thị `strokeOrderSvg` trong Flutter | `model/Kanji.js`, `FrontEnd/lib/features/kanji/models/kanji.dart` |
| Nội dung seed | 15 từ vựng, 20 Kanji, 16 ngữ pháp trong các script tương ứng | `scripts/seed-vocabulary.js`, `scripts/seed-kanji.js`, `scripts/seed-grammar.js` |

Các số seed là **số mục khai báo trong script**, không phải số bản ghi DB hoặc độ phủ N5.
Chưa truy vấn Atlas để xác định số tiến độ lỗi, lượng nội dung thực tế hay tỷ lệ từ hội thoại
ánh xạ được sang `Vocabulary._id`. Audit phải xong trước migration/cutover dữ liệu thật;
không chặn việc viết hàm và test mốc 1 trên fixture trong DB kiểm thử.

Tầng lịch có thể giữ. Việc cần làm ở mốc 1 là nối đúng API, dữ liệu và giao diện để hoàn thành
vòng ôn Vocabulary. Không dùng kết quả tìm tham chiếu để khẳng định người học "chưa từng" ôn
tập hoặc các route admin "chưa bao giờ" được gọi.

## 3. Nguyên tắc xuyên suốt

- **Mỗi mốc có kết quả dùng được.** Nghiệm thu bằng hành vi người học, kèm test kỹ thuật.
- **Dùng lại giao diện đã chuẩn hóa.** Màn mới dùng `AppScaffold`, `ContentPane` và token có sẵn;
  cho phép sửa lại màn đã làm khi phụ thuộc hoặc bằng chứng sử dụng yêu cầu, kiểm tra hồi quy.
- **Vòng học cơ bản hoạt động khi AI không khả dụng.** Gõ chữ thay microphone vẫn cần AI để
  phản hồi; hết quota hoặc lỗi AI thì báo rõ và người học vẫn dùng được từ vựng/SRS thông thường.
- **Nội dung là điều kiện đầu vào.** Bộ demo phải có trước hội thoại, không chờ tới mốc 7.
- **Điểm mở rộng được ghi rõ.** Chưa thêm trường cho SM-2, Grammar SRS hoặc lỗi phát âm.
- **Phân biệt dữ kiện, mục tiêu và giả thuyết.** Chưa tuyên bố độc quyền thị trường hoặc hiệu quả
  ghi nhớ dài hạn khi mới chỉ có demo và test kỹ thuật.

## 4. Các mốc và điều kiện chuyển mốc

| # | Mốc | Lý do thứ tự | Phụ thuộc |
| --- | --- | --- | --- |
| 1 | **SRS + streak tin cậy** | Hoàn thành ôn Vocabulary và một đường ghi hoạt động | Fixture nhỏ để phát triển; audit trước cutover |
| 1B | **Streak — lịch, mục tiêu ngày, băng** | Cơ chế giữ chân, tách khỏi mốc 1 vì đổi trải nghiệm chứ không sửa lỗi | 1 |
| 2 | **Luyện nói AI** | Tạo hội thoại và phản hồi bằng tiếng Việt | Bộ nội dung demo ở §4.2 |
| 3 | **Nối nói vào SRS** | Trọng tâm câu chuyện vòng học của đồ án | 1, 2 và kiểm độ phủ nội dung |
| 4 | **Cầu nối Hán-Việt** | Phát triển bài học từ khả năng hiển thị đã có | Nguồn dữ liệu và spec riêng |
| 5 | **Bài tập sản sinh** | Bổ sung thực hành gõ/điền/chia từ ngoài nhận biết đáp án | Spec model và cách chấm |
| 6 | **Kỹ năng nghe** | Dùng dạng bài nhập tự do; cần nguồn audio | 5 |
| 7 | **Nội dung quy mô thật** | Mở rộng N5 sau khi luồng học và nhập liệu ổn định | 1–6 |

Thứ tự ưu tiên là 1 → bộ nội dung demo → 2 → 3 → 4–7. Mốc 1B có thể làm sau 1 hoặc hoãn
sau 3; không bắt buộc hoàn thiện freeze/lịch trước khi luyện nói. Bộ nội dung nhỏ là
điều kiện chuyển mốc, còn nội dung N5 đầy đủ vẫn thuộc mốc 7.

Mốc 1B đánh số phụ để không phải đổi số các mốc 2–7. Nó **không** chặn mốc 2: có thể làm xen
kẽ hoặc hoãn, vì nó không tạo dữ liệu mà mốc 2–3 cần. Chi tiết ở
[spec streak](2026-09-09-streak-integrity-design.md).

### 4.0 Thứ tự bắt đầu và dữ liệu từ vựng

**Có thể triển khai chức năng trước, bổ sung nội dung lớn sau.** Không cần đủ 60 từ hoặc
đủ N5 để viết và kiểm SRS/streak. Cần dữ liệu nhỏ hợp lệ để kiểm vòng học thực tế.

| Bước | Làm gì | Dữ liệu cần |
| --- | --- | --- |
| 0 | Chốt contract chung SRS/streak, kiểm baseline; chuẩn bị fixture và audit chỉ đọc | 2 tài khoản kiểm thử, 1–2 bài học, khoảng 10–15 từ hợp lệ; bộ 40 thẻ sinh tự động cho test nhiều đợt |
| 1 | Viết dayKey/rules/policy, ActivityEvent/StreakDay, repository, transaction và test chống trùng | Fixture, không cần kho từ vựng lớn |
| 2 | Chuyển nguồn ghi login/bài học/bài tập/JLPT/achievement sang cổng chung; đóng API tự cấp XP; sửa đọc/export | Attempt/achievement và dữ liệu legacy giả để test migration; không refactor phần ngoài nguồn ghi liên quan |
| 3 | Nối API SRS, Vocabulary detail và Flutter vào recordActivity chung; đủ luồng ôn/reset/xóa/lỗi | Bộ từ nhỏ; clock giả để kiểm đến hạn, không chờ ngày thật |
| 4 | Smoke DB kiểm thử, dry-run migration, đối chiếu và cutover mốc 1 | Audit/backup dữ liệu thật phải đạt trước thao tác ghi hoặc triển khai bản mới lên DB đó |
| 5 | Hoàn thiện nhập nội dung an toàn và nạp bộ demo 60 từ/3 chủ đề | Dữ liệu đã rà và có nguồn theo §4.2 |
| 6 | Mốc 2 hội thoại → mốc 3 chọn từ và ôn lại; làm 1B khi muốn đầu tư thêm trải nghiệm | Bộ demo đã nhập, kiểm được ID thật và khả năng ánh xạ |
| 7 | Mở rộng các kỹ năng/nội dung ở mốc 4–7 | Từng bộ dữ liệu và tiêu chí chất lượng riêng |

Các bước 1–3 có thể thành các commit nhỏ; không deploy nửa số writer cũ/nửa số writer mới.
Viết implementation plan mốc 1 theo thứ tự trên, ghi test chặn cho từng bước.

**Thêm dữ liệu mà không mất tiến độ:**

- Có thể soạn/rà Excel/CSV/JSON ngay trong lúc viết code; tách công việc biên soạn khỏi nhập DB.
- Vocabulary hiện bắt buộc `word`, `hiragana`, `meaning` và `lesson`; `level=N5` cần
  cho bộ demo. Phải có Lesson hợp lệ trước khi nhập, không chỉ một danh sách từ và nghĩa.
- `BackEnd/scripts/seed-vocabulary.js` hiện gọi `Vocabulary.deleteMany({})` trước insert.
  Chỉ dùng seed này cho DB dùng một lần; **không chạy lại trên DB đang có nội dung/tiến độ**.
- Import Excel hiện dùng `insertMany`, chưa tự chống trùng khi nạp lại. Trước nạp lớn, thêm
  dry-run, báo lỗi từng dòng và cơ chế nhập lặp không tạo bản sao. Dùng manifest ánh xạ mã
  nội dung ổn định → `_id`; cập nhật đúng ID cũ, không xóa/tạo lại và không chỉ khớp theo
  mặt chữ vì từ đồng hình/khác nghĩa có thể là các mục khác nhau.
- Nạp thêm từ không được thay `SRSProgress.item_id` hoặc đặt lại box/lịch. Kiểm lại tham
  chiếu trước–sau import. Khi thêm vào bài đã có người hoàn thành, chốt ảnh hưởng tổng mục
  học; ưu tiên bài demo mới, không tự thu hồi XP hay lịch sử hoàn thành cũ.
- Bộ 10–15 từ và 40 thẻ test là fixture, không phải cam kết số bản ghi Atlas. Ngưỡng 60 từ
  là điều kiện demo nói/SRS, không phải điều kiện bắt đầu triển khai mốc 1.

### 4.1 Mốc 1 — SRS sống lại

Bao gồm **Phần A của [spec streak](2026-09-09-streak-integrity-design.md)**: gom một đường
`recordActivity`, bảng XP phía server, ActivityEvent/StreakDay, migration và một unit of work
chung. Bỏ ba route ghi không hợp lệ trong streak cùng `/achievement/update-progress`,
sửa định danh lần nộp và ghi ngày cho JLPT/bài tập, gộp kiểm mốc qua cổng chung.
Giữ các endpoint đọc, sửa contract/consumer có chủ đích để xuất dữ liệu không mất lịch sử.
Mỗi lượt SRS đến hạn được commit nhận **2 XP**; đây là chính sách mới đã đồng bộ ở cả hai spec.
Phạm vi nguồn ghi phải xong trước khi tích hợp và triển khai vòng SRS lên dữ liệu thật.

Dựng lại module trên scheduler Leitner và repository hiện có; mở rộng repository cho truy vấn
đến hạn và cập nhật có điều kiện. Nghiệm thu **Vocabulary**: tạo tiến độ khi đánh dấu đã học,
lấy thẻ theo đợt, đúng/sai, thống kê, xóa tiến độ và reset riêng.

API có **sáu route** theo spec SRS, bỏ bốn route admin khỏi phạm vi demo. Reset giữ thẻ trong
lịch, về box 1, streak 0, hẹn sau 24 giờ; xóa làm mất bản ghi tiến độ. Hai thao tác không tính
là một lần trả lời. Giữ `/review` là hub các cách ôn; mục "Ôn tập hôm nay" mở `/srs` để người
học có một điểm vào rõ ràng. Cập nhật test điều hướng theo quyết định UX này.

Kanji SRS cần spec riêng để chốt quan hệ với `lesson-progress` và đường tạo tiến độ. Không đưa
nó vào nghiệm thu mốc 1 hoặc mặc nhiên giao cho mốc 4. Model vẫn giữ enum `Vocabulary`/`Kanji`;
việc giữ enum không có nghĩa luồng Kanji đã hoàn chỉnh. Xử lý dữ liệu Kanji có sẵn theo spec SRS.

Ra khỏi mốc: từ được đánh dấu đã học xuất hiện đúng hạn, mỗi lượt chỉ đổi lịch/XP một lần,
thẻ bỏ qua không chặn thẻ khác, badge đúng và login/GET không tự tạo ngày học.
Migration bảo toàn số dư/lịch sử; export vẫn xuất đủ các trang XP và ngày.

### 4.2 Điều kiện nội dung trước mốc 2

**Mục tiêu sản phẩm đề xuất để nghiệm thu, chưa phải số đo hiện trạng:**

- Có ít nhất **60 từ Vocabulary khác nhau**, phù hợp N5 theo bộ chuẩn nội dung được chọn,
  đã rà cách viết, cách đọc và nghĩa tiếng Việt, được nhập thành công trong môi trường demo.
- Phủ ba chủ đề **tự giới thiệu, sinh hoạt hằng ngày, ăn uống**. Mỗi chủ đề có kịch bản kiểm
  soát tạo ít nhất **5 candidate khác nhau** ánh xạ được sang ID có thật; không cộng trùng từ
  giữa các chủ đề để đạt tổng 60.
- Ghi nguồn, giấy phép hoặc căn cứ quyền sử dụng cho từng tập nội dung; giải quyết quyền dùng
  **trước khi nhập bộ demo**, không để đến mốc 7. Nội dung tự soạn cũng ghi người rà và phiên bản.
- Chạy kiểm kê trên DB demo và đối chiếu các ID mà kịch bản sẽ dùng. Đếm file seed hoặc chỉ
  dựa vào chữ giống nhau chưa đủ chứng minh ánh xạ và nội dung đúng nghĩa.

Đây là ngưỡng cho kịch bản có kiểm soát, không bảo đảm mọi hội thoại tự do đều có 5 từ phù hợp.
Ghi số candidate và số ánh xạ được khi chạy thử để biết cần bổ sung nội dung ở đâu.

### 4.3 Mốc 2 — Luyện nói AI

Dùng thiết kế [Phase 2 §5](../../architecture/phase-2-plan.md) cho module bốn tầng, adapter AI
nhận client qua tham số, hội thoại, sửa câu, giải thích tiếng Việt, quota, STT/TTS và ô nhập chữ.
**Chuyển các thao tác chọn từ để ghi SRS ở §5.1 bước 5, §5.5 và phần tương ứng của `finish`
sang mốc 3.** Mốc 2 có thể trả candidate và kết thúc phiên, chưa tạo tiến độ SRS từ phiên nói.
Ghi nhận hoạt động hội thoại/quota vẫn thuộc mốc 2 và phải chống ghi nhận trùng.

Audio không gửi tới **backend ứng dụng**. STT/TTS phụ thuộc engine nền tảng, có thể dùng dịch vụ
mạng; không cam kết audio không rời thiết bị hoặc xử lý hoàn toàn offline. Thông báo quyền riêng
tư và fallback phải khớp engine thực tế. Rà SDK/model/API tại thời điểm viết plan.

Ra khỏi mốc: hoàn thành hội thoại trong ba kịch bản demo, nhận sửa câu/giải thích, gõ chữ khi
microphone bị từ chối và xử lý lỗi/quota mà không làm mất phiên hoặc ghi nhận hoạt động trùng.

### 4.4 Mốc 3 — Nối nói vào SRS

Đây là **trọng tâm trình bày của đồ án**: người học chọn từ cần luyện trong phiên nói, rồi gặp
lại chúng theo lịch. Giả thuyết sản phẩm là cách nối này hữu ích cho người Việt; chưa có khảo
sát để kết luận "thị trường bỏ trống" hay "không app nào có".

Chỉ cho chọn candidate đã ánh xạ được sang `Vocabulary._id` hiện có. Từ chưa tìm thấy chỉ hiển
thị để tham khảo, không tự tạo Vocabulary hoặc SRS. Backend xác thực lựa chọn theo phiên/chủ
sở hữu, kiểm tra nội dung tồn tại, loại trùng và bảo đảm gửi lại không tạo tiến độ trùng.

- **Chưa có tiến độ:** tạo box 1, streak 0, `next_review = thời điểm thêm + 24 giờ`.
- **Đã có tiến độ:** giữ nguyên box, streak và lịch, kể cả người học vừa dùng sai từ trong nói.
- **Lỗi ngữ pháp/phát âm:** hiển thị phản hồi trong phiên, chưa biến thành thẻ SRS.

Không hứa mọi "lỗi nói hôm nay" sẽ xuất hiện trong SRS ngày mai. Demo dùng tài khoản/fixture
chưa có tiến độ cho các từ được chọn: **mỗi chủ đề chọn và thêm được ít nhất 3 từ mới vào SRS**,
xác nhận ID và lịch, rồi dùng đồng hồ giả để kiểm lúc đến hạn và sau một lượt trả lời.
Kiểm riêng từ đã có tiến độ và request gửi lại để chứng minh lịch không bị đặt lại.

### 4.5 Mốc 4 — Cầu nối Hán-Việt

Xây bài học theo cụm, gợi ý đoán nghĩa từ ghép và các cặp bẫy nghĩa Nhật–Việt trên dữ liệu
Hán-Việt đã hiển thị. Nếu cần trường Hán-Việt cho Vocabulary, spec riêng phải chốt nguồn và
phạm vi model. Giá trị với người Việt là giả thuyết cần đo bằng bài tập và phản hồi sử dụng.

### 4.6 Mốc 5 — Bài tập sản sinh

Mở rộng khỏi trắc nghiệm 2–4 đáp án: gõ đáp án, điền khuyết, chia động từ. Spec phải chốt
chuẩn hóa đáp án, các cách trả lời được chấp nhận, chấm điểm và tương thích bài cũ.

### 4.7 Mốc 6 — Kỹ năng nghe

Nghe chép chính tả và nghe hiểu trên dạng bài mốc 5. Chốt nguồn/quyền dùng audio, transcript
và kiểm tra phát audio trước nghiệm thu; không chỉ kiểm tra giao diện nút nghe.

### 4.8 Mốc 7 — Nội dung quy mô thật

Mở rộng bộ demo lên phạm vi N5 được định nghĩa bằng danh mục và nguồn cụ thể. Kiểm quyền dùng,
độ trùng, tính đúng, độ phủ bài học và quy trình nhập; chưa gán phần trăm hoàn thành từ số seed.

## 5. Ngoài phạm vi hiện tại

- Kanji SRS hoàn chỉnh: chờ spec riêng về đường học và quan hệ `lesson-progress`.
- Nét viết/chấm nét Kanji, pitch accent và Grammar SRS: cần dữ liệu hoặc mô hình riêng.
- SRS cho lỗi ngữ pháp/phát âm; tự tạo từ bằng AI; tự kéo lịch sớm vì lỗi hội thoại.
- Furigana/ruby text và group chat theo các ràng buộc roadmap hiện hành.
- Chuyển sang SM-2: giữ Leitner cho mốc 1; thuật toán không đồng nhất với số nút tự chấm của UI.
- STT tại backend ứng dụng; không suy ra từ giới hạn này rằng STT nền tảng luôn chạy tại thiết bị.

## 6. Cách đo

Các cổng kỹ thuật dưới đây là **mức tối thiểu**, không thay tiêu chí hành vi riêng từng mốc:

- Backend: `npm test` xanh. Flutter: `dart analyze --fatal-infos`, `flutter test` và
  `flutter build web --release` đạt trong các thư mục tương ứng.
- Đổi route công khai/điều hướng thì cập nhật contract tương ứng trong cùng commit; có test
  điều hướng web khi bị ảnh hưởng và kiểm không tràn ở các bề rộng đã chốt.
- Test trọng tâm theo spec: repository thực sự tạo đúng query/update, HTTP validation/quyền
  sở hữu, xung đột, retry và trạng thái UI; fake service không thay được kiểm các ranh giới này.

| Mốc/luồng | Bằng chứng nghiệm thu sản phẩm |
| --- | --- |
| 1 | Tạo → chờ đủ 24h bằng đồng hồ giả → ôn đúng/sai; không xử lý trùng; lấy nhiều đợt không bỏ sót; reset khác xóa |
| Phần A streak trong 1 | Event/kết quả/XP/ngày cùng commit; retry nộp bài không nhân đôi; migration và xuất đủ lịch sử được kiểm bằng fixture |
| 1B — có thể hoãn | Goal tách khỏi streak; freeze có ledger ngày và không sửa SRS; lịch phân biệt legacy; nhắc trong app đúng phạm vi đã chốt |
| Trước 2 | Kiểm kê đạt 60 từ, 3 chủ đề, ≥5 candidate map được/chủ đề và hồ sơ nguồn/quyền dùng |
| 2 | Hoàn thành 3 kịch bản; ghi số lượt thành công, lỗi/quota và candidate map được; đường nhập chữ hoạt động |
| 3 | ≥3 từ mới/chủ đề được chọn → lưu đúng ID/lịch → xuất hiện đúng hạn → cập nhật sau ôn; từ có sẵn giữ lịch |
| 4–7 | Spec riêng chốt tập bài/nội dung, cách chấm và ngưỡng trước khi code; báo cáo kết quả trên tập đó |

Lưu phiên bản fixture, số chạy thực tế và kết quả đạt/chưa đạt trong biên bản nghiệm thu.
Đo hoàn tất luồng và độ phủ ánh xạ trước; cải thiện ghi nhớ dài hạn cần nghiên cứu sử dụng sau này.

## 7. Quyết định còn để mở

| Câu hỏi | Cần trả lời trước |
| --- | --- |
| Nguồn, quyền dùng, bộ chuẩn N5 và danh sách 60 từ demo cụ thể | Mốc 2; trước khi nhập nội dung |
| Ngưỡng quota, SDK/model và engine STT/TTS thực tế | Plan mốc 2 |
| Nguồn và phương pháp kiểm các cặp bẫy Hán-Việt | Mốc 4 |
| Quan hệ Kanji đã học với bài học và đường đưa vào SRS | Spec Kanji SRS riêng |
| Danh mục N5 đầy đủ, nguồn và tiêu chí chất lượng khi mở rộng | Mốc 7 |
| Có đủ nhu cầu để đổi thuật toán SRS không | Sau khi có dữ liệu sử dụng, ngoài mốc 1 |
