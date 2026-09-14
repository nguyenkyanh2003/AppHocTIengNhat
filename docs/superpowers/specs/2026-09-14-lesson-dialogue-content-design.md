# Thiết kế — Nội dung hội thoại theo tình huống cho bài học

Ngày: 2026-09-14 · Trạng thái: đã duyệt qua brainstorming, chưa triển khai

Tài liệu này là phần tiếp theo của
[lesson-situation-tagging-design.md](2026-09-14-lesson-situation-tagging-design.md), vốn chỉ
mở hạ tầng (field `situation`, refactor 4 tầng) mà cố ý để trống nội dung và không đụng
Flutter. Spec này hoàn thiện phần còn thiếu để trải nghiệm học thực sự tổ chức theo tình
huống, gần với cách [Tsunagaru](https://tsunagarujp.mext.go.jp/level00/d03) trình bày:
hội thoại thật cho một số tình huống, và giao diện Flutter hiển thị/lọc được theo tình huống.

## 1. Phạm vi

**Trong phạm vi:**
- Cấu trúc dữ liệu hội thoại (`dialogue`, `can_do_goals`) trên `Lesson`, song song với
  `content_html` hiện có.
- Nội dung thật cho **3 tình huống**: `supermarket` (đi siêu thị), `train` (đi tàu),
  `restaurant` (nhà hàng) — ba giá trị đã có sẵn trong `situation-catalog.js`.
- Từ vựng chính của mỗi hội thoại là `Vocabulary` thật, gắn `lesson` đúng bài, nhập qua
  `import-vocabulary.js` đã có.
- Endpoint `GET /api/lesson/situations` — danh sách tình huống đang có ít nhất một bài học.
- Flutter: model cập nhật, widget hiển thị hội thoại mới, hai màn hình bài học gọi widget đó,
  màn danh sách bài học lọc được theo tình huống.

**Ngoài phạm vi (xem §7):** audio, 12 tình huống còn lại của catalog, sửa `content_html` của
10 bài ngữ pháp cũ, tự động sinh nội dung bằng Claude API trong runtime (nội dung ở đây là
seed tĩnh, không phải tính năng luyện nói AI của Phase 2).

## 2. Nguồn nội dung và trách nhiệm rà soát

Nội dung tiếng Nhật (câu thoại, cách đọc, nghĩa) trong spec và plan tiếp theo do Claude soạn
dựa trên mẫu câu N5 phổ biến. **Đây không phải nội dung đã được kiểm chứng bởi người biết
tiếng Nhật.** Trước khi dùng trong bản bảo vệ đồ án hoặc demo chính thức, người dùng (hoặc
người biết tiếng Nhật) phải rà lại toàn bộ hội thoại đã seed. Commit nạp nội dung phải ghi rõ
trong message rằng nội dung "cần rà soát trước khi dùng chính thức" — không tuyên bố đã kiểm
chứng.

## 3. Data model

Thêm hai field optional vào `Lesson` (không đổi field nào cũ, không migration vì optional):

```js
dialogue: {
  type: [{
    speaker: { type: String, required: true, trim: true },
    text_ja: { type: String, required: true, trim: true },
    reading: { type: String, required: true, trim: true },
    text_vi: { type: String, required: true, trim: true },
    audio_url: { type: String, default: null },
  }],
  default: [],
},
can_do_goals: { type: [String], default: [] },
```

- `speaker` là nhãn vai (ví dụ `"店員"`, `"客"`), không phải tên nhân vật cụ thể — đơn giản
  cho việc soạn và hiển thị.
- `reading` là cách đọc **toàn câu** bằng hiragana/katakana (không phải furigana theo từng
  kanji) — đủ cho người học N5 đọc được câu, không đòi hỏi UI ruby text (đã ghi nhận là ngoài
  phạm vi hiện hành ở `learning-loop-program-design.md` §5).
- `audio_url` để sẵn chỗ cho quyết định audio sau này (client TTS hoặc file thật); mặc định
  `null`, không có consumer nào đọc field này ở đợt này.
- Một `Lesson` có thể có cả `content_html` lẫn `dialogue` (không bắt buộc loại trừ nhau); bài
  ngữ pháp cũ chỉ có `content_html`, bài tình huống mới chỉ có `dialogue`.

## 4. Nội dung ba tình huống

| `situation` | Tên bài | Số lượt thoại | Số từ vựng mới | Can-do goals |
| --- | --- | --- | --- | --- |
| `supermarket` | Đi siêu thị | 6-8 lượt (khách — nhân viên thu ngân) | 8-10 từ | 2-3 mục |
| `train` | Đi tàu | 6-8 lượt (khách — nhân viên nhà ga) | 8-10 từ | 2-3 mục |
| `restaurant` | Ở nhà hàng | 6-8 lượt (khách — nhân viên phục vụ) | 8-10 từ | 2-3 mục |

Cả ba đều cấp độ `N5`, dùng mẫu câu lịch sự cơ bản (です/ます). Nội dung hội thoại đầy đủ và
danh sách từ vựng cụ thể được viết trực tiếp trong implementation plan (không lặp lại ở đây
để tránh hai nguồn sự thật lệch nhau khi chỉnh sửa).

## 5. Backend

### 5.1 Model và repository

`Lesson.js` thêm hai field ở §3. `lesson.repository.js` (đã tách tầng ở spec trước) thêm:

```js
distinctSituations() {
  return lessonModel.distinct('situation', { situation: { $ne: null } });
}
```

### 5.2 Service và API mới

`lesson.service.js` thêm `listSituations()` gọi `repository.distinctSituations()`, sort kết
quả. Route mới:

```
GET /api/lesson/situations  →  { data: string[], total }
```

Đăng ký **trước** `/:id` trong `lesson.routes.js` (cùng nguyên tắc thứ tự route đã áp dụng ở
spec trước, tránh Express nuốt `"situations"` làm `:id`). Route công khai tăng từ 11 lên 12 —
cập nhật `expectedCount`/`expectedSignatureHash` trong `route-contract.test.js` **có chủ đích**
trong cùng commit, sau khi đọc lại danh sách route mới bằng mắt.

`GET /api/lesson` và `GET /api/lesson/:id` không đổi chữ ký — `dialogue`/`can_do_goals` tự
nhiên xuất hiện trong response vì service/controller đã trả nguyên document.

### 5.3 Seed nội dung

Script mới `BackEnd/scripts/seed-situational-lessons.js`:
- Upsert theo `title` (khoá tự nhiên có sẵn, đã unique-index) — **không** `deleteMany`, không
  ảnh hưởng 10 bài ngữ pháp cũ.
- Có `--dry-run` giống `import-vocabulary.js`, in ra bài sẽ tạo/cập nhật trước khi ghi.
- Sau khi 3 lesson tồn tại, chạy `import-vocabulary.js --file <đường dẫn CSV> --dry-run` rồi
  bỏ `--dry-run` để nạp từ vựng, gắn `lesson` đúng ID vừa tạo.

## 6. Flutter

### 6.1 Model

`FrontEnd/lib/features/lessons/models/lesson.dart`: thêm `situation` (`String?`), `dialogue`
(`List<DialogueTurn>`), `canDoGoals` (`List<String>`) vào `Lesson`, parse an toàn khi field
vắng mặt (bài cũ không có `dialogue`).

Model mới `dialogue_turn.dart`:

```dart
class DialogueTurn {
  final String speaker;
  final String textJa;
  final String reading;
  final String textVi;
  final String? audioUrl;
  // fromJson/toJson tương ứng field snake_case ở trên
}
```

### 6.2 Widget hội thoại

`FrontEnd/lib/features/lessons/widgets/dialogue_view.dart` (mới, dưới 300 dòng): nhận
`List<DialogueTurn>` và `List<String> canDoGoals`, hiển thị:
- Khối "Có thể làm được" (can-do goals) dạng checklist ở đầu.
- Danh sách lượt thoại: nhãn `speaker`, `text_ja` (cỡ chữ lớn), `reading` (nhỏ hơn, màu phụ),
  `text_vi` (nghiêng, màu phụ) — dùng token màu/spacing từ `app_tokens.dart`, không hardcode.
- Không có nút phát audio ở đợt này (audio ngoài phạm vi); để sẵn slot UI trống nếu
  `audioUrl != null` trong tương lai, nhưng chưa vẽ gì khi luôn `null`.

### 6.3 Điểm gọi trong 2 screen hiện có

- `lesson_detail_screen.dart`: nếu `lesson.dialogue.isNotEmpty`, chèn `DialogueView` vào vị
  trí đang hiển thị tổng quan bài học; nếu rỗng, hành vi y hệt hiện tại (không đổi nhánh
  `content_html`).
- `lesson_study_screen.dart`: nếu `dialogue.isNotEmpty`, dùng `DialogueView` làm nội dung học
  chính thay cho phần render `content_html`; nếu rỗng, giữ nguyên luồng cũ.
- Không sửa logic nào khác trong hai file này ngoài điểm rẽ nhánh này — đúng nguyên tắc
  "chỉ thêm điểm gọi, không phình file cũ" đã thống nhất.

### 6.4 Lọc theo tình huống ở danh sách

`lesson_list_screen.dart`: `_showFilterDialog()` hiện có thêm một khối "Lọc theo tình huống"
(đọc danh sách qua `LessonService.getSituations()` gọi `GET /lesson/situations`), thêm state
`_selectedSituation` cạnh `_selectedLevel`, thêm chip hiển thị tình huống đang chọn. Không
tách file riêng vì phần thêm nhỏ (~20-30 dòng) trên một file đã ở mức 396 dòng, khác hẳn mức
độ phình của hai màn 700+ dòng kia.

## 7. Ngoài phạm vi

- **Audio thật** (file hoặc TTS phát từ `text_ja`) — `audio_url` chỉ để sẵn chỗ; quyết định
  nguồn/engine là việc riêng của Phase 2 §5.3 khi làm luyện nói AI.
- **12 tình huống còn lại** trong `situation-catalog.js` — chỉ 3 tình huống có nội dung thật
  ở đợt này; thêm tình huống mới là lặp lại đúng quy trình ở §5.3, không cần đổi schema.
- **Sửa `content_html` của 10 bài ngữ pháp cũ** — chúng không phải tình huống, không ép vào
  cấu trúc `dialogue`.
- **Furigana theo từng kanji (ruby text)** — `reading` là cách đọc toàn câu, không phải
  markup ruby; đã ghi nhận là ngoài phạm vi ở spec chương trình học trước đó.
- **Dùng chung taxonomy này với `speaking-topics.js`** — module `speaking` chưa tồn tại,
  giữ nguyên quyết định "không giả định trước" từ spec lesson-situation-tagging.
- **Tách toàn bộ `lesson_detail_screen.dart`/`lesson_study_screen.dart` xuống dưới 300 dòng**
  — chỉ tách phần hội thoại thành widget riêng; phần còn lại của hai file vẫn to như cũ, việc
  tổng dọn dẹp thuộc Giai đoạn 3 theo `redesign-roadmap.md`.

## 8. Test bắt buộc

- Backend: `lesson.repository.test.js` thêm test `distinctSituations` lọc đúng `$ne: null`;
  `lesson.service.test.js` thêm test `listSituations` sort kết quả; `lesson.routes.test.js`
  thêm test `GET /situations` trả `{data, total}`, mảng rỗng khi chưa có bài nào gắn tình
  huống (200, không 404); model test thêm assertion cho `dialogue`/`can_do_goals` default `[]`.
- `route-contract.test.js`: cập nhật `expectedCount` 11→12 và hash mới sau khi xác nhận danh
  sách route bằng mắt.
- Flutter: test parse `Lesson.fromJson` với và không có `dialogue`; widget test cho
  `DialogueView` (render đúng số lượt thoại, ẩn nút audio khi `audioUrl == null`); cập nhật
  test hiện có của `lesson_list_screen` nếu chạm state mới; không cần thêm route mới vào
  `navigation_contract_test.dart` vì không thêm màn hình/route Flutter mới.
- Không test nào chạm MongoDB thật hay import CSV thật trong CI.

## 9. Rollout

1. Data model (§3) — thêm field, không migration.
2. Backend service/route/test (§5.1–5.2).
3. Soạn nội dung 3 tình huống + script seed + CSV từ vựng (§5.3) — chạy `--dry-run` trước,
   ghi rõ trong commit là nội dung cần rà soát (§2).
4. Flutter model + `DialogueView` + điểm gọi trong 2 screen + filter danh sách (§6).
5. Xác nhận toàn cục: `npm test`, `dart analyze --fatal-infos`, `flutter test`, route contract.

## 10. Rủi ro

- **Độ chính xác nội dung tiếng Nhật chưa được người biết tiếng Nhật xác nhận** tại thời điểm
  code xong — rủi ro đã nêu ở §2, giảm bằng cách dùng mẫu câu N5 phổ biến, ghi chú rõ trong
  commit, và yêu cầu rà soát trước khi đưa vào bản bảo vệ.
- **Trộn hai khái niệm "tình huống"**: `Vocabulary.usage_context` (đã có, tự do, dùng cho
  browse/search từ vựng) và `Lesson.situation` (enum cố định, dùng cho bài học) là hai field
  độc lập, khác model, khác mục đích — đã ghi nhận từ spec trước; giữ nguyên, không hợp nhất.
- **Thêm route làm đổi route-contract hash** — đây là thay đổi có chủ đích (12 route thay vì
  11), không phải lỗi; chỉ rủi ro nếu quên cập nhật cùng commit.
