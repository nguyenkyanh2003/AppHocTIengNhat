import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/features/admin/widgets/admin_content_format.dart';

void main() {
  test('cột nội dung của bảng quản trị có chữ cho mọi loại, kể cả từ vựng', () {
    expect(adminContentHeadline('vocabulary', {'word': '学生', 'hiragana': 'がくせい'}), '学生 (がくせい)');
    expect(adminContentHeadline('kanji', {'character': '学', 'meaning': 'học'}), '学');
    expect(adminContentHeadline('grammar', {'title': '〜てもいい', 'structure': 'V-て + もいい'}), '〜てもいい');
    expect(adminContentHeadline('lessons', {'title': 'Tình huống: Đi tàu'}), 'Tình huống: Đi tàu');
  });

  test('tiêu đề trong hộp xác nhận xoá kèm nghĩa để không xoá nhầm', () {
    expect(adminContentTitle('kanji', {'character': '学', 'meaning': 'học'}), '学 — học');
    expect(adminContentTitle('vocabulary', {'word': '学生', 'hiragana': 'がくせい'}), '学生 (がくせい)');
  });
}
