import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../models/lesson_video.dart';
import 'lesson_transcript_view.dart';
import 'lesson_video_player.dart';

/// Khối "Video bài học": chọn video, xem video và đọc lời thoại chạy theo.
///
/// Video và lời thoại luôn cùng nằm trong tầm nhìn: màn rộng đặt lời thoại
/// bên phải video, màn hẹp đặt lời thoại trong một khung cuộn riêng ngay dưới
/// video. Lời thoại không bao giờ dàn dài theo trang — cuộn xuống đọc mà video
/// trôi khỏi màn hình thì không còn "xem kèm lời thoại" nữa.
class LessonVideoSection extends StatefulWidget {
  const LessonVideoSection({super.key, required this.videos});

  final List<LessonVideo> videos;

  /// Dưới bề rộng này thì xếp dọc: hai cột sẽ làm khung video quá nhỏ.
  static const double twoColumnMinWidth = 840;

  /// Chiều cao khung lời thoại khi xếp dọc, tính theo màn hình để video phía
  /// trên vẫn còn chỗ.
  static double stackedTranscriptHeight(double screenHeight) =>
      (screenHeight * 0.4).clamp(220.0, 420.0);

  @override
  State<LessonVideoSection> createState() => _LessonVideoSectionState();
}

class _LessonVideoSectionState extends State<LessonVideoSection> {
  VideoPlayerController? _controller;

  /// Dòng lời thoại đang được nói.
  ///
  /// Tách riêng khỏi `setState` vì vị trí phát đổi vài chục lần mỗi giây:
  /// dựng lại cả bảng lời thoại theo từng nhịp đó làm giao diện giật. Ở đây
  /// chỉ phát tín hiệu khi **đổi dòng**, nên bảng dựng lại vài lần mỗi video.
  final ValueNotifier<int?> _activeLine = ValueNotifier<int?>(null);

  /// Lớp chữ đang bật (日本語 / Roma-ji / Tiếng Việt), dùng chung cho bảng lời
  /// thoại và phụ đề toàn màn hình: người học đã tắt tiếng Việt để tự luyện
  /// thì vào toàn màn hình nó cũng không tự bật lại.
  final ValueNotifier<Set<TranscriptLayer>> _layers =
      ValueNotifier({...TranscriptLayer.values});

  int _index = 0;
  bool _ready = false;
  String? _error;

  LessonVideo get _video => widget.videos[_index];

  @override
  void initState() {
    super.initState();
    _open(_index);
  }

  @override
  void dispose() {
    _controller?.removeListener(_syncActiveLine);
    _controller?.dispose();
    _activeLine.dispose();
    _layers.dispose();
    super.dispose();
  }

  void _syncActiveLine() {
    final controller = _controller;
    if (controller == null) return;

    final index =
        activeTranscriptIndex(_video.transcript, controller.value.position);
    if (index != _activeLine.value) _activeLine.value = index;
  }

  /// Câu đang nói, hoặc câu gần nhất đã qua khi đang ở khoảng lặng; `-1`
  /// khi video chưa tới câu đầu tiên.
  int _currentLine(VideoPlayerController controller) {
    final active = _activeLine.value;
    if (active != null) return active;
    final position = controller.value.position;
    return _video.transcript.lastIndexWhere((line) => line.start <= position);
  }

  /// Nhảy tới câu cách câu hiện tại [offset] câu (0 là nghe lại) rồi phát.
  Future<void> _seekLine(int offset) async {
    final controller = _controller;
    final lines = _video.transcript;
    if (controller == null || lines.isEmpty) return;
    final target = (_currentLine(controller) + offset).clamp(0, lines.length - 1);
    await controller.seekTo(lines[target].start);
    await controller.play();
  }

  Future<void> _open(int index) async {
    final previous = _controller;
    final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videos[index].playbackUrl));

    previous?.removeListener(_syncActiveLine);
    controller.addListener(_syncActiveLine);
    _activeLine.value = null;

    setState(() {
      _index = index;
      _controller = controller;
      _ready = false;
      _error = null;
    });
    // Dọn controller cũ **sau** khi đã thay vào state, để không có khung hình
    // nào trỏ tới controller đã huỷ.
    await previous?.dispose();

    try {
      await controller.initialize();
      // Vị trí phát đổi liên tục nên chỉ vẽ lại phần cần: lời thoại lắng nghe
      // controller qua `ValueListenableBuilder` ở dưới.
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Không mở được video này.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (widget.videos.isEmpty || controller == null) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;

    final player = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LessonVideoPlayer(
          controller: controller,
          isReady: _ready,
          errorMessage: _error,
          onRetry: () => _open(_index),
          fullscreenCaption: ValueListenableBuilder<int?>(
            valueListenable: _activeLine,
            builder: (context, active, _) => ValueListenableBuilder<Set<TranscriptLayer>>(
              valueListenable: _layers,
              builder: (context, layers, _) => TranscriptCaption(
                line: active == null ? null : _video.transcript[active],
                layers: layers,
              ),
            ),
          ),
          navigation: _video.transcript.isEmpty
              ? null
              : TranscriptNavigation(
                  previous: () => _seekLine(-1),
                  replay: () => _seekLine(0),
                  next: () => _seekLine(1),
                ),
        ),
        AppGap.sm,
        Text(_video.title, style: textTheme.titleMedium),
        if (_video.description != null) ...[
          AppGap.xs,
          Text(_video.description!, style: textTheme.bodyMedium),
        ],
        if (_video.source != null) ...[
          AppGap.xs,
          Text('Nguồn: ${_video.source!}', style: textTheme.labelSmall),
        ],
      ],
    );

    Widget transcript({required bool scrollable}) =>
        ValueListenableBuilder<int?>(
          valueListenable: _activeLine,
          builder: (context, activeIndex, _) => LessonTranscriptView(
            lines: _video.transcript,
            activeIndex: activeIndex,
            layers: _layers,
            scrollable: scrollable,
            onSeek: (position) async {
              await controller.seekTo(position);
              await controller.play();
            },
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.videos.length > 1) ...[
          _VideoPicker(
            videos: widget.videos,
            selected: _index,
            onSelected: _open,
          ),
          AppGap.lg,
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= LessonVideoSection.twoColumnMinWidth;
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  player,
                  AppGap.lg,
                  SizedBox(
                    height: LessonVideoSection.stackedTranscriptHeight(
                        MediaQuery.sizeOf(context).height),
                    child: transcript(scrollable: true),
                  ),
                ],
              );
            }

            // Khung lời thoại cao bằng khung video 16:9 cộng thanh điều khiển
            // và tên cảnh, để hai cột kết thúc cùng một đường ngang.
            const gap = AppSpacing.lg;
            final playerWidth = (constraints.maxWidth - gap) * 6 / 11;
            final transcriptHeight = playerWidth * 9 / 16 + 120;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: player),
                const SizedBox(width: gap),
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: transcriptHeight,
                    child: transcript(scrollable: true),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _VideoPicker extends StatelessWidget {
  const _VideoPicker({
    required this.videos,
    required this.selected,
    required this.onSelected,
  });

  final List<LessonVideo> videos;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (var index = 0; index < videos.length; index++)
          ChoiceChip(
            label: Text('${index + 1}. ${videos[index].title}'),
            selected: index == selected,
            onSelected: (_) => onSelected(index),
          ),
      ],
    );
  }
}
