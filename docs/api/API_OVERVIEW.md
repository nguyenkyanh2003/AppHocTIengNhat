# Tổng quan REST API

Base URL mặc định: `http://localhost:3000/api`.

## Xác thực

- Route đăng nhập/đăng ký/reset mật khẩu không yêu cầu Bearer token.
- Route người dùng dùng `Authorization: Bearer <access-token>`.
- Route quản trị kiểm tra thêm vai trò admin.
- JSON request dùng `Content-Type: application/json`; upload dùng `multipart/form-data`.

## Nhóm endpoint chính

| Base path | Chức năng |
| --- | --- |
| `/users` | Đăng nhập, hồ sơ, đổi/reset mật khẩu, quản trị user |
| `/lesson`, `/lesson-progress` | Nội dung bài học và tiến độ |
| `/vocabulary`, `/kanji`, `/grammar` | Nội dung ngôn ngữ và CRUD quản trị |
| `/exercise` | Danh sách, câu hỏi, nộp bài và kết quả |
| `/jlpt` | Đề thi, phiên làm bài và chấm điểm JLPT |
| `/srs`, `/flashcard` | Ôn tập lặp lại ngắt quãng và bộ thẻ |
| `/progress`, `/streak`, `/achievement` | Dashboard, XP, streak và thành tích |
| `/group`, `/group-chat` | Nhóm học tập và tin nhắn |
| `/notebook`, `/news`, `/notifications` | Ghi chú, tin tức và thông báo |
| `/report`, `/transactions` | Báo cáo và yêu cầu giao dịch |

## Quy ước response

- Danh sách có thể trả trực tiếp array hoặc object phân trang gồm `data`, `totalItems`, `totalPages`, `currentPage`.
- Tạo/cập nhật thường trả `{ message, data }`.
- Lỗi client dùng HTTP 400/401/403/404/409; lỗi máy chủ dùng HTTP 500.
- Flutter service chịu trách nhiệm chuẩn hóa response trước khi đưa vào model/provider.

## Ví dụ luồng bài tập

```text
GET  /api/exercise/lesson/:lessonId
GET  /api/exercise/:exerciseId
POST /api/exercise/submit/:exerciseId
GET  /api/exercise/history
GET  /api/exercise/result/:resultId
```

Body nộp bài:

```json
{
  "answers": [
    { "question_id": "...", "answer_id": "..." }
  ],
  "timeSpent": 90
}
```

Danh sách đầy đủ và method/path chính xác được bảo vệ bởi `BackEnd/tests/route-contract.test.js`.
