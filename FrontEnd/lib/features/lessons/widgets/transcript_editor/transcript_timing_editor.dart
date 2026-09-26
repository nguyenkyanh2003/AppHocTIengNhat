import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../models/lesson_video.dart';
import '../../providers/transcript_timing_session.dart';
import '../video/lesson_video_player.dart';
import 'timing_line_list.dart';

/// Canh mốc lời thoại cho **một** video: dán câu, xem video, bấm Space đúng
/// lúc từng câu bắt đầu, rồi sao chép kết quả vào file `.txt` của bài.
///
/// Mỗi video một widget (màn cha đặt `key` theo video), nên đổi video là bắt
/// đầu lại sạch: trình phát, câu đã dán và mốc đã canh đều thuộc về video đó.
class TranscriptTimingEditor extends StatefulWidget {
  const TranscriptTimingEditor({super.key, required this.video});

  final LessonVideo video;

  @override
  State<TranscriptTimingEditor> createState() => _TranscriptTimingEditorState();
}

class _TranscriptTimingEditorState extends State<TranscriptTimingEditor> {
  final TranscriptTimingSession _session = TranscriptTimingSession();
  final TextEditingController _input = TextEditingController();
  late final VideoPlayerController _controller =
      VideoPlayerController.networkUrl(Uri.parse(widget.video.playbackUrl));
  bool _ready = false;
  String? _videoError;
  bool _timing = false;

  /// `uploads/lesson-videos/<bài>/<file>` → tên file video và tên file `.txt`.
  late final List<String> _urlParts = widget.video.url.split('/');
  String get _fileName => _urlParts.last;
  String get _lessonDir => _urlParts.length > 1 ? _urlParts[_urlParts.length - 2] : '';

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSessionChanged);
    _controller.initialize().then(
          (_) => mounted ? setState(() => _ready = true) : null,
          onError: (_) => mounted ? setState(() => _videoError = 'Không mở được video này.') : null,
        );
  }

  @override
  void dispose() {
    _session.dispose();
    _input.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    final message = _session.consumeMessage();
    if (message != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    setState(() {});
  }

  /// Vị trí đọc thẳng từ trình phát chứ không lấy giá trị cập nhật định kỳ,
  /// để mốc lệch ít nhất có thể so với lúc bấm.
  Future<void> _mark() async {
    final position = await _controller.position ?? _controller.value.position;
    _session.mark(position);
  }

  void _togglePlay() => _controller.value.isPlaying ? _controller.pause() : _controller.play();

  void _seekBack() => _controller.seekTo(_controller.value.position - const Duration(seconds: 3));

  void _startTiming() {
    _controller.seekTo(Duration.zero);
    setState(() => _timing = true);
  }

  void _editLines() {
    _controller.pause();
    _session.restart();
    setState(() => _timing = false);
  }

  Future<void> _copyOutput() async {
    await Clipboard.setData(ClipboardData(text: _session.output(fileName: _fileName, title: widget.video.title)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã sao chép. Dán vào BackEnd/data/lesson-videos/$_lessonDir.txt, thay phần "## $_fileName".')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LessonVideoPlayer(
          controller: _controller,
          isReady: _ready,
          errorMessage: _videoError,
        ),
        AppGap.lg,
        if (_timing) _timingPhase(context) else _inputPhase(context),
      ],
    );
  }

  Widget _inputPhase(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('1. Dán câu thoại của video này, mỗi câu một dòng:', style: textTheme.titleSmall),
        AppGap.xs,
        Text(
          'người nói JA / VI | câu tiếng Nhật | roma-ji | nghĩa tiếng Việt',
          style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        AppGap.sm,
        TextField(
          controller: _input,
          minLines: 6,
          maxLines: 14,
          onChanged: _session.load,
          decoration: const InputDecoration(
            hintText: 'オウ / Ou | おはようございます。 | Ohayoo gozaimasu. | Chào buổi sáng.',
          ),
        ),
        for (final error in _session.errors) ...[
          AppGap.xs,
          Text(error, style: textTheme.bodySmall?.copyWith(color: AppColors.error)),
        ],
        AppGap.md,
        FilledButton.icon(
          onPressed: _session.canStart && _ready ? _startTiming : null,
          icon: const Icon(Icons.timer_outlined),
          label: Text(_session.lines.isEmpty ? 'Bắt đầu canh giờ' : 'Bắt đầu canh giờ ${_session.lines.length} câu'),
        ),
      ],
    );
  }

  Widget _timingPhase(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final session = _session;

    // Nút không nhận focus: bấm chuột vào nút rồi nhấn Space thì Space vẫn là
    // "đánh dấu câu", không thành bấm lại cái nút vừa chạm.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): _mark,
        const SingleActivator(LogicalKeyboardKey.backspace): session.undo,
        const SingleActivator(LogicalKeyboardKey.keyP): _togglePlay,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _seekBack,
      },
      child: Focus(
        autofocus: true,
        child: ExcludeFocus(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                session.isComplete
                    ? '3. Xong ${session.lines.length} câu. Sao chép kết quả vào file lời thoại của bài.'
                    : '2. Phát video, nhấn Space đúng lúc câu được tô sáng bắt đầu '
                        '(${session.nextIndex + 1}/${session.lines.length}).',
                style: textTheme.titleSmall,
              ),
              AppGap.xs,
              Text(
                'Space: đánh dấu · Backspace: hoàn tác · P: phát/tạm dừng · ←: lùi 3 giây',
                style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              AppGap.md,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilledButton.icon(
                    onPressed: session.isComplete ? null : _mark,
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Đánh dấu câu'),
                  ),
                  OutlinedButton.icon(
                    onPressed: session.starts.isEmpty ? null : session.undo,
                    icon: const Icon(Icons.undo),
                    label: const Text('Hoàn tác'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _editLines,
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Sửa câu thoại'),
                  ),
                  if (session.isComplete)
                    FilledButton.icon(
                      onPressed: _copyOutput,
                      icon: const Icon(Icons.copy),
                      label: const Text('Sao chép kết quả'),
                    ),
                ],
              ),
              AppGap.lg,
              TimingLineList(lines: session.lines, starts: session.starts),
            ],
          ),
        ),
      ),
    );
  }
}
