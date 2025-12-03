# Lesson System với Progress Tracking

## Tổng quan

Hệ thống quản lý bài học (Lesson System) đầy đủ với tracking tiến độ học tập chi tiết.

## Tính năng đã triển khai

### 1. **Lesson Progress Model** (`lib/models/lesson_progress.dart`)
- Theo dõi tiến độ học từng lesson của user
- Tracking chi tiết:
  - Số lượng vocabulary đã học / tổng số
  - Số lượng grammar đã học / tổng số
  - Số lượng kanji đã học / tổng số
- Tính toán phần trăm hoàn thành tự động
- Trạng thái hoàn thành lesson

### 2. **Progress Service** (`lib/services/lesson_progress_service.dart`)
- `getProgress(lessonId)` - Lấy tiến độ cho 1 lesson
- `getAllProgress()` - Lấy tất cả tiến độ
- `startLesson(lessonId)` - Bắt đầu học lesson
- `updateProgress()` - Cập nhật khi học item
- `completeLesson(lessonId)` - Đánh dấu hoàn thành
- `resetProgress(lessonId)` - Reset tiến độ
- `getOverallStats()` - Thống kê tổng quan
- `getProgressByLevel(level)` - Thống kê theo level

### 3. **Progress Provider** (`lib/providers/lesson_progress_provider.dart`)
- State management cho progress
- Auto-sync với backend
- Real-time progress updates

### 4. **LessonDetailScreen cải tiến** 
- **Progress bar** hiển thị % hoàn thành tổng thể
- **Circular progress** cho từng category (vocabulary/grammar/kanji)
- **Completion badge** khi hoàn thành lesson
- **Smart button**: 
  - "Bắt đầu học" (chưa bắt đầu)
  - "Tiếp tục học" (đang học)
  - "Học lại" (đã hoàn thành)
- **Reset button** để đặt lại tiến độ
- Hiển thị số lượng đã học / tổng số

### 5. **Backend API** (`BackEnd/routes/LessonProgress.js`)
Endpoints:
- `GET /api/lesson-progress/lesson/:lessonId` - Get progress
- `GET /api/lesson-progress/lessons` - Get all progress
- `POST /api/lesson-progress/lesson/:lessonId/start` - Start lesson
- `POST /api/lesson-progress/lesson/:lessonId/update` - Update progress
- `POST /api/lesson-progress/lesson/:lessonId/complete` - Complete lesson
- `POST /api/lesson-progress/lesson/:lessonId/reset` - Reset progress
- `GET /api/lesson-progress/stats` - Overall stats
- `GET /api/lesson-progress/level/:level` - Level stats

### 6. **Database Model** (`BackEnd/model/LessonProgress.js`)
- Schema với user, lesson references
- Tracking các item đã học (IDs)
- Compound index (user + lesson) để query nhanh
- Methods: `markItemLearned()`, `unmarkItemLearned()`
- Auto-complete detection

## Cách sử dụng

### Frontend

1. **Trong LessonDetailScreen:**
```dart
// Progress tự động load khi vào màn hình
// Hiển thị progress bar, circular indicators
// Nút "Bắt đầu học" / "Tiếp tục học" / "Học lại"
```

2. **Update progress khi học:**
```dart
final progressProvider = Provider.of<LessonProgressProvider>(context);

// Đánh dấu đã học 1 vocabulary
await progressProvider.updateProgress(
  lessonId: lessonId,
  itemType: 'vocabulary',
  itemId: vocabId,
  completed: true,
);

// Hoàn thành lesson
await progressProvider.completeLesson(lessonId);

// Reset tiến độ
await progressProvider.resetProgress(lessonId);
```

3. **Lấy thống kê:**
```dart
final progressProvider = Provider.of<LessonProgressProvider>(context);
await progressProvider.loadStats();
print(progressProvider.stats);
// {
//   total_lessons: 10,
//   completed_lessons: 3,
//   in_progress_lessons: 5,
//   total_vocabularies_learned: 150,
//   ...
// }
```

### Backend

Các route đã được đăng ký trong `main.js`:
```javascript
app.use("/api/lesson-progress", LessonProgressRoutes);
```

## Testing

1. **Khởi động backend:**
```bash
cd BackEnd
npm start
```

2. **Khởi động frontend:**
```bash
cd FrontEnd
flutter run -d chrome
```

3. **Test flow:**
- Login vào app
- Vào "Bài học" → Chọn 1 lesson
- Click "Bắt đầu học"
- Xem progress bar cập nhật
- Vào LessonStudyScreen (nếu có)
- Quay lại → Xem progress đã lưu
- Test reset progress

## Cải tiến tiếp theo

- [ ] Hệ thống rewards/badges khi hoàn thành lessons
- [ ] Daily streak tracking
- [ ] Leaderboard theo level
- [ ] Progress chart visualization
- [ ] Study time tracking
- [ ] Spaced repetition reminder
- [ ] Practice exercises tích hợp với progress
- [ ] Export progress report PDF

## API Response Examples

### Get Progress
```json
{
  "_id": "...",
  "user": "user_id",
  "lesson": "lesson_id",
  "completed_vocabularies": 5,
  "total_vocabularies": 10,
  "completed_grammars": 2,
  "total_grammars": 5,
  "completed_kanjis": 3,
  "total_kanjis": 8,
  "is_completed": false,
  "last_studied_at": "2025-12-01T10:00:00.000Z",
  "createdAt": "2025-12-01T09:00:00.000Z",
  "updatedAt": "2025-12-01T10:00:00.000Z"
}
```

### Get Stats
```json
{
  "total_lessons": 25,
  "completed_lessons": 8,
  "in_progress_lessons": 12,
  "total_vocabularies_learned": 350,
  "total_grammars_learned": 120,
  "total_kanjis_learned": 180
}
```

## Notes

- Progress tự động tạo khi user click "Bắt đầu học"
- Backend sử dụng compound index (user + lesson) để query nhanh
- Frontend cache progress trong provider
- Progress được update real-time khi học
- Hỗ trợ multiple devices (sync qua backend)
