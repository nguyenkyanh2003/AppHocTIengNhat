import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/features/admin/utils/admin_content_csv.dart';

void main() {
  test('CSV decoder handles quoted commas and vocabulary aliases', () {
    final rows = AdminContentCsv.decode(
      'vocabulary',
      utf8.encode(
        'word,reading,meaning,level,lesson,usage_context\r\n'
        '学生,がくせい,"học sinh, sinh viên",N5,lesson-1,trường học\r\n',
      ),
    );

    expect(rows, hasLength(1));
    expect(rows.single['hiragana'], 'がくせい');
    expect(rows.single['meaning'], 'học sinh, sinh viên');
    expect(rows.single['lesson'], 'lesson-1');
  });

  test('CSV decoder normalizes Kanji reading lists', () {
    final rows = AdminContentCsv.decode(
      'kanji',
      utf8.encode(
        'character,meaning,level,lessonId,onyomi,kunyomi\n'
        '日,ngày,N5,lesson-1,"ニチ; ジツ","ひ、か"\n',
      ),
    );

    expect(rows.single['onyomi'], ['ニチ', 'ジツ']);
    expect(rows.single['kunyomi'], ['ひ', 'か']);
  });

  test('CSV encoder preserves nested values and Excel UTF-8 BOM', () {
    final bytes = AdminContentCsv.encode('kanji', [
      {
        '_id': '1',
        'character': '日',
        'onyomi': ['ニチ', 'ジツ'],
        'meaning': 'ngày',
        'level': 'N5',
      },
    ]);

    expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    final csv = utf8.decode(bytes.skip(3).toList());
    expect(csv, contains('ニチ|ジツ'));
    expect(csv, contains('"日"'));
  });
}
