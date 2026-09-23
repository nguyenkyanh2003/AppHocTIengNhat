import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../models/lesson_video.dart';
import 'lesson_transcript_view.dart';
import 'lesson_video_player.dart';

/// Khối "Video bài học": chọn video, xem video và đọc lời thoại chạy theo.
///
/// Màn rộng đặt video bên trái và lời thoại bên phải như trang gốc; màn hẹp
/// xếp dọc. Cùng một widget cho web và điện thoại, chỉ khác bố cục.
class LessonVideoSection extends StatefulWidget {
  const LessonVideoSection({super.key, required this.videos});

  final List<LessonVideo> videos;

  /// Dưới bề rộng này thì xếp dọc: hai cột sẽ làm khung video quá nhỏ.
  static const double twoColumnMinWidth = 900;

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
    super.dispose();
  }

  void _syncActiveLine() {
    final controller = _controller;
    if (controller == null) return;

    final index =
        activeTranscriptIndex(_video.transcript, controller.value.position);
    if (index != _activeLine.value) _activeLine.value = index;
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
              // Một cột nằm trong trang đang cuộn: lời thoại dàn hết chiều
              // cao, trang lo việc cuộn.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  player,
                  AppGap.lg,
                  transcript(scrollable: false),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: player),
                AppGap.lg,
                Expanded(
                  flex: 5,
                  // Chiều cao cố định để phần lời thoại tự cuộn trong khung,
                  // thay vì kéo dài cả trang khi video có nhiều dòng.
                  child: SizedBox(
                    height: 420,
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
