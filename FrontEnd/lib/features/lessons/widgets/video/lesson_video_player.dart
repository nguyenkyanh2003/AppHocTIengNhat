import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../app/theme/app_tokens.dart';

/// Khung phát video kèm thanh điều khiển gọn: play/pause, tua, thời gian.
///
/// Dùng `video_player` nên chạy được cả trên web lẫn thiết bị. Controller do
/// widget cha giữ, vì phần lời thoại cũng cần vị trí phát hiện tại.
class LessonVideoPlayer extends StatelessWidget {
  const LessonVideoPlayer({
    super.key,
    required this.controller,
    required this.isReady,
    this.errorMessage,
    this.onRetry,
  });

  final VideoPlayerController controller;
  final bool isReady;
  final String? errorMessage;
  final VoidCallback? onRetry;

  static String formatDuration(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return value.inHours > 0
        ? '${value.inHours}:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: AppRadius.lgAll,
          child: AspectRatio(
            aspectRatio: isReady ? controller.value.aspectRatio : 16 / 9,
            child: ColoredBox(
              color: AppColors.textPrimary,
              child: switch ((errorMessage, isReady)) {
                (final String message, _) => _VideoError(
                    message: message,
                    onRetry: onRetry,
                  ),
                (_, false) => const Center(child: CircularProgressIndicator()),
                _ => Stack(
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
        if (isReady && errorMessage == null) ...[
          AppGap.sm,
          _Controls(controller: controller),
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
  const _Controls({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final duration = value.duration;
        final position = value.position > duration ? duration : value.position;

        return Row(
          children: [
            IconButton(
              tooltip: value.isPlaying ? 'Tạm dừng' : 'Phát',
              onPressed: () =>
                  value.isPlaying ? controller.pause() : controller.play(),
              icon: Icon(
                value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
            ),
            IconButton(
              tooltip: 'Lùi 5 giây',
              onPressed: () => controller.seekTo(
                position - const Duration(seconds: 5),
              ),
              icon: const Icon(Icons.replay_5_rounded),
            ),
            Expanded(
              child: Slider(
                value: position.inMilliseconds
                    .clamp(0, duration.inMilliseconds)
                    .toDouble(),
                max: duration.inMilliseconds
                    .toDouble()
                    .clamp(1, double.infinity),
                onChanged: (milliseconds) => controller.seekTo(
                  Duration(milliseconds: milliseconds.round()),
                ),
              ),
            ),
            Text(
              '${LessonVideoPlayer.formatDuration(position)} / '
              '${LessonVideoPlayer.formatDuration(duration)}',
              style: textTheme.labelMedium,
            ),
          ],
        );
      },
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
              style: const TextStyle(color: Colors.white70),
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
