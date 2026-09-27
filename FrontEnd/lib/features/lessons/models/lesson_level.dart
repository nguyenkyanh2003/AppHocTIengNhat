/// Mọi cấp JLPT, từ dễ đến khó — dùng để đọc trình độ trong hồ sơ.
const List<String> kJlptLevels = ['N5', 'N4', 'N3', 'N2', 'N1'];

/// Cấp độ có bài học tình huống, hiện trên hàng lọc của màn Bài học.
///
/// Bài học tình huống đi theo video của Tsunagaru, vốn chỉ có ba cấp tương
/// đương N5, N4, N3. N2 và N1 không có bài nên không hiện nút lọc — bấm vào chỉ
/// ra danh sách rỗng. Từ vựng, kanji, ngữ pháp, đề JLPT của N2, N1 vẫn ở các mục
/// riêng của app.
const List<String> kLessonLevels = ['N5', 'N4', 'N3'];

/// Chuẩn hoá trình độ lưu trong hồ sơ về một phần tử của [kJlptLevels].
///
/// Hồ sơ cũ có thể lưu số (`5`) hoặc chữ thường thay vì `N5`. Giá trị thiếu hay
/// không phải cấp JLPT trả `null`.
String? normalizeJlptLevel(String? raw) {
  final value = raw?.trim().toUpperCase() ?? '';
  if (value.isEmpty) return null;
  final level = value.startsWith('N') ? value : 'N$value';
  return kJlptLevels.contains(level) ? level : null;
}

/// Cấp độ bài học hiện ra đầu tiên khi người học mở màn Bài học.
///
/// Lấy theo trình độ trong hồ sơ để người học gặp ngay bài hợp sức mình. Người
/// học N2, N1 bắt đầu ở cấp cao nhất đang có bài thay vì một danh sách rỗng. Hồ
/// sơ thiếu hoặc sai định dạng thì bắt đầu từ N5.
String defaultLessonLevel(String? userLevel) {
  final level = normalizeJlptLevel(userLevel) ?? kLessonLevels.first;
  return kLessonLevels.contains(level) ? level : kLessonLevels.last;
}
