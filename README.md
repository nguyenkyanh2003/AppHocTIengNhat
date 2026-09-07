# AppHocTiengNhat

Ứng dụng học tiếng Nhật gồm Flutter client và REST API Node.js/Express. Các chức năng hiện có bao gồm bài học, từ vựng, kanji, ngữ pháp, bài tập, JLPT, SRS, streak/achievement, nhóm học, chat, tin tức, sổ tay, thông báo và quản trị.

## Kiến trúc tổng quan

```text
AppHocTiengNhat/
├── BackEnd/                 # Express API + MongoDB/Mongoose
│   ├── src/
│   │   ├── app.js           # Express composition, middleware, route registration
│   │   ├── server.js        # DB connection, listen, shutdown, process handlers
│   │   ├── config/
│   │   ├── middleware/
│   │   ├── modules/         # Domain-first routes/controllers/services
│   │   └── shared/
│   ├── model/               # Mongoose models dùng chéo nhiều domain
│   ├── scripts/
│   └── tests/
├── FrontEnd/                # Flutter application
│   ├── lib/
│   │   ├── app/             # App widget, providers, router, theme, localization
│   │   ├── core/            # Network/config/layout infrastructure
│   │   ├── features/        # Screens/state/services/models theo feature
│   │   └── shared/          # Thành phần thực sự dùng chung
│   └── test/
└── docs/
```

Quy tắc đặt file và dependency được mô tả chi tiết tại [docs/architecture/project-structure.md](docs/architecture/project-structure.md).

## Yêu cầu

- Node.js 20+ và npm. Refactor này được kiểm tra với Node.js 22.15.0/npm 10.9.2.
- MongoDB local hoặc MongoDB Atlas.
- Flutter stable tương thích Dart `>=3.0.0 <4.0.0`. Refactor này được kiểm tra với Flutter 3.29.3/Dart 3.7.2.
- Android Studio, Xcode hoặc trình duyệt tùy target Flutter cần chạy.

## Cài đặt backend

```powershell
cd BackEnd
npm ci
Copy-Item .env.example .env
```

Cập nhật `BackEnd/.env` bằng cấu hình riêng của môi trường. Các biến được hỗ trợ:

| Biến | Mục đích |
| --- | --- |
| `MONGODB_URI` | MongoDB connection string |
| `DB_NAME` | Tên database |
| `PORT` | Cổng HTTP của backend |
| `NODE_ENV` | Môi trường chạy |
| `BYPASS_AUTH` | Bỏ qua auth khi phát triển; không bật ở production |
| `JWT_SECRET` | Khóa ký JWT đủ dài và ngẫu nhiên |
| `EMAIL_USER` | Tài khoản gửi email reset mật khẩu |
| `EMAIL_PASSWORD` | App password/credential của email |
| `FRONTEND_URL` | URL frontend được dùng trong luồng email |
| `CORS_ORIGINS` | Danh sách origin được phép, phân tách bằng dấu phẩy |

Không commit `.env`. File `.env.example` chỉ chứa placeholder an toàn.

Chạy backend:

```powershell
# Development, tự reload
npm run dev

# Hoặc chạy bình thường
npm start
```

API mặc định lắng nghe tại `http://localhost:3000`. Endpoint `/` trả metadata và danh sách nhóm API; project hiện không có endpoint `/health` riêng.

## Cài đặt Flutter

```powershell
cd FrontEnd
flutter pub get
flutter run
```

Network client hiện dùng:

- `http://localhost:3000/api` trên web;
- `http://10.0.2.2:3000/api` trên Android emulator.

Khi chạy trên thiết bị thật hoặc môi trường khác, không sửa source. Truyền URL API lúc build/run:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api
flutter build web --dart-define=API_BASE_URL=https://api.example.com/api
```

Ứng dụng có cache ngoại tuyến cho bài học, từ vựng, Kanji, ngữ pháp, bài tập và tin tức. Cache chỉ được dùng làm dự phòng khi người dùng bật chế độ ngoại tuyến và request mạng thất bại.

## Kiểm tra

Backend:

```powershell
cd BackEnd
npm test
```

Bộ test backend gồm smoke test Express, API route contract, model contract, scoring JLPT/exercise và chuẩn hóa dữ liệu Kanji.

Flutter:

```powershell
cd FrontEnd
dart analyze
flutter test
```

Quality gate hiện tại yêu cầu analyzer không có error, warning hoặc info. Kết quả kiểm chứng gần nhất: 12 backend test và 8 Flutter test đều passed; Flutter Web build thành công. Xem báo cáo có ngày kiểm chứng tại [docs/testing/TEST_REPORT.md](docs/testing/TEST_REPORT.md).

Build bản trình diễn web:

```powershell
cd FrontEnd
flutter build web --no-pub
```

Build Android cần Android SDK và release keystore trên máy build. Mẫu cấu hình ký nằm tại `FrontEnd/android/key.properties.example`.

## Development workflow

1. Đặt code mới vào đúng domain trong `BackEnd/src/modules/<domain>/` hoặc `FrontEnd/lib/features/<feature>/`.
2. Không đưa business logic lớn vào Express route; route chỉ khai báo path, middleware và controller binding.
3. Chỉ tạo service/repository khi có responsibility thực tế. Không tạo layer rỗng để đủ pattern.
4. Không đưa code feature-specific vào `core/` hoặc `shared/`.
5. Nếu thêm/sửa public API route hoặc Flutter navigation, cập nhật contract test có chủ đích.
6. Chạy test/analyzer của phần bị ảnh hưởng trước khi mở rộng thay đổi.
7. Không commit `.env`, `node_modules`, build output, log hay IDE state.

## Tài liệu

- [Chỉ dẫn cấu trúc project](docs/architecture/project-structure.md)
- [Lộ trình thiết kế lại](docs/architecture/redesign-roadmap.md)
- [Quy ước code](docs/architecture/conventions.md)
- [Kế hoạch giai đoạn 2 và luyện nói cùng AI](docs/architecture/phase-2-plan.md)
- [Phạm vi chưa làm trong giai đoạn 2](docs/architecture/out-of-scope.md)
- [Sơ đồ kiến trúc hệ thống](docs/architecture/system-overview.md)
- [Sơ đồ dữ liệu](docs/architecture/data-model.md)
- [Tổng quan REST API](docs/api/API_OVERVIEW.md)
- [Kịch bản demo/bảo vệ](docs/presentation/DEMO_SCRIPT.md)
- [Báo cáo kiểm thử](docs/testing/TEST_REPORT.md)
- [Mục lục tài liệu](docs/README.md)
- [Kiểm thử streak thủ công](docs/testing/TEST_STREAK.md)
