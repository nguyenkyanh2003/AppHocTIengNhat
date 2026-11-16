import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/features/admin/models/admin_content_type.dart';
import 'package:apphoctiengnnhat/features/admin/widgets/admin_content_format.dart';

void main() {
  test('cột nội dung của bảng quản trị có chữ cho mọi loại, kể cả từ vựng', () {
    expect(adminContentHeadline(AdminContentType.vocabulary, {'word': '学生', 'hiragana': 'がくせい'}), '学生 (がくせい)');
    expect(adminContentHeadline(AdminContentType.kanji, {'character': '学', 'meaning': 'học'}), '学');
    expect(adminContentHeadline(AdminContentType.grammar, {'title': '〜てもいい', 'structure': 'V-て + もいい'}), '〜てもいい');
    expect(adminContentHeadline(AdminContentType.lessons, {'title': 'Tình huống: Đi tàu'}), 'Tình huống: Đi tàu');
  });

  test('tiêu đề trong hộp xác nhận xoá kèm nghĩa để không xoá nhầm', () {
    expect(adminContentTitle(AdminContentType.kanji, {'character': '学', 'meaning': 'học'}), '学 — học');
    expect(adminContentTitle(AdminContentType.vocabulary, {'word': '学生', 'hiragana': 'がくせい'}), '学生 (がくせい)');
  });

  test('tham chiếu đọc được cả id trần lẫn document đã populate', () {
    expect(adminContentReferenceId('l1'), 'l1');
    expect(adminContentReferenceId({'_id': 'l2', 'title': 'Bài 2'}), 'l2');
    expect(adminContentReferenceId('  '), isNull);
  });
}
