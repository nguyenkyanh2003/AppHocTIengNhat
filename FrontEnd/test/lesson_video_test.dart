import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:apphoctiengnnhat/app/theme/app_tokens.dart';
import 'package:apphoctiengnnhat/features/lessons/models/lesson.dart';
import 'package:apphoctiengnnhat/features/lessons/models/lesson_video.dart';
import 'package:apphoctiengnnhat/features/lessons/widgets/video/lesson_transcript_view.dart';
import 'package:apphoctiengnnhat/features/lessons/widgets/video/lesson_video_player.dart';
import 'package:apphoctiengnnhat/features/lessons/widgets/video/lesson_video_section.dart';
import 'package:video_player/video_player.dart';

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
      expect(video.duration, isNull);
    });

    test('đọc thời lượng backend đã đo sẵn từ file', () {
      final video = LessonVideo.fromJson({'title': 'V', 'url': '/a.mp4', 'duration_seconds': 36.8});
      expect(video.duration, const Duration(milliseconds: 36800));
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

  group('khối video', () {
    Future<void> pumpSection(WidgetTester tester, LessonVideo video) =>
        tester.pumpWidget(MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: LessonVideoSection(videos: [video]))),
        ));

    testWidgets('mở bài chỉ hiện khung chờ, chưa tạo trình phát nào', (tester) async {
      await pumpSection(
        tester,
        LessonVideo(title: 'Chào buổi sáng', url: '/a.mp4', duration: const Duration(seconds: 37), transcript: _lines),
      );

      expect(find.byType(LessonVideoPoster), findsOneWidget);
      expect(find.byType(VideoPlayer), findsNothing);
      expect(find.text('00:37'), findsOneWidget);
      // Lời thoại vẫn đọc được trước khi phát.
      expect(find.text('おはようございます。'), findsOneWidget);
    });

    testWidgets('video chưa có lời thoại thì không dựng khung lời thoại trống, và nói rõ lý do', (tester) async {
      await pumpSection(tester, const LessonVideo(title: 'Hỏi đường', url: '/b.mp4'));

      expect(find.byType(LessonVideoPoster), findsOneWidget);
      expect(find.byType(LessonTranscriptView), findsNothing);
      expect(find.text('Hỏi đường'), findsOneWidget);
      expect(find.text('Cảnh này chưa có lời thoại chạy theo video.'), findsOneWidget);
    });

    testWidgets('bấm phát thì lời thoại chạy theo video: câu đang nói được tô sáng', (tester) async {
      final platform = _FakeVideoPlatform();
      final previous = VideoPlayerPlatform.instance;
      VideoPlayerPlatform.instance = platform;
      addTearDown(() => VideoPlayerPlatform.instance = previous);

      await pumpSection(tester, LessonVideo(title: 'Chào buổi sáng', url: '/a.mp4', transcript: _lines));
      expect(platform.created, 0, reason: 'mở bài chưa được tạo trình phát');

      await tester.tap(find.byType(LessonVideoPoster));
      await tester.pumpAndSettle();
      expect(platform.created, 1);
      expect(platform.playing, isTrue);

      Color? rowColor(String text) =>
          tester.widget<Material>(find.ancestor(of: find.text(text), matching: find.byType(Material)).first).color;

      platform.position = const Duration(seconds: 9);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(rowColor('いい天気ですね。'), AppColors.primaryLight);
      expect(rowColor('おはようございます。'), Colors.transparent);

      platform.position = const Duration(seconds: 26);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(rowColor('お先に失礼します。'), AppColors.primaryLight);
      expect(rowColor('いい天気ですね。'), Colors.transparent);

      // Gỡ widget để controller dừng bộ đếm vị trí trước khi test kết thúc.
      await tester.pumpWidget(const SizedBox());
    });
  });
}

/// Trình phát giả: vị trí phát do test đặt, không cần video thật.
class _FakeVideoPlatform extends VideoPlayerPlatform {
  int created = 0;
  bool playing = false;
  Duration position = Duration.zero;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async => ++created;

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    late final StreamController<VideoEvent> events;
    events = StreamController<VideoEvent>(
      onListen: () => events.add(VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(seconds: 40),
        size: const Size(1280, 720),
      )),
    );
    return events.stream;
  }

  @override
  Future<void> play(int playerId) async => playing = true;

  @override
  Future<void> pause(int playerId) async => playing = false;

  @override
  Future<Duration> getPosition(int playerId) async => position;

  @override
  Future<void> seekTo(int playerId, Duration position) async => this.position = position;

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Future<void> dispose(int playerId) async {}

  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const ColoredBox(color: Colors.black);
}
