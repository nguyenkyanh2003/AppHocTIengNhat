/// Bốn loại nội dung màn quản trị sửa được. [name] là tên dùng trong CSV và
/// tên tệp xuất.
enum AdminContentType {
  vocabulary('Từ vựng', '/vocabulary'),
  kanji('Kanji', '/kanji'),
  grammar('Ngữ pháp', '/grammar'),
  lessons('Bài học', '/lesson');

  const AdminContentType(this.label, this.path);

  final String label;

  /// Đường dẫn API của loại nội dung.
  final String path;

  /// Backend chỉ có importer Excel cho từ vựng và Kanji.
  bool get supportsExcel => this == vocabulary || this == kanji;
}
