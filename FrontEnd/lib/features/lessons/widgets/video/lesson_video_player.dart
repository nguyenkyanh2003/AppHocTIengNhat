import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/platform/fullscreen.dart';

/// Điều hướng theo **câu thoại** — thứ người học cần hơn thanh tua: nghe lại
/// câu vừa nói, lùi một câu, sang câu kế. `null` khi video không có lời thoại.
class TranscriptNavigation {
  const TranscriptNavigation({
    required this.previous,
    required this.replay,
    required this.next,
  });

  final VoidCallback previous;
  final VoidCallback replay;
  final VoidCallback next;
}

/// Khung phát video kèm thanh điều khiển gọn: phát/dừng, lùi 5 giây, tua,
/// thời gian và nút toàn màn hình ở góc phải.
///
/// Dùng `video_player` nên chạy được cả trên web lẫn thiết bị. Controller do
/// widget cha giữ, vì phần lời thoại cũng cần vị trí phát hiện tại.
class LessonVideoPlayer extends StatefulWidget {
  const LessonVideoPlayer({
    super.key,
    required this.controller,
    required this.isReady,
    this.errorMessage,
    this.onRetry,
    this.fullscreenCaption,
    this.navigation,
  });

  final VideoPlayerController controller;
  final bool isReady;
  final String? errorMessage;
  final VoidCallback? onRetry;

  /// Phụ đề đặt đè lên video khi xem toàn màn hình (thường là câu đang nói,
  /// theo đúng các lớp chữ người học đã bật ở bảng lời thoại).
  final Widget? fullscreenCaption;

  /// Nút câu trước / nghe lại câu / câu sau ở chế độ toàn màn hình.
  final TranscriptNavigation? navigation;

  static String formatDuration(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return value.inHours > 0
        ? '${value.inHours}:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  State<LessonVideoPlayer> createState() => _LessonVideoPlayerState();
}

class _LessonVideoPlayerState extends State<LessonVideoPlayer> {
  bool _fullscreen = false;

  /// Tăng mỗi lần thoát toàn màn hình để dựng lại khung video trong trang.
  ///
  /// Trên web, mỗi controller chỉ có **một** thẻ `<video>`; khung toàn màn
  /// hình mượn nó đi, và khung cũ phải được tạo mới thì mới lấy lại được —
  /// nếu không, video trong trang đen sau khi thoát toàn màn hình.
  int _generation = 0;

  Future<void> _openFullscreen() async {
    setState(() => _fullscreen = true);
    await Navigator.of(context, rootNavigator: true).push(PageRouteBuilder<void>(
      opaque: true,
      pageBuilder: (_, __, ___) => _FullscreenVideoPage(
        controller: widget.controller,
        caption: widget.fullscreenCaption,
        navigation: widget.navigation,
      ),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ));
    if (!mounted) return;
    setState(() {
      _fullscreen = false;
      _generation++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final isReady = widget.isReady;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: AppRadius.lgAll,
          child: AspectRatio(
            aspectRatio: isReady ? controller.value.aspectRatio : 16 / 9,
            child: ColoredBox(
              color: AppColors.textPrimary,
              child: switch ((widget.errorMessage, isReady)) {
                (final String message, _) => _VideoError(
                    message: message,
                    onRetry: widget.onRetry,
                  ),
                (_, false) => const Center(child: CircularProgressIndicator()),
                // Đang xem toàn màn hình: khung trong trang nhường thẻ video,
                // chỉ còn một dòng nhắc để không hiện hai trình phát cùng lúc.
                _ when _fullscreen => const Center(
                    child: Icon(Icons.fullscreen, size: 48, color: Colors.white54),
                  ),
                _ => Stack(
                    key: ValueKey(_generation),
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(controller),
                      _PlayOverlay(controller: controller),
                    ],
                  ),
              },
            ),
          ),
        ),
        if (isReady && widget.errorMessage == null) ...[
          AppGap.sm,
          _Controls(controller: controller, onFullscreen: _openFullscreen),
        ],
      ],
    );
  }
}

/// Bấm vào khung video để phát/dừng; khi dừng hiện nút play lớn ở giữa.
class _PlayOverlay extends StatelessWidget {
  const _PlayOverlay({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) => GestureDetector(
        onTap: () => value.isPlaying ? controller.pause() : controller.play(),
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: AppDurations.fast,
          opacity: value.isPlaying ? 0 : 1,
          child: const CircleAvatar(
            radius: AppSpacing.xxl,
            backgroundColor: Colors.black54,
            child: Icon(
              Icons.play_arrow_rounded,
              size: AppSpacing.xxl,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.controller, required this.onFullscreen});

  final VideoPlayerController controller;
  final VoidCallback onFullscreen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final position = _clampedPosition(value);

        return Row(
          children: [
            IconButton(
              tooltip: value.isPlaying ? 'Tạm dừng' : 'Phát',
              onPressed: () => _togglePlay(controller),
              icon: Icon(value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
            ),
            IconButton(
              tooltip: 'Lùi 5 giây',
              onPressed: () => controller.seekTo(position - const Duration(seconds: 5)),
              icon: const Icon(Icons.replay_5_rounded),
            ),
            Expanded(child: _SeekBar(controller: controller, value: value)),
            Text(_timeLabel(value), style: textTheme.labelMedium),
            IconButton(
              tooltip: 'Toàn màn hình',
              onPressed: onFullscreen,
              icon: const Icon(Icons.fullscreen_rounded),
            ),
          ],
        );
      },
    );
  }
}

