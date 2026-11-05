import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/features/grammar/models/grammar.dart';

void main() {
  // Đúng dạng `GET /api/grammar/:id` đang trả: ví dụ là object, mẫu câu nằm ở `structure`.
  const apiJson = <String, dynamic>{
    '_id': 'g1',
    'title': 'が (ga)',
    'structure': 'Danh từ + が + ...',
    'meaning': 'Trợ từ chỉ chủ ngữ',
    'usage': 'Đánh dấu chủ ngữ của câu, nhấn mạnh',
    'level': 'N5',
    'examples': [
      {'sentence': '誰が来ましたか。', 'meaning': 'Ai đã đến?'},
      {'sentence': '水が欲しいです。'},
    ],
    'view_count': 6,
    'createdAt': '2026-09-08 10:09:20',
  };

  test('đọc được ví dụ dạng object của API', () {
    final grammar = Grammar.fromJson(apiJson);

    expect(grammar.examples, ['誰が来ましたか。\nAi đã đến?', '水が欲しいです。']);
  });

  test('đọc mẫu câu và cách dùng từ đúng tên trường của API', () {
    final grammar = Grammar.fromJson(apiJson);

    expect(grammar.pattern, 'Danh từ + が + ...');
    expect(grammar.explanation, 'Đánh dấu chủ ngữ của câu, nhấn mạnh');
  });

  test('vẫn đọc được ví dụ dạng chuỗi và bỏ ví dụ rỗng', () {
    final grammar = Grammar.fromJson({
      ...apiJson,
      'examples': ['Câu ví dụ', <String, dynamic>{}],
    });

    expect(grammar.examples, ['Câu ví dụ']);
  });
}
