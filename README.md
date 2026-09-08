# AppHocTiengNhat — Ứng dụng học tiếng Nhật

[![CI](https://github.com/nguyenkyanh2003/AppHocTIengNhat/actions/workflows/ci.yml/badge.svg)](https://github.com/nguyenkyanh2003/AppHocTIengNhat/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.29-02569B?logo=flutter&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-22-339933?logo=nodedotjs&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-Atlas-47A248?logo=mongodb&logoColor=white)

Ứng dụng học tiếng Nhật cho người luyện thi JLPT: bài học, từ vựng, Kanji, ngữ pháp, bài tập, ôn tập theo SRS và theo dõi tiến độ. Flutter client + REST API Node.js/Express trên MongoDB.

> **Trạng thái:** đồ án học kỳ, một người làm, **đang trong đợt thiết kế lại 14 tuần**. App chạy được và demo được, nhưng chưa phải mọi module đều đạt chuẩn kiến trúc mới — phần nào đã đạt, phần nào chưa, ghi rõ ở mục [Tính năng](#tính-năng).

## Bài toán

Người học tiếng Nhật bỏ cuộc không phải vì thiếu tài liệu mà vì thiếu hệ thống: học xong không biết khi nào cần ôn lại, ôn lại thì không biết ôn gì, và không thấy mình tiến bộ ở đâu. Ứng dụng giải quyết bằng một vòng lặp học khép kín — học bài → làm bài tập → thẻ đến hạn theo SRS → tiến độ và streak — thay vì làm thêm một kho nội dung để tra cứu.

Về phía kỹ thuật, codebase ban đầu chạy được nhưng khó sửa: controller ôm mọi việc, response contract mỗi endpoint một kiểu, không có validation, screen Flutter dài gần 1.900 dòng. Đợt thiết kế lại đặt ra bốn ràng buộc, và chúng được **ép bằng test chứ không phải bằng lời hứa**:

| Nguyên tắc | Cách thực thi trong code |
| --- | --- |
| Backend bốn tầng | `routes` → `controller` (chỉ map HTTP, không `try/catch`) → `service` (không biết `req`/`res`) → `repository` (nơi duy nhất query Mongoose). Service nhận repository qua tham số nên test không cần MongoDB |
| Response contract thống nhất | Một tài nguyên `{ data }`; danh sách `{ data, total }`; phân trang `{ data, page, limit, total, totalPages }`. **Danh sách rỗng luôn là `200` với mảng rỗng, không bao giờ `404`** |
| API không đổi ngầm | `tests/route-contract.test.js` khoá 261 route bằng sha256. Thêm hoặc đổi một route là CI đỏ, buộc phải cập nhật digest có chủ đích trong cùng commit |
| Flutter feature-first | Mỗi feature tự chứa `screens/` + `widgets/` + `providers/` + `services/` + `models/`. Screen không gọi service trực tiếp. `dart analyze` phải sạch tuyệt đối: 0 error, 0 warning, 0 info |

Bản mẫu tham chiếu cho cả hai phía là module `vocabulary` — backend `BackEnd/src/modules/vocabulary/`, frontend `FrontEnd/lib/features/vocabulary/`.

## Tech stack

| Lớp | Công nghệ |
| --- | --- |
| Backend | Node.js 22 · Express 5 · ES Modules |
| Database | MongoDB (Atlas hoặc local) · Mongoose 8 |
| Xác thực | JWT (`jsonwebtoken`) · bcrypt · rate limiter cho nhóm route auth |
| Validation | zod — schema theo domain + middleware `validate({ query, params, body })` |
| Frontend | Flutter 3.29 · Dart 3.7 · Provider · design token tập trung |
| Tiện ích | ExcelJS/xlsx (import–export) · Multer (upload) · Nodemailer (reset mật khẩu) · moment-timezone |
| Kiểm thử | `node --test` (63 test) · `flutter test` (25 test) · `dart analyze --fatal-infos` |
| CI | GitHub Actions — hai job Node và Flutter chạy song song trên mỗi push/PR vào `main` |

## Kiến trúc tổng quan

```text
        ┌──────────────────── Flutter client (FrontEnd/) ────────────────────┐
        │  screens/  →  providers/ (ViewState)  →  services/  →  ApiClient   │
        │  Web · Android · cache ngoại tuyến làm dự phòng khi mất mạng       │
        └───────────────────────────────┬───────────────────────────────────┘
                                        │  HTTP + JWT (Bearer)
                                        ▼
        ┌──────────────────── Express API (BackEnd/src/) ────────────────────┐
        │  app.js — CORS · JSON · static uploads · đăng ký 21 module route   │
        │                                                                   │
        │   routes ──► controller ──► service ──► repository ──► Mongoose   │
        │      │            │            │             │                    │
        │      │            │            │             └─ nơi DUY NHẤT query│
        │      │            │            └─ rule nghiệp vụ, ném ApiError    │
        │      │            └─ chỉ đọc req.valid, không try/catch           │
        │      └─ path + middleware (auth, validate zod, upload)            │
        │                                                                   │
        │  shared/http/  asyncHandler · ApiError · respond · validate       │
        │  middleware/   error.middleware.js — điểm bắt lỗi duy nhất        │
        └───────────────────────────────┬───────────────────────────────────┘
                                        ▼
                          ┌──────────────────────────┐
                          │  MongoDB — 23 collection │
                          │  Atlas hoặc local        │
                          └──────────────────────────┘
```

Chi tiết: [system-overview.md](docs/architecture/system-overview.md) · [data-model.md](docs/architecture/data-model.md) · [API_OVERVIEW.md](docs/api/API_OVERVIEW.md)

## Cài đặt local

### Yêu cầu

- **Node.js 20+** và npm. Kiểm chứng với Node.js 22.15.0 / npm 10.9.2.
- **MongoDB** — Atlas (khuyến nghị) hoặc MongoDB Server chạy local.
- **Flutter stable** tương thích Dart `>=3.0.0 <4.0.0`. Kiểm chứng với Flutter 3.29.3 / Dart 3.7.2.
- Android Studio, Xcode hoặc trình duyệt, tuỳ target Flutter muốn chạy.

### 1. Clone và cài dependency backend

```powershell
git clone https://github.com/nguyenkyanh2003/AppHocTIengNhat.git
cd AppHocTIengNhat/BackEnd
npm ci
Copy-Item .env.example .env
```

### 2. Cấu hình `.env`

Mở `BackEnd/.env` và điền tối thiểu `MONGODB_URI`, `DB_NAME` và `JWT_SECRET`. Sinh khoá ngẫu nhiên:

```powershell
node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"
```

Với MongoDB Atlas, dán connection string và **thay `<db_password>` bằng mật khẩu thật, xoá luôn hai dấu ngoặc nhọn**:

```text
MONGODB_URI=mongodb+srv://<user>:<mật khẩu>@cluster0.xxxxx.mongodb.net/?appName=Cluster0
DB_NAME=AppHocTiengNhat
```

Không thêm tên database vào path của URI — code chọn database qua `DB_NAME` (`src/config/database.js`). Mật khẩu chứa `@ : / ? # %` phải percent-encode (`@` thành `%40`). Nhớ thêm IP hiện tại vào **Atlas → Network Access**.

`.env` không bao giờ được commit; `.env.example` chỉ chứa placeholder.

### 3. Nạp dữ liệu mẫu

Chạy theo **đúng thứ tự phụ thuộc** — `seed-vocabulary` yêu cầu đã có bài học, nên `seed-lessons` phải chạy trước, nếu không nó dừng với thông báo "Chưa có bài học nào".

```powershell
node scripts/seed-lessons.js
node scripts/seed-vocabulary.js
node scripts/seed-kanji.js
node scripts/seed-grammar.js
node scripts/sync-lesson-relations.js
node scripts/seedExercises.js
node scripts/seed-jlpt.js
node scripts/seedAchievements.js
```

`scripts/seed-news.js` không chạy độc lập được vì nó chỉ export một hàm và không tự mở kết nối. Gọi qua wrapper một dòng:

```powershell
node --input-type=module -e "import mongoose from 'mongoose'; import dotenv from 'dotenv'; dotenv.config(); await mongoose.connect(process.env.MONGODB_URI, { dbName: process.env.DB_NAME }); const seed = (await import('./scripts/seed-news.js')).default; await seed(); await mongoose.connection.close();"
```

MongoDB tạo database **lười** — nó chỉ xuất hiện sau khi seeder đầu tiên ghi document, nên đừng lo khi Atlas chưa thấy database ngay sau bước 2.

### 4. Chạy backend

```powershell
npm run dev      # nodemon, tự reload
npm start        # chạy thường
```

API lắng nghe tại `http://localhost:3000`. Endpoint `/` trả metadata và danh sách nhóm API; project không có `/health` riêng.

### 5. Tạo tài khoản và test API

Không seeder nào tạo user. Dùng Postman **bản desktop** — bản web tại `web.postman.co` không gọi được `localhost` trừ khi đã cài Postman Desktop Agent.

| Thành phần | Giá trị |
| --- | --- |
| Method | `POST` |
| URL | `http://localhost:3000/api/users/register` |
| Body | chọn **raw**, đổi dropdown `Text` sang **JSON** |

```json
{
  "username": "admin",
  "hoTen": "Administrator",
  "password": "<mật khẩu ít nhất 8 ký tự>",
  "email": "admin@example.com",
  "trinhDo": "N5"
}
```

`username`, `hoTen`, `password`, `email` bắt buộc; `trinhDo` mặc định `N5`. Kết quả đúng là `201 Created`.

Lỗi thường gặp: quên đổi dropdown sang `JSON` khiến Express không parse được body và trả `400 Vui lòng nhập đầy đủ thông tin bắt buộc`; mật khẩu dưới 8 ký tự trả `400`; trùng `username` hoặc `email` trả `409`.

**Gọi endpoint cần đăng nhập:** `POST /api/users/login` với `{"username": "...", "password": "..."}` trả về `token`. Trong Postman mở tab **Authorization** → Type **Bearer Token** → dán token vào. Middleware đọc header `Authorization` theo dạng `Bearer <token>`, nên nếu tự gõ tay ở tab Headers mà thiếu tiền tố `Bearer` phía trước sẽ bị `401`. Kiểm tra bằng `GET /api/users/me`.

`login`, `forgot-password` và `reset-password` mỗi endpoint có hạn mức **riêng**
20 request trong 15 phút, tính theo IP. Hạn mức gắn với nghiệp vụ chứ không gắn với
đường dẫn, nên đổi hoa/thường (`/Login`) hay thêm dấu `/` cuối không mở thêm lượt thử.

Đổi mật khẩu và đặt lại mật khẩu đều thu hồi mọi access token đã phát cho tài khoản đó:
token cũ trả `401` ngay lần gọi tiếp theo, kể cả khi chưa hết hạn.

### 6. Test chức năng admin

Hệ thống có hai vai trò `user` và `admin`. `POST /api/users/register` **luôn** gán `VaiTro: 'user'`, trong khi endpoint tạo user dành cho admin lại đòi sẵn một admin — nên admin đầu tiên luôn phải tạo bằng cách khác. Hai cách, phục vụ hai mục đích khác nhau:

**Cách 1 — nâng quyền một tài khoản thật.** Dùng khi cần test luồng đầy đủ: đăng nhập, token, phân quyền và dữ liệu gắn với người dùng.

```powershell
node scripts/make-admin.js admin      # tham số là TenDangNhap đã đăng ký
```

Script không làm gì nếu tài khoản đã là admin, và báo lỗi kèm danh sách user hiện có nếu gõ sai tên. Tương đương thủ công: Atlas → Data Explorer → collection `users` → sửa `VaiTro` thành `"admin"` → Update. Chỉ `VaiTro` có tác dụng; controller có ghi thêm field `role` nhưng schema `User` không khai báo nên Mongoose bỏ qua field đó.

**Cách 2 — bật `BYPASS_AUTH=true`** trong `.env` rồi khởi động lại backend. Mọi request được gán sẵn một admin giả, không cần đăng nhập và không cần gửi token. Hai giới hạn phải biết trước khi dùng:

- User giả có `_id` cố định `6925c1bc5b05cf681d547032` và **không tồn tại trong database**. Mọi endpoint đọc dữ liệu theo người dùng hiện tại — profile, tiến độ học, streak, sổ tay, nhóm học — sẽ trả về rỗng hoặc `404`. Cách này chỉ hợp để test CRUD nội dung, không kiểm chứng được luồng cá nhân hoá.
- `validateEnvironment()` chặn `BYPASS_AUTH=true` khi `NODE_ENV=production`. **Luôn đặt lại `false` trước khi demo**, nếu không toàn bộ xác thực bị vô hiệu hoá.

### 7. Nhóm học mẫu

Chạy sau khi đã có ít nhất một user, vì script gắn user thật làm thành viên:

```powershell
node scripts/seed-study-groups.js
```

Script idempotent — chạy lại chỉ báo bỏ qua nhóm đã tồn tại, không nhân bản dữ liệu.

### 8. Chạy Flutter

```powershell
cd FrontEnd
flutter pub get
flutter run
```

Network client mặc định dùng `http://localhost:3000/api` trên web và `http://10.0.2.2:3000/api` trên Android emulator. Chạy trên thiết bị thật thì **không sửa source**, truyền URL lúc build hoặc run:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api
flutter build web --dart-define=API_BASE_URL=https://api.example.com/api
```

Ứng dụng có cache ngoại tuyến cho bài học, từ vựng, Kanji, ngữ pháp, bài tập và tin tức. Cache chỉ dùng làm dự phòng khi người dùng bật chế độ ngoại tuyến **và** request mạng thất bại.

## Tài khoản demo

**Repo không kèm tài khoản mẫu, và đây là chủ ý.** Mật khẩu ghi trong một repo công khai nghĩa là bất kỳ ai clone cũng đăng nhập được vào database của người đã deploy. Mỗi người tự tạo tài khoản theo bước 5, rồi tự nâng quyền admin theo bước 6.

## Biến môi trường

Nguồn đầy đủ: `BackEnd/.env.example`.

### Bắt buộc — app từ chối khởi động nếu sai

`validateEnvironment()` trong `src/config/env.js` chạy ngay khi `server.js` khởi động và ném lỗi trước khi mở cổng:

| Biến | Ràng buộc |
| --- | --- |
| `MONGODB_URI` | Không được rỗng |
| `JWT_SECRET` | **Tối thiểu 32 ký tự** |
| `BYPASS_AUTH` | Không được `true` khi `NODE_ENV=production` |
| `PORT` | Số nguyên trong khoảng 1–65535 |

### Các biến còn lại

| Nhóm | Biến |
| --- | --- |
| App | `DB_NAME` · `NODE_ENV` · `CORS_ORIGINS` |
| Email khôi phục mật khẩu | `EMAIL_USER` · `EMAIL_PASSWORD` (Gmail app password) |
| Frontend | `FRONTEND_URL` — gốc của link trong email đặt lại mật khẩu |

Link khôi phục mật khẩu được dựng thành `<FRONTEND_URL>/#/reset-password?token=...`.
Dấu `#` là bắt buộc: Flutter Web đang dùng hash routing, nên URL thiếu `#` sẽ được
trình duyệt hỏi thẳng web server và không tới được màn đặt lại mật khẩu. `FRONTEND_URL`
phải trỏ tới nơi bản web thật sự chạy (`flutter build web` rồi phục vụ `build/web`), và
`CORS_ORIGINS` phải chứa đúng origin đó thì trang web mới gọi được API.

Không commit `.env`. Nếu secret từng bị lộ (commit nhầm, ảnh chụp màn hình), **xoay khoá chứ đừng chỉ xoá file** — `JWT_SECRET` bị lộ nghĩa là bất kỳ ai cũng tự ký được token admin.

## Tính năng

Trạng thái phản ánh đúng repo tại thời điểm hiện tại, không phải kế hoạch.

| Nhóm | Trạng thái |
| --- | --- |
| Xác thực, phân quyền, hồ sơ | ✅ Chạy được |
| Bài học, từ vựng, Kanji, ngữ pháp | ✅ Chạy được |
| Bài tập và chấm điểm | ✅ Chạy được, có test scoring |
| JLPT — làm đề và chấm | ✅ Chạy được |
| Quản trị nội dung, import/export CSV–Excel | ✅ Chạy được |
| Cache ngoại tuyến | ✅ Chạy được |
| Streak, achievement, XP | ✅ Chạy được |
| SRS, lịch sử học, lịch sử thi JLPT, tìm kiếm | 🔧 Đang sửa trong Giai đoạn 2 |
| Thông báo, quản trị tin tức | 🔧 Ngoài phạm vi Giai đoạn 2 |
| Luyện nói cùng AI | 📋 Mới có kế hoạch, **chưa viết dòng code nào** |
| Nhóm học | ❄️ Chỉ xem danh sách và chi tiết |
| Chat nhóm | ❄️ UI đã gỡ khỏi client; route và dữ liệu backend giữ nguyên |

### Về nhóm 🔧 — quan trọng nếu bạn định sửa code

Một số controller đang query **field không tồn tại trong model**. Mongoose bỏ qua field lạ nên không có lỗi nào hiện ra; tính năng chỉ đơn giản là không chạy. Ảnh hưởng `srs-progress`, `notification`, `progress` (phần lịch sử học), `news` (phần quản trị) và `jlpt` (phần lịch sử thi).

**Trước khi sửa bất kỳ controller nào, đối chiếu tên trường với model trong `BackEnd/model/`.** Chẩn đoán chi tiết và cách sửa nằm ở [phase-2-plan.md](docs/architecture/phase-2-plan.md).

### Về nhóm ❄️

Chat nhóm bị đóng băng có chủ đích: một tính năng xã hội cần nhiều người dùng đồng thời mới có ý nghĩa, trong khi đồ án chỉ có vài tài khoản — nên nó không nằm trong tiêu chí nghiệm thu và đã được gỡ khỏi luồng demo. Backend, route và dữ liệu vẫn nguyên vẹn, nên mở lại là viết lại UI chứ không phải dựng lại API. Điều kiện mở lại ghi ở [out-of-scope.md](docs/architecture/out-of-scope.md).

## Kiểm thử

| Bộ test | Số lượng | Chạy bằng |
| --- | --- | --- |
| Backend | 63 test, 10 file | `cd BackEnd; npm test` |
| Flutter | 25 test, 6 file | `cd FrontEnd; flutter test` |
| Analyzer | gate 0 error/warning/info | `cd FrontEnd; dart analyze` |

```powershell
cd BackEnd;  npm test
cd FrontEnd; dart analyze
cd FrontEnd; flutter test
```

Backend test gồm smoke test Express, route contract (khoá sha256), model contract, scoring JLPT và bài tập, lịch SRS, import từ vựng. **Không test nào đụng MongoDB hay gọi API bên ngoài** — service nhận repository giả qua tham số.

CI chạy đúng ba lệnh trên (`.github/workflows/ci.yml`), hai job Node và Flutter song song, trên mọi push và pull request vào `main`.

Build bản trình diễn web:

```powershell
cd FrontEnd
flutter build web --no-pub
```

Build Android cần Android SDK và release keystore trên máy build; mẫu cấu hình ký ở `FrontEnd/android/key.properties.example`.

Báo cáo kiểm thử có ngày kiểm chứng: [TEST_REPORT.md](docs/testing/TEST_REPORT.md).

## Deploy

**Chưa có pipeline deploy.** GitHub Actions hiện chỉ đóng vai cổng chặn chất lượng — chạy test và analyzer, không build image và không đẩy lên đâu cả.

Deploy backend, deploy Flutter Web, refresh token, index MongoDB cho truy vấn nóng và siết giới hạn upload nằm ở Giai đoạn 4 của [lộ trình](docs/architecture/redesign-roadmap.md). Ghi rõ ở đây để không ai nhìn badge CI xanh rồi tưởng đã có CD.

## Cấu trúc thư mục

```text
BackEnd/
├── src/
│   ├── app.js              Express composition, middleware, đăng ký route
│   ├── server.js           validateEnvironment · kết nối DB · listen · shutdown
│   ├── config/             env.js (settings + validator) · database.js
│   ├── middleware/         auth · upload · security (rate limit) · error
│   ├── modules/            21 domain: vocabulary (bản mẫu 4 tầng) · srs · lessons
│   │                       kanji · grammar · exercise · jlpt · users · admin...
│   └── shared/http/        api-error · async-handler · respond · validate (zod)
├── model/                  23 Mongoose model dùng chéo nhiều domain
├── scripts/                seed-* · make-admin · sync-lesson-relations
└── tests/                  10 file, 63 test — repository/service giả, không cần DB

FrontEnd/
├── lib/
│   ├── app/                App widget · provider registration · theme token · i18n
│   ├── core/               ApiClient · offline cache · ViewState · responsive
│   ├── features/           23 feature tự chứa: screens/ widgets/ providers/
│   │                       services/ models/ — vocabulary là bản mẫu
│   └── shared/             widget và model thực sự dùng ở nhiều feature
└── test/                   6 file, 25 test

docs/
├── architecture/           conventions · project-structure · roadmap · phase-2-plan
├── api/                    tổng quan REST API
├── presentation/           kịch bản demo và bảo vệ
└── testing/                báo cáo kiểm thử
```

## Tài liệu

| Tài liệu | Nội dung |
| --- | --- |
| [CLAUDE.md](CLAUDE.md) | Nguyên tắc dự án, khuôn mẫu code, các bẫy đã biết trong repo |
| [conventions.md](docs/architecture/conventions.md) | Quy ước code — khuôn mẫu bắt buộc trước mọi thay đổi |
| [project-structure.md](docs/architecture/project-structure.md) | Quy tắc đặt file và hướng phụ thuộc |
| [redesign-roadmap.md](docs/architecture/redesign-roadmap.md) | Lộ trình 14 tuần, baseline đo được, phạm vi từng giai đoạn |
| [phase-2-plan.md](docs/architecture/phase-2-plan.md) | Việc đang làm: khôi phục vòng lặp học và luyện nói cùng AI |
| [out-of-scope.md](docs/architecture/out-of-scope.md) | Quyết định tạm hoãn và điều kiện mở lại |
| [system-overview.md](docs/architecture/system-overview.md) | Sơ đồ kiến trúc hệ thống |
| [data-model.md](docs/architecture/data-model.md) | Sơ đồ quan hệ dữ liệu |
| [API_OVERVIEW.md](docs/api/API_OVERVIEW.md) | Tổng quan REST API |
| [DEMO_SCRIPT.md](docs/presentation/DEMO_SCRIPT.md) | Kịch bản demo và câu hỏi phản biện |
| [TEST_REPORT.md](docs/testing/TEST_REPORT.md) | Báo cáo kiểm thử |
| [TEST_STREAK.md](docs/testing/TEST_STREAK.md) | Kịch bản kiểm thử streak thủ công |
| [docs/README.md](docs/README.md) | Mục lục tài liệu |
