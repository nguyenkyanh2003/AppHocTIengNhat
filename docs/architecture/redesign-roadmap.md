# Lộ trình thiết kế lại (14 tuần)

Tài liệu này ghi lại lý do, phạm vi và thứ tự công việc của đợt thiết kế lại dự án.
Quy ước kỹ thuật cụ thể nằm ở [conventions.md](conventions.md); cấu trúc thư mục hiện
hành nằm ở [project-structure.md](project-structure.md).

## Vấn đề

Dự án chạy được nhưng khó sửa và khó mở rộng. Bốn nhóm vấn đề được xác nhận bằng
chính codebase tại thời điểm bắt đầu (2026-09-07):

| Vấn đề | Bằng chứng |
| --- | --- |
| Controller làm mọi việc | `src/modules/jlpt/jlpt.controller.js` 1351 dòng; 19/21 module không có service; `vocabulary.controller.js` cấu hình `multer` ngay trong controller |
| Business logic sai vì lẫn với HTTP | `vocabulary.controller.js` lọc `studyStatus` **sau khi** đã phân trang, nên trang bị thiếu item và `totalItems` không khớp |
| Response contract không nhất quán | `{totalItems,totalPages,currentPage,data}` ở endpoint này, `{total,data}` ở endpoint khác; `GET /api/vocabulary/search` trả `404` khi không có kết quả |
| Không validate input | Không có lớp validation; `parseInt(req.query.limit)` không chặn giá trị lớn bất thường |
| Xử lý lỗi lặp lại | Mỗi handler tự `try/catch` + `res.status(500)`; `error.middleware.js` gần như không được dùng |
| Screen khổng lồ | `group_detail_screen.dart` 1888 dòng, `home_screen.dart` 1139, `learning_history_screen.dart` 1031 |
| State thủ công, khởi tạo nặng | 23 `ChangeNotifierProvider` khởi tạo eager; mỗi provider tự quản `_isLoading`/`_error`/`_data` |
| Không có design system | `app_theme.dart` chỉ có bảng màu, không có spacing/typography scale, không có widget trạng thái dùng chung |
| `ApiClient` ôm quá nhiều việc | HTTP + token + offline cache + multipart + map lỗi trong một file; danh sách endpoint cache hardcode trong `_isCacheable` |
| Kiểm thử mỏng, không có CI | 6 test file backend, 4 test file Flutter, `.github/` không có workflow |

## Ràng buộc

- Giữ nguyên stack: Flutter + Provider, Express 5 + Mongoose 8. Refactor tại chỗ, không viết lại.
- Giữ toàn bộ tính năng hiện có. Vì quỹ thời gian ~1 học kỳ không đủ đầu tư sâu cho cả 21 domain, chia hai mức:
  - **Tier A — đầu tư sâu**: lesson, vocabulary, kanji, grammar, exercise, SRS/flashcard/streak/achievement, JLPT.
  - **Tier B — chuẩn hoá cơ học, không thêm tính năng**: study group/chat, news, notebook, report, settings, transaction, admin.
- App phải chạy được sau mỗi bước. Không đổi API/schema ngoài chủ đích.
- API contract bị khoá bằng sha256 trong `BackEnd/tests/route-contract.test.js`. Mọi thay đổi route phải cập nhật digest có chủ đích trong cùng commit.

## Baseline (đo ngày 2026-09-07, trước khi refactor)

| Chỉ số | Giá trị |
| --- | --- |
| BackEnd: file `.js` trong `src/` + `model/` | 78 |
| BackEnd: tổng số dòng | 12.591 |
| BackEnd: số module | 21 |
| BackEnd: số public route | 261 |
| BackEnd: test file / test case | 6 / 12 (pass) |
| BackEnd: controller lớn nhất | `jlpt.controller.js` — 1351 dòng |
| FrontEnd: file `.dart` trong `lib/` | 145 |
| FrontEnd: tổng số dòng | 43.059 |
| FrontEnd: test file | 4 |
| FrontEnd: screen lớn nhất | `group_detail_screen.dart` — 1888 dòng |
| FrontEnd: global provider khởi tạo eager | 23 |
| CI | không có |

Cuối mỗi giai đoạn, đo lại các chỉ số này để so sánh trong báo cáo.

## Các giai đoạn

