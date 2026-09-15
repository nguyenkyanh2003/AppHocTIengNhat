/// Cấp độ JLPT dùng để lọc bài học, từ dễ đến khó.
const List<String> kLessonLevels = ['N5', 'N4', 'N3', 'N2', 'N1'];

/// Chuẩn hoá trình độ lưu trong hồ sơ về một phần tử của [kLessonLevels].
///
/// Hồ sơ cũ có thể lưu số (`5`) hoặc chữ thường thay vì `N5`. Giá trị thiếu hay
/// không phải cấp JLPT trả `null`.
String? normalizeJlptLevel(String? raw) {
  final value = raw?.trim().toUpperCase() ?? '';
  if (value.isEmpty) return null;
  final level = value.startsWith('N') ? value : 'N$value';
  return kLessonLevels.contains(level) ? level : null;
}

/// Cấp độ bài học hiện ra đầu tiên khi người học mở màn Bài học.
///
/// Lấy theo trình độ trong hồ sơ để người học gặp ngay bài hợp sức mình. Bộ bài
/// chủ đề chưa có bài N1, nên người học N1 bắt đầu ở N2 thay vì một danh sách
/// rỗng. Hồ sơ thiếu hoặc sai định dạng thì bắt đầu từ N5.
String defaultLessonLevel(String? userLevel) {
  final level = normalizeJlptLevel(userLevel) ?? 'N5';
  return level == 'N1' ? 'N2' : level;
}
