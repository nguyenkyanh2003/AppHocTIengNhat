import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../shared/widgets/chunky_card.dart';

/// Bộ thẻ lật của phiên học, dùng chung cho từ vựng và chữ Hán: mỗi lần một
/// thẻ, chạm để lật.
///
/// "Đã nhớ" lưu tiến độ ngay (và chuyển sang thẻ kế), nên rời bài giữa chừng
/// vẫn giữ những thẻ đã học. Bấm nhầm thì hoàn tác ngay trên thông báo, hoặc
/// quay lại thẻ đó và bấm "Bỏ đánh dấu".
class StudyCardDeck<T> extends StatefulWidget {
  const StudyCardDeck({
    super.key,
    required this.items,
    required this.unit,
    required this.labelOf,
    required this.isLearned,
    required this.isSaving,
    required this.onMarkLearned,
    required this.onUnmarkLearned,
    required this.front,
    required this.back,
    this.onSpeak,
  });

  final List<T> items;

  /// Tên một thẻ trong câu chữ: "Từ" thành "Từ 2/6", "Từ trước".
  final String unit;

  /// Mặt chữ của thẻ trong thông báo "Đã nhớ「…」".
  final String Function(T item) labelOf;
  final bool Function(T item) isLearned;
  final bool Function(T item) isSaving;
  final Future<void> Function(T item) onMarkLearned;
  final Future<void> Function(T item) onUnmarkLearned;
  final Widget Function(T item) front;
  final Widget Function(T item) back;

  /// Có thì góc thẻ có nút nghe phát âm.
  final Future<void> Function(T item)? onSpeak;

  @override
  State<StudyCardDeck<T>> createState() => _StudyCardDeckState<T>();
}

class _StudyCardDeckState<T> extends State<StudyCardDeck<T>> {
  int _index = 0;
  bool _flipped = false;

  T get _item => widget.items[_index];

  void _goTo(int index) => setState(() {
        _index = index.clamp(0, widget.items.length - 1);
        _flipped = false;
      });

  Future<void> _remember() async {
    final item = _item;
    final index = _index;
    final messenger = ScaffoldMessenger.of(context);
    await widget.onMarkLearned(item);
    if (!mounted || !widget.isLearned(item)) return;
    if (_index < widget.items.length - 1) _goTo(_index + 1);

    // Thẻ đã chuyển sang thẻ kế: hoàn tác ngay tại đây thì không phải lùi lại tìm.
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Đã nhớ「${widget.labelOf(item)}」'),
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () async {
            await widget.onUnmarkLearned(item);
            if (mounted) _goTo(index);
          },
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final item = _item;
    final learned = widget.isLearned(item);
    final learnedCount = widget.items.where(widget.isLearned).length;
    final unit = widget.unit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('$unit ${_index + 1}/${widget.items.length}', style: textTheme.titleSmall),
            const Spacer(),
            Text('Đã nhớ $learnedCount/${widget.items.length}',
                style: textTheme.labelLarge?.copyWith(color: AppColors.success)),
          ],
        ),
        AppGap.sm,
        _DeckProgress(
          unit: unit,
          current: _index,
          learned: [for (final item in widget.items) widget.isLearned(item)],
        ),
        AppGap.lg,
        ChunkyCard(
          onTap: () => setState(() => _flipped = !_flipped),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Stack(
            children: [
              // Chừa chỗ trên cùng cho nút nghe và nhãn "Đã nhớ", để chữ lớn
              // không bao giờ nằm dưới chúng.
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: SizedBox(
                  width: double.infinity,
                  child: AnimatedSwitcher(
                    duration: AppDurations.normal,
                    child: _flipped
                        ? KeyedSubtree(key: const ValueKey('back'), child: widget.back(item))
                        : KeyedSubtree(key: const ValueKey('front'), child: widget.front(item)),
                  ),
                ),
              ),
              if (widget.onSpeak != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton.filledTonal(
                    onPressed: () => widget.onSpeak!(item),
                    tooltip: 'Nghe phát âm',
                    icon: const Icon(Icons.volume_up),
                  ),
                ),
              if (learned)
                const Positioned(
                  top: 0,
                  left: 0,
                  child: Chip(
                    avatar: Icon(Icons.check_circle, size: 18, color: AppColors.success),
                    label: Text('Đã nhớ'),
                  ),
                ),
            ],
          ),
        ),
        AppGap.lg,
        Row(
          children: [
            IconButton.outlined(
              onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
              tooltip: '$unit trước',
              icon: const Icon(Icons.chevron_left),
            ),
            AppGap.md,
            Expanded(
              child: learned
                  ? OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                      onPressed: widget.isSaving(item) ? null : () => widget.onUnmarkLearned(item),
                      icon: const Icon(Icons.undo),
                      label: const Text('Bỏ đánh dấu đã nhớ'),
                    )
                  : FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                      onPressed: widget.isSaving(item) ? null : _remember,
                      icon: const Icon(Icons.check),
                      label: const Text('Đã nhớ'),
                    ),
            ),
            AppGap.md,
            IconButton.outlined(
              onPressed: _index < widget.items.length - 1 ? () => _goTo(_index + 1) : null,
              tooltip: '$unit sau',
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}

/// Mỗi ô là một thẻ: ô tới thẻ đang xem thì tô màu (thanh chạy theo "Từ 7/9"),
/// ô của thẻ đã nhớ thì tô xanh — một thanh cho biết cả đang ở đâu lẫn đã nhớ
/// những thẻ nào.
class _DeckProgress extends StatelessWidget {
  const _DeckProgress({required this.unit, required this.current, required this.learned});

  final String unit;
  final int current;
  final List<bool> learned;

  @override
  Widget build(BuildContext context) {
    final learnedCount = learned.where((value) => value).length;
    return Semantics(
      label: '$unit ${current + 1} trên ${learned.length}, đã nhớ $learnedCount',
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var index = 0; index < learned.length; index++) ...[
              if (index > 0) const SizedBox(width: AppSpacing.xs / 2),
              Expanded(
                child: AnimatedContainer(
                  key: ValueKey('card-progress-$index'),
                  duration: AppDurations.fast,
                  height: AppSpacing.sm,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.pillAll,
                    color: learned[index]
                        ? AppColors.success
                        : index <= current
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
