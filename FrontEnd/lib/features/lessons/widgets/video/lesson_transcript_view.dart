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
    this.layers,
    this.showLayerToggles = true,
  });

  final List<TranscriptLine> lines;

  /// Các lớp chữ đang bật. Truyền từ ngoài vào khi nơi khác (phụ đề toàn màn
  /// hình) cũng cần theo cùng lựa chọn; bỏ trống thì widget tự giữ.
  final ValueNotifier<Set<TranscriptLayer>>? layers;

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

  /// `false` khi nút bật tắt lớp chữ đã nằm ở ngoài, dùng chung cho nhiều
  /// phần (Kịch bản / Mẫu câu).
  final bool showLayerToggles;

  @override
  State<LessonTranscriptView> createState() => _LessonTranscriptViewState();
}

class _LessonTranscriptViewState extends State<LessonTranscriptView> {
  final ValueNotifier<Set<TranscriptLayer>> _ownLayers =
      ValueNotifier({...TranscriptLayer.values});
  final ScrollController _scroll = ScrollController();
  final Map<int, GlobalKey> _keys = {};

  ValueNotifier<Set<TranscriptLayer>> get _layers => widget.layers ?? _ownLayers;

  @override
  void dispose() {
    _ownLayers.dispose();
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

  /// Đưa dòng đang nói vào tầm nhìn.
  ///
  /// Khung tự cuộn thì **chỉ** cuộn khung đó: `Scrollable.ensureVisible` đi
  /// ngược lên mọi vùng cuộn bao ngoài, nên nó kéo luôn cả trang theo dòng
  /// đang nói và đẩy video ra khỏi màn hình trong lúc người học đang xem.
  void _scrollToActive() {
    final active = widget.activeIndex;
    final context = active == null ? null : _keys[active]?.currentContext;
    if (context == null) return;

    if (widget.scrollable && _scroll.hasClients) {
      final row = context.findRenderObject();
      if (row == null) return;
      _scroll.position.ensureVisible(
        row,
        duration: AppDurations.normal,
        curve: Curves.easeOut,
        alignment: 0.3,
      );
      return;
    }

    Scrollable.ensureVisible(
      context,
      duration: AppDurations.normal,
      curve: Curves.easeOut,
      alignment: 0.3,
    );
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: _layers,
        builder: (context, layers, _) => _build(context, layers),
      );

  Widget _build(BuildContext context, Set<TranscriptLayer> layers) {
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
        layers: layers,
        isActive: index == widget.activeIndex,
        onTap: () => widget.onSeek(widget.lines[index].start),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLayerToggles) ...[
          TranscriptLayerToggles(layers: _layers),
          AppGap.md,
        ],
        if (widget.scrollable) Flexible(child: list) else list,
      ],
    );
  }
}

/// Ba nút bật tắt lớp chữ 日本語 / Roma-ji / Tiếng Việt.
class TranscriptLayerToggles extends StatelessWidget {
  const TranscriptLayerToggles({super.key, required this.layers});

  final ValueNotifier<Set<TranscriptLayer>> layers;

  void _toggle(TranscriptLayer layer) {
    final next = {...layers.value};
    // Luôn giữ ít nhất một lớp: tắt hết thì bảng trống và không hiểu vì sao.
    if (next.contains(layer) && next.length > 1) {
      next.remove(layer);
    } else {
      next.add(layer);
    }
    layers.value = next;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<TranscriptLayer>>(
      valueListenable: layers,
      builder: (context, selected, _) => Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final layer in TranscriptLayer.values)
            FilterChip(
              label: Text(layer.label),
              selected: selected.contains(layer),
              onSelected: (_) => _toggle(layer),
            ),
        ],
      ),
    );
  }
}

/// Các lớp chữ của một câu theo đúng thứ tự hiển thị, mỗi lớp kèm tên người
/// nói ở cùng lớp đó (プトリ cạnh câu tiếng Nhật, Putri cạnh câu tiếng Việt).
List<({TranscriptLayer layer, String? speaker, String text})> transcriptLayerRows(
  TranscriptLine line,
  Set<TranscriptLayer> layers,
) =>
    [
      if (layers.contains(TranscriptLayer.japanese))
        (layer: TranscriptLayer.japanese, speaker: line.speakerJa, text: line.textJa),
      if (layers.contains(TranscriptLayer.romaji) && (line.romaji?.isNotEmpty ?? false))
        (layer: TranscriptLayer.romaji, speaker: line.speakerRomaji, text: line.romaji!),
      if (layers.contains(TranscriptLayer.vietnamese))
        (layer: TranscriptLayer.vietnamese, speaker: line.speakerVi, text: line.textVi),
    ];

/// Một lớp chữ: tên người nói ở cột trái, câu ở bên phải.
class TranscriptLayerRow extends StatelessWidget {
  const TranscriptLayerRow({super.key, required this.layer, required this.speaker, required this.text});

  final TranscriptLayer layer;
  final String? speaker;
  final String text;

  /// Đủ cho tên dài nhất đang có ("Nhân viên hướng dẫn") xuống hai dòng.
  static const double speakerWidth = 96;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = switch (layer) {
      TranscriptLayer.japanese =>
        AppTypography.japaneseReading(color: AppColors.textPrimary).copyWith(fontSize: AppTypography.body),
      TranscriptLayer.romaji => textTheme.bodySmall,
      TranscriptLayer.vietnamese => textTheme.bodyMedium,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: speakerWidth,
            child: Text(
              speaker ?? '',
              style: textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          AppGap.sm,
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}

/// Phụ đề của câu đang nói, đặt đè lên video khi xem toàn màn hình.
///
/// Theo đúng các lớp chữ người học đã bật ở bảng lời thoại; khoảng lặng
/// ([line] là `null`) thì không hiện gì.
class TranscriptCaption extends StatelessWidget {
  const TranscriptCaption({super.key, required this.line, required this.layers});

  final TranscriptLine? line;
  final Set<TranscriptLayer> layers;

  @override
  Widget build(BuildContext context) {
    final line = this.line;
    if (line == null) return const SizedBox.shrink();

    final romaji = line.romaji;
    final texts = [
      if (layers.contains(TranscriptLayer.japanese))
        Text(
          line.textJa,
          style: AppTypography.japaneseReading(color: Colors.white)
              .copyWith(fontSize: AppTypography.title),
        ),
      if (layers.contains(TranscriptLayer.romaji) &&
          romaji != null &&
          romaji.isNotEmpty)
        Text(
          romaji,
          style: const TextStyle(
              color: Colors.white70, fontSize: AppTypography.bodySmall),
        ),
      if (layers.contains(TranscriptLayer.vietnamese))
        Text(
          line.textVi,
          style: const TextStyle(
              color: Colors.white, fontSize: AppTypography.subtitle),
        ),
    ];
    if (texts.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: AppRadius.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: DefaultTextStyle.merge(
          textAlign: TextAlign.center,
          child: Column(mainAxisSize: MainAxisSize.min, children: texts),
        ),
      ),
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
                    color: isActive ? AppColors.primary : AppColors.textDisabled,
                  ),
                ),
              ),
              AppGap.sm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final row in transcriptLayerRows(line, layers))
                      TranscriptLayerRow(layer: row.layer, speaker: row.speaker, text: row.text),
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
