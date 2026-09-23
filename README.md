<div align="center">

# AppHocTiengNhat

**Ứng dụng học tiếng Nhật theo tình huống — học bài, luyện từ, ôn thẻ và theo dõi tiến độ trong một vòng lặp khép kín.**

[![CI](https://github.com/nguyenkyanh2003/AppHocTIengNhat/actions/workflows/ci.yml/badge.svg)](https://github.com/nguyenkyanh2003/AppHocTIengNhat/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.29-02569B?logo=flutter&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-22-339933?logo=nodedotjs&logoColor=white)
![Express](https://img.shields.io/badge/Express-5-000000?logo=express&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-8-47A248?logo=mongodb&logoColor=white)

[Tính năng](#tính-năng) · [Bắt đầu](#bắt-đầu) · [Tài khoản demo](#tài-khoản-demo) · [Kiểm thử](#kiểm-thử) · [Tài liệu](#tài-liệu)

</div>

---

Người học tiếng Nhật thường không thiếu tài liệu, mà thiếu một hệ thống: học xong không biết
khi nào nên ôn lại, ôn lại thì không biết ôn gì, và không thấy mình tiến bộ ở đâu.
AppHocTiengNhat dựng lại chặng đường đó thành một vòng lặp — **học bài theo tình huống → làm
bài tập → ôn thẻ đến hạn → nhìn thấy tiến độ và chuỗi ngày học** — thay vì làm thêm một kho
nội dung để tra cứu.

Ứng dụng gồm một client Flutter (Web + Android) và một REST API Node.js/Express chạy trên
MongoDB.

## Tính năng

- **Học theo tình huống** — 20 bài hội thoại đời thường: tự giới thiệu, đi siêu thị, đi tàu,
  đi khám bệnh, phỏng vấn làm thêm, sơ tán khi động đất… Mỗi bài gồm hội thoại song ngữ, từ
  vựng, ngữ pháp và Kanji xuất hiện trong bài.
- **Từ vựng theo bộ** — từ được chia thành bộ nhỏ theo chủ đề và độ khó, kèm cách đọc, ví dụ,
  ngữ cảnh dùng và phân tích chữ Hán; đánh dấu đã học theo từng từ hoặc cả bộ.
- **Kanji và ngữ pháp** — tra cứu theo cấp N5–N1 với âm On/Kun, bộ thủ, mẫu câu và ví dụ.
- **Bài tập và chấm điểm tự động** — trắc nghiệm, điền từ, ghép cặp; chấm ngay sau khi nộp
  kèm giải thích từng câu.
- **Luyện đề JLPT** — làm đề theo cấu trúc đề thật, tính điểm theo từng phần và lưu kết quả.
- **Flashcard và ôn tập ngắt quãng** — bộ thẻ tự tạo hoặc sinh từ bài học, lịch ôn theo thuật
  toán ngắt quãng để thẻ khó quay lại sớm hơn thẻ đã nhớ.
- **Chuỗi ngày học, huy hiệu, bảng xếp hạng** — mọi hoạt động học đều đi qua một cổng ghi duy
  nhất, nên streak và điểm kinh nghiệm luôn khớp với việc đã làm.
- **Tiến độ và thống kê** — biểu đồ theo ngày, theo kỹ năng và theo cấp độ, kèm mục tiêu cá nhân.
- **Sổ tay và tìm kiếm** — ghi chú riêng cho từ, Kanji hay mẫu ngữ pháp; tìm kiếm chung trên
  toàn bộ nội dung.
- **Chế độ ngoại tuyến** — bài học, từ vựng, Kanji, ngữ pháp, bài tập và tin tức được cache lại
  để dùng tiếp khi mất mạng.
- **Trang quản trị** — quản lý nội dung và người dùng, import/export Excel–CSV, xem báo cáo và
  số liệu sử dụng.

## Kiến trúc

```text
┌─────────────────── Flutter client (FrontEnd/) ────────────────────┐
│  screens/ ──► providers/ (ViewState) ──► services/ ──► ApiClient  │
│  Web · Android · cache ngoại tuyến                                │
└───────────────────────────────┬───────────────────────────────────┘
                                │  HTTP + JWT (Bearer)
                                ▼
┌─────────────────── Express API (BackEnd/src/) ────────────────────┐
│  routes ──► controller ──► service ──► repository ──► Mongoose    │
│     │           │             │            │                      │
│     │           │             │            └─ nơi duy nhất query  │
│     │           │             └─ rule nghiệp vụ, ném ApiError     │
│     │           └─ chỉ map HTTP, đọc req.valid                    │
│     └─ path + middleware (auth, validate zod, upload)             │
└───────────────────────────────┬───────────────────────────────────┘
                                ▼
                  ┌──────────────────────────┐
                  │  MongoDB — 25 collection │
                  └──────────────────────────┘
```

Backend chia bốn tầng, gồm 21 module domain và 260 route công khai. Mỗi endpoint khai báo
schema zod và controller chỉ đọc dữ liệu đã validate; lỗi nghiệp vụ ném `ApiError` và được gom
về một middleware duy nhất. Response theo một contract thống nhất: một tài nguyên trả
`{ data }`, danh sách trả `{ data, total }`, có phân trang trả
`{ data, page, limit, total, totalPages }`.

Frontend tổ chức theo feature: mỗi feature tự chứa `screens/`, `widgets/`, `providers/`,
`services/` và `models/`. Màu sắc, khoảng cách và bo góc lấy từ một bộ design token tập trung.

Chi tiết: [system-overview.md](docs/architecture/system-overview.md) ·
[data-model.md](docs/architecture/data-model.md) ·
[API_OVERVIEW.md](docs/api/API_OVERVIEW.md)

## Công nghệ

| Lớp | Công nghệ |
| --- | --- |
| Backend | Node.js 22 · Express 5 · ES Modules |
| Database | MongoDB (Atlas hoặc local) · Mongoose 8 |
| Xác thực | JWT · bcrypt · rate limit cho nhóm route auth |
| Validation | zod — schema theo domain + middleware `validate` |
| Frontend | Flutter 3.29 · Dart 3.7 · Provider · go_router |
| Tiện ích | ExcelJS/xlsx · Multer · Nodemailer · moment-timezone · fl_chart |
| Kiểm thử | `node --test` · `flutter test` · `dart analyze --fatal-infos` |
| CI | GitHub Actions — job Node và job Flutter chạy song song trên mỗi push/PR vào `main` |

## Bắt đầu

### Yêu cầu

- **Node.js 20+** và npm (kiểm chứng với Node.js 22.15.0 / npm 10.9.2)
- **MongoDB** — Atlas hoặc MongoDB Server chạy local
- **Flutter stable**, Dart `>=3.0.0 <4.0.0` (kiểm chứng với Flutter 3.29.3 / Dart 3.7.2)

### 1. Cài đặt backend

```powershell
git clone https://github.com/nguyenkyanh2003/AppHocTIengNhat.git
cd AppHocTIengNhat/BackEnd
npm ci
Copy-Item .env.example .env
```

### 2. Cấu hình `.env`

Điền tối thiểu `MONGODB_URI`, `DB_NAME` và `JWT_SECRET`. Sinh khoá ngẫu nhiên:

```powershell
node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"
```

Với MongoDB Atlas, dán connection string và thay `<db_password>` bằng mật khẩu thật, xoá luôn
hai dấu ngoặc nhọn. Không thêm tên database vào path của URI — code chọn database qua
`DB_NAME`. Mật khẩu chứa `@ : / ? # %` phải percent-encode. Nhớ thêm IP hiện tại vào
**Atlas → Network Access**.

### 3. Nạp dữ liệu mẫu

Chạy theo đúng thứ tự — bài học phải có trước vì từ vựng, Kanji và bài tập gắn vào bài:

```powershell
node scripts/seed-situational-lessons.js   # 20 bài theo tình huống + nội dung đi kèm
node scripts/seed-exercises.js             # 60 bài tập mẫu: nghĩa từ, cách đọc, hội thoại của 20 bài
node scripts/seed-kanji.js
node scripts/seed-grammar.js
node scripts/sync-lesson-relations.js
node scripts/seed-jlpt.js                  # đề luyện JLPT
node scripts/seedAchievements.js           # danh mục huy hiệu
node scripts/seed-demo.js --bulk=30        # tài khoản demo, lịch sử học 20 ngày, 4 bạn học, huy hiệu
node scripts/seed-study-groups.js          # tuỳ chọn, cần có user trước
```

Các seeder trên upsert theo khoá tự nhiên (tiêu đề bài, mặt chữ Kanji, tên huy hiệu...) nên
chạy lại không nhân bản dữ liệu và không đổi `_id` — tiến độ học, lịch ôn và lịch sử thi vẫn
trỏ đúng. Bản ghi đã có mà khác nội dung được báo là xung đột và giữ nguyên, trừ khi chạy lại
với `--overwrite`; thêm `--dry-run` để xem trước mà không ghi. Kho từ vựng lớn nhập bằng
`node scripts/import-vocabulary.js --file <csv|xlsx>`, cũng upsert theo `(word, hiragana)`.

MongoDB tạo database lười nên database chỉ xuất hiện sau khi seeder đầu tiên ghi document.

### Chuyển dữ liệu streak cũ

Database có dữ liệu từ trước đợt đổi đường ghi XP (2026-09-20) cần chép lịch sử cũ sang nhật
ký mới một lần. Thứ tự bắt buộc — migration từ chối ghi nếu chưa có bản sao lưu đã khôi phục thử:

```powershell
node scripts/audit-user-streak.js                    # chỉ đọc: số liệu và múi giờ gợi ý
node scripts/backup-collections.js                   # ra backups/<thời điểm>/
node scripts/restore-collections.js --dir backups/<thời điểm> --target-db AppHocTiengNhat_restore_check
node scripts/migrate-streak-legacy.js --legacy-tz Asia/Ho_Chi_Minh              # chạy thử
node scripts/migrate-streak-legacy.js --legacy-tz Asia/Ho_Chi_Minh --apply --backup backups/<thời điểm>   --drop-legacy-arrays --remove-orphans
```

Chỉ truyền `--legacy-tz` khi audit xác định được múi giờ; không có cờ này migration bỏ qua
phần ngày cũ thay vì đoán. Chạy lại an toàn, không bao giờ sửa `total_xp`. Database
`AppHocTiengNhat` đã được chuyển ngày 2026-09-23.

`node scripts/smoke-learning-loop.js` chạy thử vòng ôn SRS → XP → chuỗi ngày trên một database
riêng `<DB_NAME>_smoke` cùng cluster: transaction, hai lượt ôn đồng thời, rollback. Database đó
tự xoá sau khi chạy.

### 4. Chạy backend

```powershell
npm run dev      # nodemon, tự reload
npm start
```

API lắng nghe tại `http://localhost:3000`; endpoint `/` trả metadata và danh sách nhóm API.

### 5. Chạy ứng dụng

```powershell
cd ../FrontEnd
flutter pub get
flutter run
```

Client mặc định gọi `http://localhost:3000/api` trên web và `http://10.0.2.2:3000/api` trên
Android emulator. Chạy trên thiết bị thật thì truyền URL lúc build hoặc run thay vì sửa source:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api
flutter build web --dart-define=API_BASE_URL=https://api.example.com/api
```

## Tài khoản demo

`node scripts/seed-demo.js` tạo sẵn hai tài khoản kèm dữ liệu học mẫu: thẻ SRS đến hạn, lịch sử
học 20 ngày (chuỗi 13 ngày tới hôm qua — học một thẻ là lên 14 và mở huy hiệu), bài tập đã làm,
huy hiệu đã đạt, và bốn bạn học `demo_minhanh`, `demo_thulan`, `demo_quanghuy`, `demo_ducminh`
(mật khẩu `Demo123456`) để bảng xếp hạng có người:

| Vai trò | Tài khoản | Mật khẩu |
| --- | --- | --- |
| Học viên | `demo_hocvien` | `123456` |
| Quản trị | `demo_admin` | `DemoAdmin123!` |

Hai tài khoản này chỉ dành cho môi trường phát triển và demo local. Xoá chúng bằng
`node scripts/seed-demo.js --reset` trước khi đưa database lên môi trường công khai.

Nâng quyền admin cho một tài khoản tự đăng ký:

```powershell
node scripts/make-admin.js <TenDangNhap>
```

## Biến môi trường

Nguồn đầy đủ: `BackEnd/.env.example`.

### Bắt buộc

`validateEnvironment()` chạy lúc khởi động và dừng server trước khi mở cổng nếu giá trị sai:

| Biến | Ràng buộc |
| --- | --- |
| `MONGODB_URI` | Không được rỗng |
| `JWT_SECRET` | Tối thiểu 32 ký tự |
| `PORT` | Số nguyên 1–65535 |
| `BYPASS_AUTH` | Không được `true` khi `NODE_ENV=production` |

### Tuỳ chọn

| Nhóm | Biến |
| --- | --- |
| App | `DB_NAME` · `NODE_ENV` · `CORS_ORIGINS` |
| Email khôi phục mật khẩu | `EMAIL_USER` · `EMAIL_PASSWORD` (Gmail app password) |
| Frontend | `FRONTEND_URL` — gốc của link trong email đặt lại mật khẩu |

Link khôi phục mật khẩu được dựng thành `<FRONTEND_URL>/#/reset-password?token=...`. Dấu `#`
là bắt buộc vì Flutter Web dùng hash routing. `FRONTEND_URL` phải trỏ tới nơi bản web thật sự
chạy, và `CORS_ORIGINS` phải chứa đúng origin đó.

Không commit `.env`. Nếu secret từng bị lộ thì xoay khoá chứ đừng chỉ xoá file — `JWT_SECRET`
bị lộ nghĩa là bất kỳ ai cũng tự ký được token admin.

## Kiểm thử

```powershell
cd BackEnd;  npm test                    # node --test, không cần MongoDB
cd FrontEnd; dart analyze --fatal-infos
cd FrontEnd; flutter test
```

Test backend dùng repository và service giả truyền qua tham số, nên không test nào đụng
MongoDB hay gọi API bên ngoài. Bộ test bao gồm smoke test Express, contract 255 route khoá
bằng sha256, contract model, chấm điểm JLPT và bài tập, lịch ôn SRS, luật streak và import
từ vựng.

CI chạy đúng bộ lệnh trên, cộng thêm `flutter build web --release` và integration test điều
hướng chạy trong Chrome headless ([ci.yml](.github/workflows/ci.yml)).

Build bản phát hành:

```powershell
cd FrontEnd; flutter build web --release
cd FrontEnd; flutter build apk --release
```

Build Android cần Android SDK và release keystore; mẫu cấu hình ký ở
`FrontEnd/android/key.properties.example`.

## Cấu trúc thư mục

```text
BackEnd/
├── src/
│   ├── app.js              Express composition, middleware, đăng ký route
│   ├── server.js           validate env · kết nối DB · listen · shutdown
│   ├── config/             env.js · database.js
│   ├── middleware/         auth · upload · security (rate limit) · error
│   ├── modules/            21 domain: vocabulary · srs · lessons · kanji
│   │                       grammar · exercise · jlpt · users · streaks…
│   └── shared/http/        api-error · async-handler · respond · validate
├── model/                  25 Mongoose model
├── scripts/                seed-* · import-* · make-admin
└── tests/                  test đơn vị, không cần DB

FrontEnd/
├── lib/
│   ├── app/                App widget · router · theme token · i18n
│   ├── core/               ApiClient · offline cache · ViewState · responsive
│   ├── features/           24 feature tự chứa: screens/ widgets/ providers/
│   │                       services/ models/
│   └── shared/             widget dùng chung nhiều feature
├── test/                   widget và unit test
└── integration_test/       luồng điều hướng trên trình duyệt

docs/
├── architecture/           cấu trúc dự án, quy ước code, mô hình dữ liệu
├── api/                    tổng quan REST API
└── testing/                báo cáo kiểm thử
```

## Tài liệu

| Tài liệu | Nội dung |
| --- | --- |
| [system-overview.md](docs/architecture/system-overview.md) | Kiến trúc hệ thống và luồng dữ liệu |
| [project-structure.md](docs/architecture/project-structure.md) | Cấu trúc thư mục và quy tắc đặt file |
| [conventions.md](docs/architecture/conventions.md) | Quy ước code bắt buộc cho cả hai phía |
| [data-model.md](docs/architecture/data-model.md) | Mô hình dữ liệu và quan hệ giữa collection |
| [API_OVERVIEW.md](docs/api/API_OVERVIEW.md) | Nhóm endpoint, xác thực, response contract |
| [TEST_REPORT.md](docs/testing/TEST_REPORT.md) | Báo cáo kiểm thử |
