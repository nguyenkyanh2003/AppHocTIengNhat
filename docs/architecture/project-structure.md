# Cấu trúc project

## Mục tiêu

Kiến trúc ưu tiên cohesion cao, coupling thấp và ít ceremony. Cây thư mục phải giúp developer xác định nơi đặt code mới, nhưng việc chia layer không được làm thay đổi API, schema MongoDB, navigation hoặc hành vi người dùng.

## Root repository

```text
AppHocTiengNhat/
├── BackEnd/       # API và runtime server
├── FrontEnd/      # Flutter client
├── docs/          # Tài liệu theo mục đích
├── .gitignore
└── README.md
```

Giữ nguyên casing `BackEnd/` và `FrontEnd/` trong đợt kiến trúc này. Nếu muốn đổi thành lowercase, thực hiện ở thay đổi riêng để tránh lỗi case-sensitive trên Git/Linux/CI.

## Backend

### Cây thư mục

```text
BackEnd/
├── src/
│   ├── app.js
│   ├── server.js
│   ├── config/
│   │   ├── database.js
│   │   └── env.js
│   ├── middleware/
│   ├── modules/
│   │   └── <domain>/
│   │       ├── <domain>.routes.js
│   │       ├── <domain>.controller.js
│   │       └── <focused-use-case>.service.js  # chỉ khi cần
│   └── shared/
│       └── utils/
├── model/
├── scripts/
├── tests/
├── uploads/
├── package.json
└── .env.example
```

### Trách nhiệm các layer

- `src/app.js`: tạo Express app, cài middleware chung, mount route, 404 và error handler. File này không mở cổng hoặc kết nối database, nên có thể import độc lập trong test.
- `src/server.js`: start HTTP server, kết nối/ngắt MongoDB, seed dữ liệu cần thiết và xử lý signal/process error.
- `src/config/`: đọc cấu hình môi trường và quản lý kết nối database.
- `src/middleware/`: concern HTTP dùng chung như auth, upload, timezone và error handling.
- `src/modules/<domain>/`: code HTTP theo domain. Route phải mỏng; controller nhận `req/res` và giữ response contract.
- `src/shared/`: utility thực sự dùng ở nhiều module và không thuộc một domain cụ thể.
- `model/`: Mongoose models hiện dùng chéo nhiều domain. Giữ tập trung để tránh churn/circular dependency; chỉ colocate model sau khi dependency audit chứng minh nó thuộc duy nhất một module.
- `scripts/`: seed/import/maintenance scripts có thể chạy chủ động, không được import ngầm vào request path nếu không cần.
- `tests/`: smoke, contract và unit tests.

### Dependency direction

```text
server -> app -> routes -> controllers -> focused services/models
   └------> config/database
middleware -----------------------------> shared utilities/models khi cần
```

`routes` không thực hiện DB query hoặc scoring. Service thuần không phụ thuộc Express `req/res`. Controller hiện có thể gọi Mongoose model trực tiếp nếu query còn nhỏ và không tái sử dụng; tạo repository khi DB concern đủ lớn.

### Khi nào tạo service hoặc repository

Tạo service khi có một trong các dấu hiệu:

- rule/scoring/workflow cần unit test độc lập;
- cùng use case được gọi từ nhiều controller;
- orchestration dài không thuộc HTTP mapping.

Tạo repository khi:

- query phức tạp hoặc lặp lại;
- transaction/data access cần mock riêng;
- module có đủ DB concern để controller/service trở nên khó đọc.

Không tạo file service/repository/interface/factory rỗng chỉ để đạt một sơ đồ kiến trúc.

### Thêm backend feature mới

Ví dụ thêm domain `reviews`:

1. Tạo `src/modules/reviews/review.routes.js` và `review.controller.js`.
2. Chỉ thêm `review.service.js` nếu có rule/workflow thực tế.
3. Mount router trong `src/app.js` mà không đổi prefix API ngoài chủ đích.
4. Thêm route vào contract test và unit test cho pure rule.
5. Chạy `npm test` và syntax check trước khi sang module khác.

