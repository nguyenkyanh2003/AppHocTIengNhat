/// Cấp độ JLPT dùng để lọc bài học.
const List<String> kLessonLevels = ['N5', 'N4', 'N3', 'N2', 'N1'];

/// Cấp độ bài học hiện ra đầu tiên khi người học mở màn Bài học.
///
/// Lấy theo trình độ trong hồ sơ để người học gặp ngay bài hợp sức mình. Bộ bài
/// chủ đề chưa có bài N1, nên người học N1 bắt đầu ở N2 thay vì một danh sách
/// rỗng. Hồ sơ cũ có thể lưu số (`5`) thay vì `N5`; thiếu hoặc sai định dạng
/// thì bắt đầu từ N5.
String defaultLessonLevel(String? userLevel) {
  var level = userLevel?.trim().toUpperCase() ?? '';
  if (!level.startsWith('N')) level = 'N$level';
  if (!kLessonLevels.contains(level)) return 'N5';
  return level == 'N1' ? 'N2' : level;
}
