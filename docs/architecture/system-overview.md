# Sơ đồ kiến trúc hệ thống

## Thành phần chính

```mermaid
flowchart LR
    U[Người học / Quản trị viên]
    F[Flutter application]
    S[Secure token storage]
    C[Offline content cache]
    A[Express REST API]
    M[(MongoDB)]
    E[Email provider]
    FS[Upload storage]

    U --> F
    F -->|HTTPS + Bearer JWT| A
    F <--> S
    F <--> C
    A --> M
    A -->|Reset password| E
    A --> FS
```

Flutter tổ chức theo feature và chỉ truy cập HTTP qua `ApiClient`. Backend mount route theo domain; middleware xác thực/phân quyền chạy trước controller. Controller dùng Mongoose model để đọc/ghi MongoDB.

## Luồng xác thực

```mermaid
sequenceDiagram
    actor User
    participant App as Flutter
    participant API as Express API
    participant DB as MongoDB

    User->>App: Nhập tài khoản/mật khẩu
    App->>API: POST /api/users/login
    API->>DB: Kiểm tra tài khoản và bcrypt hash
    DB-->>API: User hợp lệ
    API-->>App: Access JWT + profile
    App->>App: Lưu JWT trong secure storage
    App->>API: Request + Authorization: Bearer JWT
    API-->>App: Dữ liệu theo quyền user/admin
```

## Luồng học bài và làm bài tập

```mermaid
sequenceDiagram
    actor User
    participant App as Flutter
    participant API as Express API
    participant DB as MongoDB

    User->>App: Chọn bài học
    App->>API: GET /api/lesson/:id
    API->>DB: Load lesson + vocabulary + grammar + kanji
    API-->>App: LessonDetail
    App->>API: Cập nhật LessonProgress
    User->>App: Làm bài tập
    App->>API: GET /api/exercise/lesson/:lessonId
    API-->>App: Danh sách bài tập đúng bài học
    App->>API: POST /api/exercise/submit/:id
    API->>DB: Chấm điểm, lưu kết quả, cập nhật XP/streak
    API-->>App: Điểm và trạng thái đạt
```

## Ranh giới bảo mật

- Access token lưu bằng secure storage; cache ngoại tuyến không lưu token.
- Route quản trị dùng `authenticateAdmin`.
- Login, forgot/reset password có rate limit.
- Upload giới hạn kích thước và kiểm tra MIME + phần mở rộng.
- Production dùng CORS whitelist và không trả stack/error nội bộ.
