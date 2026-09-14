# Thiết kế — Làm lại hệ thống thị giác của giao diện

Ngày: 2026-09-14 · Trạng thái: đã duyệt qua brainstorming, chưa triển khai

## 1. Vấn đề

Giao diện trông chắp vá và "chưa được thiết kế". Đo trên `FrontEnd/lib` ngày 2026-09-14:

| Chỉ số | Giá trị | Hệ quả |
| --- | --- | --- |
| Số lần hardcode `fontSize:` | 475 | Chữ to nhỏ không theo nhịp nào |
| Số cỡ chữ khác nhau đang dùng | 20 (9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 20, 22, 24, 28, 32, 36, 40, 42, 48, 64) | 13px cạnh 14px cạnh 15px đọc ra như lỗi |
| Cỡ chữ dùng nhiều nhất | 12px (103 lần) | Quá nhỏ cho app học ngoại ngữ |
| File hardcode màu | 42 | Mỗi màn một sắc xám khác nhau |
| File dùng `AppColors` | 13 | Design system có mà gần như không ai dùng |
| Màu chủ đạo | `#2196F3` | Đúng Material Blue mặc định của Flutter |
| Font khai báo | không có | Dùng font mặc định hệ thống |

**Gốc của vấn đề không phải thiếu trang trí.** Hạ tầng theme đã tốt: `app_theme.dart` dùng
Material 3, `ColorScheme.fromSeed`, nối `textTheme` vào `AppTypography`, có theme riêng cho
button/chip/card/nav; `app_tokens.dart` có sẵn `AppColors`/`AppSpacing`/`AppRadius`;
54/60 screen đã dùng `AppScaffold`. Vấn đề là **màn hình đi vòng qua hệ thống đó** bằng giá
trị hardcode. Vì vậy hướng sửa là chỉnh lại giá trị token và gỡ các chỗ đi vòng, không phải
xây hệ thống mới.

## 2. Quyết định thiết kế

Chốt qua brainstorming ngày 2026-09-14:

| Câu hỏi | Quyết định | Vì sao |
| --- | --- | --- |
| Phạm vi | Nền tảng toàn cục + đánh bóng kỹ 6 màn của luồng demo | 60 màn là quá nhiều cho một đợt; sửa nền tảng nâng cả 60 màn, đánh bóng sâu chỉ ở đường đi khi bảo vệ |
| Hướng thẩm mỹ | Theo chuẩn app hiện hành trên thị trường | Yêu cầu trực tiếp của người dùng |
| Font | `google_fonts`: Inter (Việt) + Noto Sans JP (Nhật) | Font mặc định là thứ tố cáo "chưa thiết kế" rõ nhất; Inter hỗ trợ dấu tiếng Việt tốt |
| Màu chủ đạo | Indigo `#4F46E5`, nhấn Amber `#F59E0B` | Bỏ Material Blue mặc định; tách bạch màu thương hiệu và màu động lực (streak/XP) |
| Thang chữ | 7 bậc, nền 16px | Từ 20 cỡ hỗn loạn về một nhịp đọc được |

## 3. Bảng màu

Thang trung tính ngả xanh (slate) thay cho `Colors.grey[...]` rải rác:

```text
Thương hiệu   primary    #4F46E5   primaryDark #4338CA   primaryLight #EEF2FF
Nhấn          accent     #F59E0B   (streak, XP, tiến độ)
Ngữ nghĩa     success    #10B981   warning #F59E0B   error #EF4444   info #0EA5E9
Trung tính    #0F172A (chữ chính)  #475569 (chữ phụ)  #94A3B8 (chữ mờ)
              #E2E8F0 (viền)       #F1F5F9 (nền phụ)  #F8FAFC (nền)   #FFFFFF (mặt)
Dark mode     nền #0F172A  mặt #1E293B  viền #334155  chữ #F1F5F9 / #94A3B8
```

Màu theo lĩnh vực (`AppColors.vocabulary/grammar/kanji/...`) giữ nguyên vai trò nhưng chỉnh
sang cùng hệ độ bão hoà với bảng trên, để thẻ của các mục không chọi nhau.

## 4. Thang chữ

| Bậc | Cỡ | Đậm | Dùng cho |
| --- | --- | --- | --- |
| display | 32 | 700 | Số liệu lớn, màn chào |
| headline | 24 | 700 | Tiêu đề màn |
| title | 20 | 600 | Tiêu đề khối |
| subtitle | 18 | 600 | Tiêu đề thẻ |
| body | 16 | 400 | Nội dung chính |
| bodySmall | 14 | 400 | Phụ đề |
| caption | 12 | 500 | Nhãn, metadata |

Chữ Nhật giữ hai bậc riêng vì kanji nhỏ thì mất nét: `japaneseDisplay` 40/600 và
`japaneseReading` 18/400, cùng dùng Noto Sans JP.

