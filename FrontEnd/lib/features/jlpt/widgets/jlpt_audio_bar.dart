import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';

/// Thanh phát file nghe của một phần thi. Trình phát dùng chung cả đề nên nằm ở màn thi.
class JlptAudioBar extends StatelessWidget {
  const JlptAudioBar({
    super.key,
    required this.audioPath,
    required this.audioName,
    required this.audioPlayer,
    required this.isPlaying,
    required this.isLoading,
    required this.duration,
    required this.position,
    required this.playAudio,
  });

  final String audioPath;
  final String audioName;
  final AudioPlayer audioPlayer;
  final bool isPlaying;
  final bool isLoading;
  final Duration duration;
  final Duration position;
  final Future<void> Function(String audioPath, String fileName) playAudio;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.primarySoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.audiotrack, color: context.colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  audioName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: AppTypography.bodySmall),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: position.inSeconds.toDouble(),
              max: duration.inSeconds.toDouble().clamp(1, double.infinity),
              onChanged: (value) async {
                await audioPlayer.seek(Duration(seconds: value.toInt()));
              },
              activeColor: context.colors.primary,
              inactiveColor: context.colors.primarySoft,
            ),
          ),
          // Time display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(position),
                    style: const TextStyle(fontSize: AppTypography.caption)),
                Text(_formatDuration(duration),
                    style: const TextStyle(fontSize: AppTypography.caption)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Play/Pause button
          Center(
            child: GestureDetector(
              onTap: isLoading ? null : () => playAudio(audioPath, audioName),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                decoration: BoxDecoration(
                  color: isLoading
                      ? context.colors.textSecondary
                      : (isPlaying
                          ? AppColors.warningStrong
                          : AppColors.primary),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    else
                      Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 24,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      isLoading
                          ? 'Đang tải...'
                          : (isPlaying ? 'Tạm dừng' : 'Phát audio'),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}';
  }
}
