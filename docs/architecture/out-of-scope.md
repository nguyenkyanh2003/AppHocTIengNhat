# Ngoài phạm vi Giai đoạn 2

Tài liệu này tránh việc xóa hoặc sửa vội các module chưa có contract dữ liệu ổn định. “Ngoài
phạm vi” nghĩa là chưa triển khai trong Phase 2, không có nghĩa là chức năng bị bỏ vĩnh viễn.

| Khu vực | Quyết định Phase 2 | Điều kiện để mở lại |
| --- | --- | --- |
| Notifications | Không sửa recipient/read state. Model hiện có broadcast theo `target_level`, trong khi controller còn giả định trạng thái đọc theo user. Chỉ ẩn entrypoint hiển thị sai. | Chốt model recipient, read state, retention và quyền admin. |
| News admin | Giữ đọc tin. Chưa thiết kế lại CRUD/publish/category/tags; dùng đúng `image_url` hiện có. | Chốt schema bài viết, workflow publish và migration. |
| Transactions/billing | Giữ nguyên route và UI vì payment screen/admin đang sử dụng. Không refactor trong Phase 2. | Có test payment và phạm vi riêng. |
| Notebook/report/settings/admin còn lại | Giữ nguyên behavior hiện có; không chuẩn hóa cơ học chỉ vì còn thời gian ở cuối Phase 2. | Một module được ưu tiên lại bằng thay đổi có chủ đích trong roadmap + Phase 2 plan, có consumer inventory và test budget. |
| Study groups/group chat | Giữ nguyên backend, route, model và dữ liệu chat. Đã gỡ UI chat khỏi Flutter client (màn chat riêng, tab chat trong màn chi tiết nhóm, provider/service/model và audio recorder widget); không thêm matching, Pomodoro/presence, WebSocket hoặc refactor module trong Phase 2. Demo chỉ mở danh sách/chi tiết nhóm đã seed ở mức xem. | Vòng lặp SRS/progress đã ổn định; feature xã hội có trạng thái hữu ích với 1–2 tài khoản seed; có ngân sách refactor/test/moderation. Hướng mở lại ưu tiên là mục tiêu tuần + endpoint tổng hợp tiến độ, không phải matching. Vì API và dữ liệu còn nguyên, mở lại chat là viết lại UI client chứ không phải dựng lại backend; khi đó phải cập nhật roadmap, acceptance test và security plan cho message type, upload, moderation và rate limit. |
| Grammar trong SRS | Không thêm vào `SRSProgress`; enum hiện chỉ là `Vocabulary`/`Kanji`. | Thiết kế item type, index và nội dung card riêng. |
| Cloud STT và audio upload | Không nhận file audio ở backend. Client dùng STT/TTS theo khả năng nền tảng và có text fallback. | Chốt nhà cung cấp, consent, chi phí, retention và quota. |
| Đổi tên field User legacy | Không đổi `TenDangNhap`, `MatKhau`, `VaiTro`, `TrinhDo` trong Phase 2. | Migration toàn repo kèm backward compatibility. |

Mọi thay đổi ngoài bảng này phải được thêm vào plan và có consumer/contract test trước khi code.
