import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/app/theme/calm_colors.dart';
import 'package:apphoctiengnnhat/features/news/models/news.dart';
import 'package:apphoctiengnnhat/features/news/providers/news_provider.dart';
import 'package:apphoctiengnnhat/features/news/widgets/news_carousel_widget.dart';

/// Nguồn tin giả: danh sách do test đặt, không gọi mạng.
class _FakeNewsProvider extends NewsProvider {
  _FakeNewsProvider(this.items);

  final List<News> items;
  int loads = 0;

  @override
  List<News> get newsList => items;

  @override
  Future<void> loadNews({bool refresh = false, String? level, String? search}) async => loads++;
}

News _news(int i, {String? level = 'N4', String? title}) => News(
      id: 'n$i',
      title: title ?? 'Tin số $i',
      description: '',
      contentHtml: '',
      level: level,
      views: 10,
      createdAt: DateTime(2026, 9, 1),
    );

Future<void> _pump(
  WidgetTester tester,
  _FakeNewsProvider provider, {
  ThemeData? theme,
  TextScaler textScaler = TextScaler.noScaling,
}) =>
    tester.pumpWidget(ChangeNotifierProvider<NewsProvider>.value(
      value: provider,
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        home: MediaQuery(
          data: MediaQueryData(textScaler: textScaler),
          child: const Scaffold(
            body: SingleChildScrollView(child: NewsCarouselWidget(header: Text('Tiêu đề mục'))),
          ),
        ),
      ),
    ));

/// Hộp của từng thẻ tin (mỗi thẻ là một `Material` có viền bo 18).
Iterable<Material> _cards(WidgetTester tester) => tester
    .widgetList<Material>(find.byType(Material))
    .where((m) => m.shape is RoundedRectangleBorder && (m.shape as RoundedRectangleBorder).side != BorderSide.none);

void main() {
  testWidgets('hiện tiêu đề mục được truyền vào và tối đa 5 bài', (tester) async {
    await _pump(tester, _FakeNewsProvider([for (var i = 1; i <= 7; i++) _news(i)]));
    await tester.pump();

    expect(find.text('Tiêu đề mục'), findsOneWidget);
    expect(find.text('Tin số 1'), findsOneWidget);
    expect(find.text('Tin số 6'), findsNothing, reason: 'chỉ lấy 5 bài mới nhất');
  });

  testWidgets('dòng phụ là trình độ và ngày đăng (chưa có chuyên mục / thời gian đọc)', (tester) async {
    await _pump(tester, _FakeNewsProvider([_news(1), _news(2, level: null)]));
    await tester.pump();

    expect(find.textContaining('N4 · '), findsOneWidget);
    expect(find.textContaining('phút đọc'), findsNothing, reason: 'không tự bịa thời gian đọc');
  });

  testWidgets('thẻ rộng 260, viền 1px theo bảng màu, không đổ bóng', (tester) async {
    await _pump(tester, _FakeNewsProvider([_news(1), _news(2)]));
    await tester.pump();

    final card = _cards(tester).first;
    expect(card.elevation, 0);
    expect((card.shape as RoundedRectangleBorder).side.color, CalmColors.light.cardBorder);
    expect(tester.getSize(find.byWidget(card)).width, 260);
  });

  testWidgets('tiêu đề tiếng Nhật hai dòng không tràn, kể cả khi phóng to chữ; thẻ cao bằng nhau', (tester) async {
    const long = '日本のファッション：着物からストリートファッションまで、若者に人気のスタイルを紹介します';
    await _pump(
      tester,
      // Một thẻ tiêu đề ngắn cạnh một thẻ tiêu đề hai dòng: đúng ca từng bị cắt dòng phụ.
      _FakeNewsProvider([_news(1, level: null), _news(2, title: long)]),
      textScaler: const TextScaler.linear(1.3),
    );
    await tester.pump();

    // Tràn thì Flutter ném lỗi "BOTTOM OVERFLOWED" và test đỏ ngay ở đây.
    expect(tester.takeException(), isNull);
    final heights = _cards(tester).map((card) => tester.getSize(find.byWidget(card)).height).toSet();
    expect(heights.length, 1, reason: 'các thẻ cao bằng nhau');
  });

  testWidgets('chưa có bài nào thì không chiếm chỗ (kể cả tiêu đề mục) và tự nạp tin', (tester) async {
    final provider = _FakeNewsProvider([]);
    await _pump(tester, provider);
    await tester.pump();

    expect(find.text('Tiêu đề mục'), findsNothing);
    expect(provider.loads, 1);
  });

  testWidgets('chế độ tối: thẻ lấy màu thẻ tối của bảng màu, không trắng', (tester) async {
    await _pump(tester, _FakeNewsProvider([_news(1)]), theme: AppTheme.darkTheme);
    await tester.pump();

    expect(_cards(tester).first.color, CalmColors.dark.card);
  });
}
