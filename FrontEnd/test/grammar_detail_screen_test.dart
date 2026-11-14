import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apphoctiengnnhat/features/grammar/providers/grammar_provider.dart';
import 'package:apphoctiengnnhat/features/grammar/screens/grammar_detail_screen.dart';

final _client = MockClient((request) async => http.Response(
      jsonEncode({'data': {
        '_id': 'g1',
        'title': 'が (ga)',
        'structure': 'Danh từ + が',
        'meaning': 'Trợ từ chỉ chủ ngữ',
        'usage': 'Đánh dấu chủ ngữ',
        'level': 'N5',
        'examples': [
          {'sentence': '誰が来ましたか。', 'meaning': 'Ai đã đến?'},
        ],
      }}),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    ));

void main() {
  testWidgets('mở được ngữ pháp có ví dụ dạng object; đầu trang và các khối chiếm hết bề rộng', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await http.runWithClient(() async {
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => GrammarProvider(),
        child: const MaterialApp(home: GrammarDetailScreen(grammarId: 'g1')),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }, () => _client);

    expect(find.text('Không tìm thấy ngữ pháp'), findsNothing);
    expect(find.text('誰が来ましたか。\nAi đã đến?'), findsOneWidget);

    double containerWidthAround(String text) => tester
        .getSize(find.ancestor(of: find.text(text), matching: find.byType(Container)).first)
        .width;

    expect(containerWidthAround('Pattern: Danh từ + が'), 500, reason: 'đầu trang');
    expect(containerWidthAround('Trợ từ chỉ chủ ngữ'), greaterThan(400), reason: 'khối nội dung');
  });
}