Duration _clampedPosition(VideoPlayerValue value) =>
    value.position > value.duration ? value.duration : value.position;

String _timeLabel(VideoPlayerValue value) =>
    '${LessonVideoPlayer.formatDuration(_clampedPosition(value))} / '
    '${LessonVideoPlayer.formatDuration(value.duration)}';

void _togglePlay(VideoPlayerController controller) =>
    controller.value.isPlaying ? controller.pause() : controller.play();

class _SeekBar extends StatelessWidget {
  const _SeekBar({required this.controller, required this.value});

  final VideoPlayerController controller;
  final VideoPlayerValue value;

  @override
  Widget build(BuildContext context) {
    final duration = value.duration;
    return Slider(
      value: _clampedPosition(value).inMilliseconds.clamp(0, duration.inMilliseconds).toDouble(),
      max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
      onChanged: (milliseconds) => controller.seekTo(Duration(milliseconds: milliseconds.round())),
    );
  }
}

/// Video phủ kín màn hình, kèm phụ đề câu đang nói và các nút học.
///
/// Thoát bằng nút thu nhỏ, Esc, nút Back, hoặc nút thoát toàn màn hình của
/// trình duyệt — đường nào cũng trả về trang cũ, và bảng lời thoại ở đó vẫn
/// đang đứng đúng câu vừa phát vì nó tự cuộn theo video suốt lúc xem.
class _FullscreenVideoPage extends StatefulWidget {
  const _FullscreenVideoPage({
    required this.controller,
    required this.caption,
    required this.navigation,
  });

  final VideoPlayerController controller;
  final Widget? caption;
  final TranscriptNavigation? navigation;

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  late final void Function() _stopListening;

  @override
  void initState() {
    super.initState();
    enterFullscreen();
    _stopListening = listenFullscreenExit(_close);
  }

  @override
  void dispose() {
    _stopListening();
    exitFullscreen();
    super.dispose();
  }

  void _close() {
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _close,
        const SingleActivator(LogicalKeyboardKey.space): () => _togglePlay(controller),
        if (widget.navigation case final nav?) ...{
          const SingleActivator(LogicalKeyboardKey.arrowLeft): nav.previous,
          const SingleActivator(LogicalKeyboardKey.arrowRight): nav.next,
          const SingleActivator(LogicalKeyboardKey.keyR): nav.replay,
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () => _togglePlay(controller),
                    child: AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: IconButton(
                    tooltip: 'Thoát toàn màn hình (Esc)',
                    onPressed: _close,
                    color: Colors.white,
                    icon: const Icon(Icons.fullscreen_exit_rounded),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _FullscreenBottom(
                    controller: controller,
                    caption: widget.caption,
                    navigation: widget.navigation,
                    onExit: _close,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Phụ đề và thanh điều khiển ở đáy khung toàn màn hình, trên nền mờ dần để
/// chữ trắng đọc được trên mọi cảnh.
class _FullscreenBottom extends StatelessWidget {
  const _FullscreenBottom({
    required this.controller,
    required this.caption,
    required this.navigation,
    required this.onExit,
  });

  final VideoPlayerController controller;
  final Widget? caption;
  final TranscriptNavigation? navigation;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black87],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, AppSpacing.sm),
        child: ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final nav = navigation;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (caption != null) ...[caption!, AppGap.md],
                IconTheme(
                  data: const IconThemeData(color: Colors.white),
                  child: Row(
                    children: [
                      if (nav != null)
                        IconButton(tooltip: 'Câu trước (←)', onPressed: nav.previous, icon: const Icon(Icons.skip_previous_rounded)),
                      IconButton(
                        tooltip: value.isPlaying ? 'Tạm dừng (Space)' : 'Phát (Space)',
                        onPressed: () => _togglePlay(controller),
                        icon: Icon(value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 32),
                      ),
                      if (nav != null) ...[
                        IconButton(tooltip: 'Nghe lại câu này (R)', onPressed: nav.replay, icon: const Icon(Icons.replay_rounded)),
                        IconButton(tooltip: 'Câu sau (→)', onPressed: nav.next, icon: const Icon(Icons.skip_next_rounded)),
                      ] else
                        IconButton(
                          tooltip: 'Lùi 5 giây',
                          onPressed: () => controller.seekTo(_clampedPosition(value) - const Duration(seconds: 5)),
                          icon: const Icon(Icons.replay_5_rounded),
                        ),
                      Expanded(child: _SeekBar(controller: controller, value: value)),
                      Text(_timeLabel(value), style: textTheme.labelMedium?.copyWith(color: Colors.white)),
                      IconButton(tooltip: 'Thoát toàn màn hình (Esc)', onPressed: onExit, icon: const Icon(Icons.fullscreen_exit_rounded)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _VideoError extends StatelessWidget {
  const _VideoError({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_outlined, color: Colors.white70),
            AppGap.sm,
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            if (onRetry != null) ...[
              AppGap.sm,
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
