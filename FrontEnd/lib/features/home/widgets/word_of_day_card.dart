import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/calm_colors.dart';
import '../../../core/audio/speech_service.dart';
import '../../vocabulary/models/vocabulary.dart';
import 'home_layout.dart';

/// Thẻ "Từ mới hôm nay": mặt chữ, cách đọc, nghĩa, trình độ, nút nghe và câu ví
/// dụ nếu từ có.
///
/// Dữ liệu từ vựng chưa có roma-ji và từ loại, nên hai phần đó không hiện
/// (không tự suy ra để khỏi sai).
class WordOfDayCard extends StatelessWidget {
  const WordOfDayCard({super.key, required this.word});

  final Vocabulary word;

  Future<void> _speak(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await SpeechService.instance
          .speak(word.hiragana.isNotEmpty ? word.hiragana : word.word);
    } on SpeechUnavailableException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Không phát được âm thanh.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final calm = CalmColors.of(context);
    final l10n = AppLocalizations.of(context);
    final example =
        word.examples.where((e) => e.sentence.trim().isNotEmpty).firstOrNull;
    final showReading = word.hiragana.isNotEmpty && word.hiragana != word.word;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: homeCardDecoration(calm, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: calm.kanjiTile,
                    borderRadius: BorderRadius.circular(16)),
                // Từ dài (お久しぶりです) tự thu nhỏ cho vừa ô thay vì tràn.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    word.word,
                    maxLines: 1,
                    style: AppTypography.japaneseDisplay(
                            size: 46, color: calm.textPrimary)
                        .copyWith(height: 1.1),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showReading)
                      Text(
                        word.hiragana,
                        style: AppTypography.japaneseDisplay(
                                size: 18,
                                weight: FontWeight.w500,
                                color: calm.textPrimary)
                            .copyWith(height: 1.3),
                      ),
                    Text(
                      word.meaning,
                      style: AppTypography.ui(
                          size: 18,
                          weight: FontWeight.w600,
                          color: calm.textPrimary,
                          height: 1.3),
                    ),
                    if (word.level != null && word.level!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _Tag(
                          text: word.level!,
                          background: calm.accentSoft,
                          foreground: calm.accent),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: l10n.listenPronunciation,
                excludeSemantics: true,
                child: Material(
                  color: calm.accentSoft,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _speak(context),
                    child: Tooltip(
                      message: l10n.listenPronunciation,
                      child: SizedBox.square(
                        dimension: HomeLayout.minTap,
                        child: Icon(Icons.volume_up_rounded,
                            size: 20, color: calm.accent),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (example != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, thickness: 1, color: calm.divider),
            ),
            Text(
              l10n.exampleLabel.toUpperCase(),
              style: AppTypography.ui(
                  size: 12,
                  weight: FontWeight.w600,
                  color: calm.textSecondary,
                  letterSpacing: 0.6),
            ),
            const SizedBox(height: 6),
            Text(example.sentence,
                style: AppTypography.japaneseBody(color: calm.textPrimary)
                    .copyWith(fontSize: 16)),
            if (example.meaning.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(example.meaning,
                  style: AppTypography.ui(
                      size: 14, color: calm.textSecondary, height: 1.4)),
            ],
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(
      {required this.text, required this.background, required this.foreground});

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: background, borderRadius: BorderRadius.circular(8)),
        child: Text(text,
            style: AppTypography.ui(
                size: 12, weight: FontWeight.w600, color: foreground)),
      );
}

/// Khung chờ cùng kích thước thẻ thật, để trang không nhảy khi từ tải xong.
class WordOfDayPlaceholder extends StatelessWidget {
  const WordOfDayPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final calm = CalmColors.of(context);
    return Container(
      height: 118,
      padding: const EdgeInsets.all(18),
      decoration: homeCardDecoration(calm, radius: 20),
      alignment: Alignment.centerLeft,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
            color: calm.kanjiTile, borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