| GĐ | Thời lượng | Nội dung | Kết quả |
| --- | --- | --- | --- |
| 0 | Tuần 1 | Nền móng: CI, quality gate, baseline, khung tài liệu | Mọi thay đổi sau đó được máy kiểm tra |
| 1 | Tuần 2–4 | Lát cắt dọc mẫu **Vocabulary + SRS** (BackEnd → FrontEnd) | Khuôn mẫu để mọi feature khác bắt chước |
| 2 | Tuần 5–9 | Nhân bản khuôn mẫu: Tier A trước, Tier B sau | 21 domain cùng một hình dạng |
| 3 | Tuần 10–12 | Redesign UI/UX toàn app trên design system | App trông như một sản phẩm thống nhất |
| 4 | Tuần 13–14 | Bảo mật, hiệu năng, test coverage, deploy, tài liệu | Sẵn sàng bảo vệ và demo online |

### Giai đoạn 0 — Nền móng (tuần 1)

1. `.github/workflows/ci.yml`: job `backend` (`npm ci` → `npm test`) và job `flutter`
   (`flutter pub get` → `dart analyze --fatal-infos` → `flutter test`). Quality gate đã ghi
   trong README nhưng trước đây không có máy nào ép.
2. Vệ sinh secret: `.env` không nằm trong source control; xoay `JWT_SECRET` và
   `EMAIL_PASSWORD` nếu từng bị commit.
3. Ghi baseline đo được (bảng trên).
4. Dựng khung [conventions.md](conventions.md), điền bằng kết quả thật của GĐ 1.

### Giai đoạn 1 — Lát cắt dọc mẫu: Vocabulary + SRS (tuần 2–4)

Nguyên tắc: làm **một** feature thật tốt, đủ để lộ mọi vấn đề chung, rồi biến nó thành
khuôn mẫu. Không đụng feature khác trong giai đoạn này.

**BackEnd — hạ tầng dùng chung** (`src/shared/http/`): `api-error.js`, `async-handler.js`,
`respond.js`, `validate.js` (zod). Nâng cấp `error.middleware.js` để nhận diện `ApiError`,
`ValidationError`, `CastError` và lỗi duplicate key.

**BackEnd — dựng lại `vocabulary` và `srs` theo 4 tầng**: routes (mỏng) → controller (chỉ
map HTTP) → service (rule nghiệp vụ, không biết `req`/`res`) → repository (truy vấn
Mongoose). Tách phần import Excel khỏi controller. Gom thuật toán Leitner của SRS thành
hàm thuần để unit test.

**BackEnd — sửa đúng 3 lỗi contract lộ ra trong lát cắt**: đẩy filter `studyStatus` xuống
DB trước khi phân trang; `search` trả `200` + mảng rỗng thay vì `404`; ép `limit` tối đa 100.
Cập nhật `expectedSignatureHash` trong cùng commit.

**FrontEnd — design system**: `app/theme/app_tokens.dart` + `app_typography.dart`;
`shared/widgets/` với `async_view.dart` (loading/error/empty/data), `app_scaffold.dart`,
`app_card.dart`, `level_badge.dart`.

**FrontEnd — chuẩn state & network**: `core/state/view_state.dart` thay bộ ba cờ thủ công;
tách offline cache khỏi `ApiClient`; đăng ký provider lazy.

**FrontEnd — dựng lại màn hình vocabulary** theo khuôn mẫu: screen < 250 dòng, phần trình
bày tách sang `widgets/`.

**Định nghĩa hoàn thành**: `vocabulary.controller.js` < 150 dòng và không còn `try/catch`
thủ công; không file Dart nào trong `features/vocabulary/` > 300 dòng; 3 lỗi contract đã
sửa; CI xanh; `conventions.md` đủ để người khác làm module tiếp theo mà không cần hỏi.

### Giai đoạn 2 — Nhân bản khuôn mẫu (tuần 5–9)

Thứ tự: `lessons` + `lesson-progress` → `kanji` → `grammar` → `exercise` → `jlpt` (nặng
nhất, làm sau khi khuôn mẫu đã ổn định) → Tier B. Mỗi module là một thay đổi độc lập, kèm
đủ bộ test theo `conventions.md`. Tách `group_detail_screen.dart` trong đợt Tier B.

### Giai đoạn 3 — Redesign UI/UX (tuần 10–12)

Vẽ lại information architecture (home và điều hướng chính hiện gánh 21 lối vào), áp design
system lên toàn bộ màn hình, thống nhất trạng thái rỗng/lỗi, dark mode, responsive.

### Giai đoạn 4 — Chất lượng và vận hành (tuần 13–14)

Bỏ `BYPASS_AUTH` khỏi đường chạy production, rate limit cho auth, siết giới hạn upload,
refresh token, index MongoDB cho truy vấn nóng, nâng test coverage, deploy backend và
Flutter Web, hoàn thiện tài liệu và kịch bản demo.
