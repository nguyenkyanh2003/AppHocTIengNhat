import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../models/lesson_video.dart';

/// Ba lớp chữ của lời thoại; người học bật tắt từng lớp.
enum TranscriptLayer { japanese, romaji, vietnamese }

extension TranscriptLayerLabel on TranscriptLayer {
  String get label => switch (this) {
        TranscriptLayer.japanese => '日本語',
        TranscriptLayer.romaji => 'Roma-ji',
        TranscriptLayer.vietnamese => 'Tiếng Việt',
      };
}

/// Lời thoại chạy theo video: dòng đang nói được tô sáng, chạm một dòng là
/// video nhảy tới đúng chỗ đó.
///
/// Không giữ [VideoPlayerController] nào — chỉ nhận [activeIndex] (chỉ số
/// dòng đang nói) và gọi [onSeek]. Nhờ vậy widget test dựng được nó mà không
/// cần video thật, **và** widget chỉ dựng lại khi đổi dòng chứ không phải mỗi
/// lần video nhích thêm vài mili-giây.
class LessonTranscriptView extends StatefulWidget {
  const LessonTranscriptView({
    super.key,
    required this.lines,
    required this.activeIndex,
    required this.onSeek,
    this.scrollable = true,
    this.autoScroll = true,
  });

  final List<TranscriptLine> lines;

  /// Chỉ số dòng đang nói; `null` khi đang ở khoảng lặng.
  final int? activeIndex;

  final ValueChanged<Duration> onSeek;

  /// `true` khi widget nằm trong một khung có chiều cao xác định (bố cục hai
  /// cột): danh sách tự cuộn trong khung đó.
  ///
  /// `false` khi nằm trong trang đang cuộn dọc (bố cục một cột): danh sách
  /// phải dàn hết chiều cao và để trang cuộn. Đặt sai bên này là màn hình
  /// trắng và kẹt, vì một danh sách tự cuộn không có chiều cao hữu hạn.
  final bool scrollable;

  /// Tự cuộn tới dòng đang nói. Tắt trong test widget để không phụ thuộc
  /// animation.
  final bool autoScroll;

  @override
  State<LessonTranscriptView> createState() => _LessonTranscriptViewState();
}

class _LessonTranscriptViewState extends State<LessonTranscriptView> {
  final Set<TranscriptLayer> _layers = {...TranscriptLayer.values};
  final ScrollController _scroll = ScrollController();
  final Map<int, GlobalKey> _keys = {};

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LessonTranscriptView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoScroll && widget.activeIndex != oldWidget.activeIndex) {
      _scrollToActive();
    }
  }

  /// Đưa dòng đang nói vào tầm nhìn. `ensureVisible` cuộn đúng vùng cuộn đang
  /// chứa dòng đó — danh sách ở bố cục hai cột, hoặc cả trang ở bố cục một cột.
  void _scrollToActive() {
    final active = widget.activeIndex;
    final context = active == null ? null : _keys[active]?.currentContext;
    if (context == null) return;

    Scrollable.ensureVisible(
      context,
      duration: AppDurations.normal,
      curve: Curves.easeOut,
      alignment: 0.3,
    );
  }

  void _toggle(TranscriptLayer layer) {
    setState(() {
      // Luôn giữ ít nhất một lớp: tắt hết thì bảng trống và không hiểu vì sao.
      if (_layers.contains(layer) && _layers.length > 1) {
        _layers.remove(layer);
      } else {
        _layers.add(layer);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (widget.lines.isEmpty) {
      return Text(
        'Video này chưa có lời thoại.',
        style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      );
    }

    final list = ListView.separated(
      controller: widget.scrollable ? _scroll : null,
      // Trong trang đang cuộn dọc thì danh sách không được cuộn riêng: nó phải
      // dàn hết chiều cao và nhường việc cuộn cho trang.
      shrinkWrap: !widget.scrollable,
      physics: widget.scrollable ? null : const NeverScrollableScrollPhysics(),
      itemCount: widget.lines.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => _TranscriptRow(
        key: _keys.putIfAbsent(index, GlobalKey.new),
        line: widget.lines[index],
        layers: _layers,
        isActive: index == widget.activeIndex,
        onTap: () => widget.onSeek(widget.lines[index].start),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final layer in TranscriptLayer.values)
              FilterChip(
                label: Text(layer.label),
                selected: _layers.contains(layer),
                onSelected: (_) => _toggle(layer),
              ),
          ],
        ),
        AppGap.md,
        if (widget.scrollable) Flexible(child: list) else list,
      ],
    );
  }
}

class _TranscriptRow extends StatelessWidget {
  const _TranscriptRow({
    super.key,
    required this.line,
    required this.layers,
    required this.isActive,
    required this.onTap,
  });

  final TranscriptLine line;
  final Set<TranscriptLayer> layers;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final speaker = line.speakerVi ?? line.speakerJa;

    return Material(
      color: isActive ? AppColors.primaryLight : Colors.transparent,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  line.label,
                  style: textTheme.labelMedium?.copyWith(
                    color:
                        isActive ? AppColors.primary : AppColors.textDisabled,
                  ),
                ),
              ),
              AppGap.sm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (speaker != null && speaker.isNotEmpty)
                      Text(speaker, style: textTheme.labelSmall),
                    if (layers.contains(TranscriptLayer.japanese))
                      Text(
                        line.textJa,
                        style: AppTypography.japaneseReading(
                          color: AppColors.textPrimary,
                        ).copyWith(fontSize: AppTypography.body),
                      ),
                    if (layers.contains(TranscriptLayer.romaji) &&
                        (line.romaji?.isNotEmpty ?? false))
                      Text(line.romaji!, style: textTheme.bodySmall),
                    if (layers.contains(TranscriptLayer.vietnamese))
                      Text(line.textVi, style: textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
