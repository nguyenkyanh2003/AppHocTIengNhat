import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/app/theme/calm_colors.dart';

/// Độ tương phản WCAG 2.x giữa hai màu đặc.
double contrast(Color a, Color b) {
  double channel(double c) => c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double luminance(Color c) => 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
  final la = luminance(a);
  final lb = luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  // Dựng theme là nạp font google_fonts, việc cần binding của test.
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final (mode, c) in [('sáng', CalmColors.light), ('tối', CalmColors.dark)]) {
    group('chế độ $mode: mọi cặp chữ / nền đạt tương phản ≥ 4.5:1', () {
      final pairs = <String, (Color, Color)>{
        'chữ chính trên nền màn': (c.textPrimary, c.background),
        'chữ phụ trên nền màn': (c.textSecondary, c.background),
        'chữ chính trên thẻ': (c.textPrimary, c.card),
        'chữ phụ trên thẻ': (c.textSecondary, c.card),
        'chữ trắng trên thẻ xanh': (c.onGreen, c.green),
        'nhãn nhỏ trên thẻ xanh': (c.onGreenEyebrow, c.green),
        'dòng phụ trên thẻ xanh': (c.onGreenMuted, c.green),
        'nút trắng chữ xanh': (c.green, Colors.white),
        'liên kết tím trên nền màn': (c.accent, c.background),
        'chữ tím trên nền tím nhạt (tag, mục đang chọn)': (c.accent, c.accentSoft),
        'số streak': (c.streakValue, c.streakCard),
        'nhãn streak': (c.streakLabel, c.streakCard),
        'số XP': (c.xpValue, c.xpCard),
        'nhãn XP': (c.xpLabel, c.xpCard),
        'tag xanh': (c.tagGreen, c.tagGreenBg),
        'mục điều hướng chưa chọn': (c.navInactive, c.card),
        'chữ chính trên ô kanji': (c.textPrimary, c.kanjiTile),
      };
      for (final entry in pairs.entries) {
        test(entry.key, () {
          final ratio = contrast(entry.value.$1, entry.value.$2);
          expect(ratio, greaterThanOrEqualTo(4.5), reason: '${entry.key}: ${ratio.toStringAsFixed(2)}:1');
        });
      }

      // Icon và chữ 漢 là thành phần đồ hoạ: WCAG yêu cầu ≥ 3:1.
      for (final entry in c.tiles.entries) {
        test('icon ô ${entry.key.name} trên nền ô (≥ 3:1)', () {
          expect(contrast(entry.value.foreground, entry.value.background), greaterThanOrEqualTo(3));
        });
      }
    });
  }

  test('theme sáng và tối đều mang bảng màu dịu', () {
    expect(AppTheme.lightTheme.extension<CalmColors>(), same(CalmColors.light));
    expect(AppTheme.darkTheme.extension<CalmColors>(), same(CalmColors.dark));
  });
}
