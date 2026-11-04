import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../models/srs_progress.dart';

/// Chọn loại thẻ cần ôn: tất cả, chỉ từ vựng, hoặc chỉ Kanji. `null` là tất cả.
class SrsTypeFilter extends StatelessWidget {
  const SrsTypeFilter({super.key, required this.selected, required this.onChanged, this.enabled = true});

  final String? selected;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  static const _options = <(String?, String)>[
    (null, 'Tất cả'),
    (SrsProgress.itemTypeVocabulary, 'Từ vựng'),
    (SrsProgress.itemTypeKanji, 'Kanji'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      children: [
        for (final (type, label) in _options)
          ChoiceChip(
            label: Text(label),
            selected: selected == type,
            onSelected: enabled && selected != type ? (_) => onChanged(type) : null,
          ),
      ],
    );
  }
}
