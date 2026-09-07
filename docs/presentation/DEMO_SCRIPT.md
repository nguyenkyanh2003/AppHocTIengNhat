# Kịch bản demo và bảo vệ

## Thông điệp mở đầu (30–45 giây)

AppHocTiengNhat là hệ thống học tiếng Nhật đa nền tảng. Flutter đảm nhiệm trải nghiệm người học và quản trị; Express/MongoDB quản lý nội dung, tiến độ, bài tập, JLPT, SRS, nhóm học và báo cáo. Mục tiêu kỹ thuật chính là tách module theo domain, giữ API có contract và bảo vệ dữ liệu người dùng bằng JWT/phân quyền.

## Kịch bản demo 8–10 phút

1. **Đăng nhập và bảo mật**: đăng nhập user; giải thích secure token storage, rate limit và phân quyền admin.
2. **Học bài**: chọn level → bài học → xem từ vựng/Kanji/ngữ pháp → cập nhật tiến độ.
3. **Bài tập theo bài học**: bấm “Làm bài tập”; chỉ ra danh sách được lọc bằng `lessonId`; làm và nộp một bài.
4. **Theo dõi kết quả**: mở dashboard/progress, streak, XP và thành tích.
5. **Ôn tập**: trình bày flashcard/SRS hoặc JLPT.
6. **Tính cộng đồng ở mức phạm vi**: mở danh sách và chi tiết một nhóm học đã seed; không mở
   chat hoặc upload media vì module này đang đóng băng.
7. **Quản trị**: tạo hoặc sửa một nội dung thật, export CSV, xử lý report/transaction.
8. **Offline**: tải nội dung, bật chế độ ngoại tuyến và giải thích fallback cache.
9. **Chất lượng**: mở `TEST_REPORT.md`, nêu analyzer sạch và số test passed.

## Câu hỏi phản biện nên chuẩn bị

- Vì sao dùng feature-first Flutter và domain-first backend?
- JWT được lưu ở đâu, token reset khác access token thế nào?
- Hệ thống chấm bài và chống đáp án trùng ra sao?
- MongoDB relation được kiểm tra thế nào khi không có foreign key?
- Khi mất mạng, dữ liệu nào dùng được và dữ liệu nào không?
- Vì sao transaction chưa gọi cổng thanh toán?

## Phạm vi phải nói đúng

- Transaction hiện là quy trình tạo và duyệt **yêu cầu giao dịch**, không phải tích hợp ví/ngân hàng tự động.
- Offline là cache nội dung đã tải; các thao tác ghi vẫn cần kết nối máy chủ.
- Build Android release cần SDK và keystore của môi trường phát hành.
- Group chat vẫn tồn tại trong code legacy nhưng không thuộc luồng demo hoặc tiêu chí nghiệm
  thu hiện tại; không tuyên bố đã hoàn thiện moderation, rate limit hay upload an toàn.
- Không trình bày coverage hoặc MongoDB E2E là đã hoàn thành khi chưa có bằng chứng chạy.

## Checklist trước giờ demo

- Dùng database test có dữ liệu seed và hai tài khoản user/admin.
- Kiểm tra `API_BASE_URL` đúng IP máy demo.
- Chạy `npm test`, `dart analyze`, `flutter test` và lưu ảnh kết quả.
- Kiểm tra email test; không chiếu `.env` hay credential.
- Chuẩn bị web build làm phương án dự phòng nếu thiết bị Android lỗi.
- Thử toàn bộ kịch bản một lần với timer dưới 10 phút.
