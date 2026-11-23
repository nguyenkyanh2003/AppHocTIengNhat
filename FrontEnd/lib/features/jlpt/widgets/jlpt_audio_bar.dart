import 'package:flutter/material.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/app_tokens.dart';

/// Thanh phát file nghe của một phần thi. Trình phát dùng chung cả đề nên nằm ở
/// màn thi; thanh này chỉ hiện trạng thái và báo lại thao tác.
class JlptAudioBar extends StatelessWidget {
  const JlptAudioBar({
    super.key,
    required this.audioPath,
    required this.audioName,
    required this.isPlaying,
    required this.isLoading,
    required this.duration,
    required this.position,
    required this.playAudio,
    required this.onSeek,
  });

  final String audioPath;
  final String audioName;
  final bool isPlaying;
  final bool isLoading;
  final Duration duration;
  final Duration position;
  final Future<void> Function(String audioPath, String fileName) playAudio;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.primarySoft,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: context.colors.primarySoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.audiotrack, color: context.colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  audioName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: AppTypography.bodySmall),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: position.inSeconds.toDouble().clamp(0, _maxSeconds),
              max: _maxSeconds,
              onChanged: (value) => onSeek(Duration(seconds: value.toInt())),
              activeColor: context.colors.primary,
              inactiveColor: context.colors.primarySoft,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(position), style: const TextStyle(fontSize: AppTypography.caption)),
                Text(_formatDuration(duration), style: const TextStyle(fontSize: AppTypography.caption)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: FilledButton.icon(
              onPressed: isLoading ? null : () => playAudio(audioPath, audioName),
              style: FilledButton.styleFrom(
                backgroundColor: isPlaying ? AppColors.warningStrong : AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: context.colors.textSecondary,
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xl),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              label: Text(isLoading ? 'Đang tải...' : (isPlaying ? 'Tạm dừng' : 'Phát audio')),
            ),
          ),
        ],
      ),
    );
  }

  /// Chưa biết độ dài (file chưa tải xong) thì vẫn cho thanh trượt một khoảng hợp lệ.
  double get _maxSeconds => duration.inSeconds.toDouble().clamp(1, double.infinity);

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}';
  }
}