## Flutter

### Cây thư mục

```text
FrontEnd/lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── app_providers.dart
│   ├── localization/
│   ├── router/
│   ├── state/
│   └── theme/
├── core/
│   ├── config/
│   ├── layout/
│   └── network/
├── features/
│   └── <feature>/
│       ├── screens/
│       ├── widgets/
│       ├── providers/
│       ├── services/
│       └── models/
└── shared/
    ├── models/
    └── widgets/
```

Feature chỉ có các thư mục thực sự cần. Ví dụ feature UI-only không phải tạo `models/`, `providers/` hay `services/` rỗng.

### Vai trò từng khu vực

- `main.dart`: bootstrap tối thiểu (`ensureInitialized`, khởi tạo client, `runApp`).
- `app/`: composition root, router/navigation contract, global provider registration, theme, localization và coordinator ở cấp ứng dụng.
- `core/`: hạ tầng không mang ý nghĩa domain như HTTP client, runtime config và responsive primitives. `core` không được import feature.
- `features/<feature>/`: toàn bộ screen, widget, provider, service và model chỉ phục vụ feature đó.
- `shared/`: model/widget dùng thật ở nhiều feature hoặc generic theo bản chất. `shared` không phải nơi tạm chứa file chưa biết đặt đâu.

`shared/models/user.dart` là shared vì cả auth và profile dùng. Audio recorder nằm trong `study_groups` vì hiện chỉ chat/group dùng. News carousel nằm trong `news` dù được home render, vì nó sở hữu state/model/navigation của news.

### Dependency direction

```text
main -> app composition/router -> features
features -----------------------> core
features -----------------------> shared -> core
features -> app/theme/localization (UI infrastructure)
app/state -> feature providers (application-level orchestration có chủ đích)
```

Cross-feature import chỉ dùng khi một feature thật sự compose màn hình hoặc type công khai của feature khác, ví dụ home điều hướng đến các feature hoặc flashcard study nhận vocabulary. Không import private implementation chỉ để tái sử dụng một helper nhỏ; nếu helper thực sự generic và có nhiều consumer, chuyển nó vào `shared` hoặc `core` có chủ đích.

### Network layer

`core/network/api_client.dart` sở hữu base URL, auth header và HTTP behavior dùng chung. Endpoint/domain method vẫn ở `features/<feature>/services/`; không gom toàn bộ API vào một service khổng lồ.

### State và navigation

- Provider vẫn là state-management package hiện tại.
- Global provider registration nằm tại `app/app_providers.dart`.
- Named và generated routes nằm tại `app/router/app_router.dart`.
- Khi đổi public route, cập nhật `test/navigation_contract_test.dart` trong cùng thay đổi.

### Thêm Flutter feature mới

Ví dụ thêm feature `reviews`:

1. Tạo `features/reviews/screens/` và screen đầu tiên.
2. Thêm `providers/`, `services/`, `models/` chỉ khi feature có state/API/data type riêng.
3. Dùng `core/network/ApiClient` trong feature service; không đặt endpoint review vào core.
4. Nếu provider phải sống toàn app, đăng ký trong `app/app_providers.dart`.
5. Nếu có route public, đăng ký trong `app/router/app_router.dart` và cập nhật contract test.
6. Chạy `dart analyze` và `flutter test`; analyzer phải không có issue.

## Tài liệu và file vận hành

- Hướng dẫn chính: root `README.md`.
- Quyết định/cấu trúc: `docs/architecture/`.
- Quy trình phát triển: `docs/development/`.
- Kịch bản test: `docs/testing/`.
- Ghi chú chẩn đoán: `docs/troubleshooting/`.
- Tài liệu lịch sử/obsolete cần giữ: `docs/archive/`, kèm ghi chú trạng thái.

Secret phải nằm trong file `.env` local và không được commit. Build output, dependency folder, logs và IDE state cũng không thuộc source control.