Các cỡ 9, 11, 13, 15, 17, 22, 36, 42, 48, 64 bị loại khỏi codebase trong phạm vi 6 màn được
đánh bóng; những màn ngoài phạm vi vẫn còn cho tới đợt sau.

## 5. Phạm vi thi công

**Nền tảng (ảnh hưởng cả 60 màn):**

- `pubspec.yaml`: thêm `google_fonts`.
- `app_tokens.dart`: thay bảng màu theo §3.
- `app_typography.dart`: dựng lại thang chữ theo §4, gắn Inter/Noto Sans JP.
- `app_theme.dart`: đổi seed color; rà lại theme của button/chip/card cho khớp bảng màu mới.

**Sáu màn đánh bóng kỹ** (gỡ hardcode, dùng `textTheme`/`AppColors`/`AppSpacing`, thay `Card`
thô bằng `AppCard`):

| Màn | Dòng | `fontSize` hardcode |
| --- | --- | --- |
| `features/home/screens/home_screen.dart` | 443 | 6 |
| `features/lessons/screens/lesson_list_screen.dart` | 479 | 10 |
| `features/lessons/screens/lesson_detail_screen.dart` | 813 | 15 |
| `features/vocabulary/screens/vocabulary_main_screen.dart` | 194 | 0 |
| `features/flashcards/screens/flashcard_study_screen.dart` | 359 | 4 |
| `features/profile/screens/profile_screen.dart` | 542 | 4 |

**Bảy chỗ hardcode đúng mã màu cũ `#2196F3`** phải gỡ cùng đợt, nếu không sẽ lệch tông với
theme mới: `app_tokens.dart`, `features/achievements/models/achievement.dart`,
`features/achievements/screens/achievement_screen.dart`,
`features/flashcards/widgets/flashcard_widget.dart`,
`features/streaks/screens/streak_screen.dart`.

## 6. Chống tái phát

Không có bước này thì vài tuần nữa lại lem nhem như cũ:

- `analysis_options.yaml`: bật rule chặn hardcode màu trong `lib/features/**`.
- Một test đếm số `fontSize:` hardcode toàn `lib/` và chặn không cho vượt ngưỡng hiện tại —
  cùng cơ chế với `route-contract.test.js`: muốn tăng thì phải sửa ngưỡng có chủ đích. Ngưỡng
  đặt bằng đúng con số còn lại sau khi đánh bóng 6 màn, nên nó chỉ có thể giảm dần.

## 7. Ngoài phạm vi

- **52 màn còn lại** — vẫn đẹp lên nhờ theme mới nhưng không được gỡ hardcode ở đợt này.
- **`group_detail_screen.dart`** — đang đóng băng theo `redesign-roadmap.md`, không đụng.
- **Cấu trúc điều hướng** — `app_navigation.dart`/`app_shell.dart` đang ổn, không vẽ lại IA.
- **Tách các screen quá khổ** — `lesson_detail_screen.dart` (813 dòng) và
  `learning_history_screen.dart` (1031) vẫn quá dài sau đợt này; tách file là việc riêng.
- **Dark mode hoàn chỉnh** — bảng màu tối có trong §3 nhưng không rà từng màn ở đợt này.

## 8. Nghiệm thu

- `dart analyze --fatal-infos` không tăng thêm lỗi so với 13 lỗi có sẵn (đều trong test file
  SRS, không liên quan).
- `flutter test` không tăng thêm test đỏ so với 4 test đỏ có sẵn; test đếm `fontSize` mới phải
  xanh.
- `flutter build web --no-pub` thành công.
- Mở app thật trên trình duyệt, đi hết luồng demo sáu màn, xác nhận không có tràn layout ở các
  bề rộng mà `breakpoint_overflow_test.dart` đang khoá.
- Đối chiếu bằng mắt: không còn hai cỡ chữ lệch nhau 1-2px cạnh nhau trong cùng một khối.

## 9. Rủi ro

- **Đổi màu chủ đạo ảnh hưởng toàn app.** Bảy chỗ hardcode `#2196F3` đã liệt kê ở §5; ngoài ra
  các màn ngoài phạm vi dùng `Colors.blue` sẽ hơi lệch tông cho tới đợt sau. Chấp nhận được vì
  lệch tông nhẹ vẫn đỡ hơn hiện trạng mỗi màn một kiểu.
- **`google_fonts` cần mạng ở lần chạy đầu.** Nếu tải hỏng, package tự lùi về font mặc định —
  app không vỡ, chỉ là chữ trông như cũ. Không đặt font vào đường đi bắt buộc của tính năng nào.
- **Tăng cỡ chữ nền từ 12 lên 16 làm nội dung chiếm nhiều chỗ hơn**, có thể lộ ra tràn layout ở
  màn hẹp. Đây là lý do nghiệm thu bắt buộc chạy `breakpoint_overflow_test.dart`.
