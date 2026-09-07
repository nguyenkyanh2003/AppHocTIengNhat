# Báo cáo kiểm thử

Ngày kiểm chứng gần nhất: **2026-08-28**.

## Kết quả tự động

| Quality gate | Kết quả |
| --- | --- |
| `npm test` | 12/12 passed |
| `node --check` cho backend JS | 95/95 file passed |
| `dart analyze` | 0 issue |
| `flutter test --no-pub` | 8/8 passed |
| `flutter build web --no-pub` | Passed, build production hoàn tất trong 93,9 giây |

Backend test bao phủ smoke/404 Express, contract route, contract model transaction/report, scoring exercise/JLPT và chuẩn hóa Kanji canonical/legacy. Flutter test bao phủ bootstrap, navigation contract, preference/cache contract, lesson-scoped exercise contract và CSV import/export.

## Kiểm thử thủ công trước khi bảo vệ

1. Đăng ký, đăng nhập, đăng xuất và forgot password với email test.
2. Học một bài, mở đúng bài tập của bài đó, nộp bài và kiểm tra XP/streak.
3. Admin tạo/sửa/nhân bản/xóa từng loại nội dung; import CSV và export CSV.
4. Bật offline, tải nội dung, ngắt backend/mạng và mở lại nội dung đã cache.
5. Tạo report và xử lý report bằng admin.
6. Tạo yêu cầu giao dịch và cập nhật trạng thái bằng admin.
7. Nhóm học: tạo/join/chat/upload audio hoặc ảnh trên hai tài khoản.
8. Chạy responsive trên web và một thiết bị Android thật.

## Giới hạn chưa thể xác nhận tự động tại workspace

- Chưa có MongoDB integration test/container; cần chạy checklist với database test.
- Android APK/AAB chưa build được trên máy không có Android SDK và release keystore.
- Cổng thanh toán tự động nằm ngoài phạm vi hiện tại; module transaction quản lý yêu cầu giao dịch và trạng thái.
- Email reset phụ thuộc credential/provider bên ngoài; không dùng credential production để demo.
