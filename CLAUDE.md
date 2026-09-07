# CLAUDE.md

Hướng dẫn cho Claude Code khi làm việc trong repo này.

## Dự án

Ứng dụng học tiếng Nhật: **Flutter** (`FrontEnd/`, ~43k dòng, state bằng Provider) và
**REST API Node/Express + MongoDB** (`BackEnd/`, 21 module, 261 route). Đồ án học kỳ, một
người làm, đang trong đợt thiết kế lại theo [lộ trình](docs/architecture/redesign-roadmap.md).

## Lệnh

```powershell
cd BackEnd;  npm run dev        # API tại http://localhost:3000
cd BackEnd;  npm test           # node --test, 63 test, không cần MongoDB
cd FrontEnd; flutter run
cd FrontEnd; dart analyze       # phải sạch tuyệt đối: 0 error, 0 warning, 0 info
cd FrontEnd; flutter test       # 25 test
```

Chạy `npm test` và `dart analyze; flutter test` của phần bị ảnh hưởng **trước** khi mở rộng
thay đổi sang chỗ khác. CI chạy đúng bộ lệnh này (`.github/workflows/ci.yml`).

## Tài liệu bắt buộc đọc trước khi sửa

| Tài liệu | Khi nào cần |
| --- | --- |
| [conventions.md](docs/architecture/conventions.md) | Trước mọi thay đổi code — đây là khuôn mẫu bắt buộc |
| [project-structure.md](docs/architecture/project-structure.md) | Khi thêm file mới, phân vân đặt ở đâu |
| [redesign-roadmap.md](docs/architecture/redesign-roadmap.md) | Khi cần biết việc đang ở giai đoạn nào |
| [phase-2-plan.md](docs/architecture/phase-2-plan.md) | Việc đang làm hiện tại |
| [out-of-scope.md](docs/architecture/out-of-scope.md) | Trước khi mở rộng phạm vi hoặc sửa module đang đóng băng |

## Khuôn mẫu code

**Backend — bốn tầng.** `routes` (path + middleware) → `controller` (chỉ map HTTP, mục tiêu
dưới 150 dòng, **không** `try/catch`) → `service` (rule nghiệp vụ, không biết `req`/`res`) →
`repository` (mọi truy vấn Mongoose). Service nhận repository qua tham số để test không cần
MongoDB. Bản mẫu: `BackEnd/src/modules/vocabulary/`.

**Validation và lỗi.** Mọi endpoint khai báo schema zod trong `<domain>.schema.js` + middleware
`validate({ query, params, body })`; controller chỉ đọc `req.valid`. Service ném `ApiError`;
`asyncHandler` + `error.middleware.js` lo phần còn lại. Hạ tầng ở `BackEnd/src/shared/http/`.

**Response contract.** Một tài nguyên `{ data }`; danh sách `{ data, total }`; có phân trang
`{ data, page, limit, total, totalPages }`. Dùng `ok` / `list` / `paginated` trong
`shared/http/respond.js`. **Danh sách rỗng luôn là 200 với mảng rỗng, không bao giờ 404.**

**Flutter.** Feature tự chứa: `screens/` (bố cục, dưới 250 dòng, giới hạn cứng 300) +
`widgets/` + `providers/` (giữ `ViewState`, gọi service) + `services/` (gọi `ApiClient`, trả
về **kiểu dữ liệu**, không trả `Map`) + `models/`. Screen không gọi service trực tiếp.
Bản mẫu: `FrontEnd/lib/features/vocabulary/`.

**Trạng thái và giao diện.** Provider dùng `ViewState<T>` + `ViewState.guard`
(`core/state/view_state.dart`); screen dùng `AsyncView` (`shared/widgets/async_view.dart`) cho
cả bốn nhánh loading/lỗi/rỗng/có dữ liệu. Màu, khoảng cách, bo góc lấy từ
`app/theme/app_tokens.dart` — không hardcode `Color(0x...)` hay `EdgeInsets.all(17)`.

## Bẫy trong repo này

- **Route công khai bị khoá bằng sha256.** `BackEnd/tests/route-contract.test.js` giữ
  `expectedCount` và `expectedSignatureHash` của 261 route. Đổi route thì cập nhật cả hai
  **trong cùng commit**, có chủ đích — đừng chỉnh hash cho test xanh.
- **Nhiều controller đang query field không tồn tại trong model.** Mongoose bỏ qua field lạ
  nên không có lỗi nào hiện ra, tính năng chỉ đơn giản là không chạy: `srs-progress`,
  `notification`, `progress` (phần lịch sử học), `news` (phần quản trị), `jlpt` (lịch sử thi).
  Chi tiết và cách sửa ở [phase-2-plan.md](docs/architecture/phase-2-plan.md). **Trước khi
  sửa bất kỳ controller nào, đối chiếu tên trường với model trong `BackEnd/model/`.**
- **`User` dùng tên tiếng Việt** (`TenDangNhap`, `MatKhau`, `VaiTro`, `TrinhDo`). Xấu nhưng
  model và controller nhất quán với nhau nên **vẫn chạy** — đừng đổi tên giữa chừng, việc này
  đụng 153 chỗ ở backend và 35 chỗ ở Flutter, đã xếp vào cuối lộ trình.
- **Model mới luôn dùng snake_case tiếng Anh.** Không tạo thêm thế hệ đặt tên thứ tư.
- **`BYPASS_AUTH=true` bỏ qua toàn bộ xác thực** và gán sẵn một admin giả. Chỉ dùng khi phát
  triển; `validateEnvironment()` chặn ở production.
- **`Vocabulary` không bật `timestamps`**, nên sort theo `createdAt` không có tác dụng — sort
  "mới nhất" bằng `_id: -1`.
- **Không commit `.env`.** Secret chỉ nằm ở `.env` local; `.env.example` chỉ chứa placeholder.

## Quy trình

1. Đặt code mới vào đúng domain: `BackEnd/src/modules/<domain>/` hoặc
   `FrontEnd/lib/features/<feature>/`. Không đưa code riêng của feature vào `core/`, `shared/`.
2. Bám khuôn mẫu của module đã làm xong thay vì phát minh cấu trúc mới. Chỉ tạo service hay
   repository khi có trách nhiệm thật, không tạo file rỗng cho đủ sơ đồ.
3. Mỗi module sửa xong phải có đủ bộ test trong `conventions.md`. Test dùng repository/service
   giả — không test nào được đụng MongoDB hay gọi API bên ngoài.
4. Khi đổi route công khai hoặc điều hướng Flutter, cập nhật contract test tương ứng
   (`route-contract.test.js`, `navigation_contract_test.dart`) trong cùng commit.
5. Commit theo Conventional Commits, tiếng Anh, thân commit giải thích **vì sao** chứ không
   liệt kê lại diff.

## Khi làm phần AI (luyện nói)

Backend gọi Claude bằng `@anthropic-ai/sdk`, model đọc từ `SPEAKING_MODEL` (không hard-code
model hoặc chi phí). Structured output dùng `output_config.format` cùng helper tương thích với
version SDK; phải xử lý cả `parsed_output` rỗng, `stop_reason: "refusal"` và
`stop_reason: "max_tokens"`. Chỉ `speaking-ai.service.js` được phép gọi Claude, và nó nhận
client qua tham số để test truyền client giả. `ANTHROPIC_API_KEY` chỉ nằm ở backend,
**không bao giờ** đưa vào Flutter. Chi tiết quota, privacy, retention và SRS integration nằm
trong [phase-2-plan.md](docs/architecture/phase-2-plan.md).
