import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/features/lessons/models/lesson.dart';
import 'package:apphoctiengnnhat/features/lessons/models/lesson_video.dart';
import 'package:apphoctiengnnhat/features/lessons/widgets/video/lesson_transcript_view.dart';

TranscriptLine _line(int start, int? end, String ja, String vi) =>
    TranscriptLine(
      start: Duration(seconds: start),
      end: end == null ? null : Duration(seconds: end),
      textJa: ja,
      romaji: 'Romaji $ja',
      textVi: vi,
      speakerVi: 'Ou',
    );

final _lines = [
  _line(4, 7, 'おはようございます。', 'Chào buổi sáng.'),
  _line(8, 10, 'いい天気ですね。', 'Thời tiết đẹp nhỉ.'),
  _line(25, null, 'お先に失礼します。', 'Tôi xin phép về trước.'),
];

void main() {
  group('model', () {
    test('đọc JSON của backend, đổi giây sang Duration', () {
      final video = LessonVideo.fromJson({
        'title': 'Chào buổi sáng',
        'url': '/uploads/lesson-videos/n5-01-greeting/scene-1.mp4',
        'source': 'MEXT',
        'transcript': [
          {
            'start_seconds': 4,
            'end_seconds': 7.5,
            'speaker_vi': 'Ou',
            'text_ja': 'おはようございます。',
            'romaji': 'Ohayoo gozaimasu.',
            'text_vi': 'Chào buổi sáng.',
          },
        ],
      });

      expect(video.transcript.single.start, const Duration(seconds: 4));
      expect(video.transcript.single.end, const Duration(milliseconds: 7500));
      expect(video.transcript.single.label, '00:04');
      expect(video.playbackUrl, startsWith('http'));
    });

    test('bài học không có video thì danh sách rỗng, không lỗi', () {
      final lesson =
          Lesson.fromJson({'_id': 'l1', 'title': 'Bài', 'level': 'N5'});
      expect(lesson.videos, isEmpty);
    });

    test('phần tử hỏng trong danh sách video bị bỏ qua', () {
      final videos = LessonVideo.listFromJson([
        {'title': 'Không có url'},
        'chuỗi lạ',
        {'title': 'Có url', 'url': '/a.mp4'},
      ]);
      expect(videos.map((video) => video.title), ['Có url']);
    });
  });

  group('dòng đang nói', () {
    test('trả về dòng có mốc thời gian bao quanh vị trí hiện tại', () {
      expect(activeTranscriptIndex(_lines, const Duration(seconds: 5)), 0);
      expect(activeTranscriptIndex(_lines, const Duration(seconds: 9)), 1);
    });

    test('khoảng lặng giữa hai dòng thì không tô dòng nào', () {
      expect(activeTranscriptIndex(_lines, const Duration(seconds: 2)), isNull);
      expect(
          activeTranscriptIndex(_lines, const Duration(seconds: 12)), isNull);
    });

    test('dòng cuối không có `end` thì sáng tới hết video', () {
      expect(activeTranscriptIndex(_lines, const Duration(seconds: 90)), 2);
    });

    test('tua nhảy thẳng tới giữa video vẫn ra đúng dòng', () {
      expect(activeTranscriptIndex(_lines, const Duration(seconds: 26)), 2);
    });
  });

  group('bảng lời thoại', () {
    Future<void> pump(
      WidgetTester tester, {
      int? activeIndex,
      bool scrollable = true,
      ValueChanged<Duration>? onSeek,
    }) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: scrollable
              ? LessonTranscriptView(
                  lines: _lines,
                  activeIndex: activeIndex,
                  autoScroll: false,
                  onSeek: onSeek ?? (_) {},
                )
              // Bố cục một cột: nằm trong trang cuộn dọc, tức chiều cao không
              // giới hạn — đúng tình huống từng làm màn hình trắng và kẹt.
              : SingleChildScrollView(
                  child: LessonTranscriptView(
                    lines: _lines,
                    activeIndex: activeIndex,
                    scrollable: false,
                    autoScroll: false,
                    onSeek: onSeek ?? (_) {},
                  ),
                ),
        ),
      ));
      await tester.pump();
    }

    testWidgets('hiện cả ba lớp chữ và mốc thời gian', (tester) async {
      await pump(tester);

      expect(find.text('おはようございます。'), findsOneWidget);
      expect(find.text('Romaji おはようございます。'), findsOneWidget);
      expect(find.text('Chào buổi sáng.'), findsOneWidget);
      expect(find.text('00:04'), findsOneWidget);
    });

    testWidgets('tắt một lớp thì lớp đó biến mất, lớp khác giữ nguyên',
        (tester) async {
      await pump(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Roma-ji'));
      await tester.pumpAndSettle();

      expect(find.text('Romaji おはようございます。'), findsNothing);
      expect(find.text('おはようございます。'), findsOneWidget);
      expect(find.text('Chào buổi sáng.'), findsOneWidget);
    });

    testWidgets('không tắt được lớp cuối cùng', (tester) async {
      await pump(tester);

      for (final label in ['Roma-ji', 'Tiếng Việt', '日本語']) {
        await tester.tap(find.widgetWithText(FilterChip, label));
        await tester.pumpAndSettle();
      }

      expect(find.text('おはようございます。'), findsOneWidget);
    });

    testWidgets('nằm trong trang cuộn dọc vẫn dựng được, không lỗi layout',
        (tester) async {
      await pump(tester, scrollable: false, activeIndex: 1);

      expect(tester.takeException(), isNull);
      expect(find.text('Thời tiết đẹp nhỉ.'), findsOneWidget);
    });

    testWidgets('chạm một dòng thì yêu cầu tua tới đúng mốc', (tester) async {
      Duration? seeked;
      await pump(tester, onSeek: (value) => seeked = value);

      await tester.tap(find.text('Thời tiết đẹp nhỉ.'));
      await tester.pump();

      expect(seeked, const Duration(seconds: 8));
    });
  });

  group('phụ đề toàn màn hình', () {
    Future<void> pumpCaption(WidgetTester tester, TranscriptLine? line, Set<TranscriptLayer> layers) =>
        tester.pumpWidget(MaterialApp(home: Scaffold(body: TranscriptCaption(line: line, layers: layers))));

    testWidgets('hiện đúng các lớp chữ người học đã bật', (tester) async {
      await pumpCaption(tester, _lines[0], {TranscriptLayer.japanese, TranscriptLayer.romaji});

      expect(find.text('おはようございます。'), findsOneWidget);
      expect(find.text('Romaji おはようございます。'), findsOneWidget);
      // Đã tắt tiếng Việt ở bảng lời thoại thì toàn màn hình cũng không bật lại.
      expect(find.text('Chào buổi sáng.'), findsNothing);
    });

    testWidgets('khoảng lặng giữa hai câu thì không hiện gì', (tester) async {
      await pumpCaption(tester, null, {...TranscriptLayer.values});
      expect(find.byType(Text), findsNothing);
    });
  });

  testWidgets('bảng lời thoại dùng chung lựa chọn lớp chữ được truyền vào', (tester) async {
    final layers = ValueNotifier<Set<TranscriptLayer>>({...TranscriptLayer.values});
    addTearDown(layers.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LessonTranscriptView(
          lines: _lines,
          activeIndex: null,
          onSeek: (_) {},
          layers: layers,
          autoScroll: false,
        ),
      ),
    ));

    await tester.tap(find.widgetWithText(FilterChip, 'Tiếng Việt'));
    await tester.pump();

    expect(layers.value.contains(TranscriptLayer.vietnamese), isFalse);
    expect(find.text('Chào buổi sáng.'), findsNothing);
  });
}
