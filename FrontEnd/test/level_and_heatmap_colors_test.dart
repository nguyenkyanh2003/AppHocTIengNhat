import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/app/theme/app_tokens.dart';
import 'package:apphoctiengnnhat/features/progress/models/dashboard.dart';
import 'package:apphoctiengnnhat/features/progress/widgets/progress_heatmap_calendar.dart';
import 'package:apphoctiengnnhat/shared/widgets/level_badge.dart';

double _contrast(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return ((x > y ? x : y) + 0.05) / ((x > y ? y : x) + 0.05);
}

void main() {
  final modes = [
    ('sáng', () => AppTheme.lightTheme, AppThemeColors.light),
    ('tối', () => AppTheme.darkTheme, AppThemeColors.dark),
  ];

  group('nhãn cấp độ đọc được', () {
    for (final (name, theme, colors) in modes) {
      for (final level in AppColors.jlptLevels.keys) {
        testWidgets('$level ở chế độ $name đạt tối thiểu 4,5:1',
            (tester) async {
          await tester.pumpWidget(MaterialApp(
            theme: theme(),
            home: Material(color: colors.surface, child: LevelBadge(level)),
          ));

          final text = tester.widget<Text>(find.text(level));
          final box = tester.widget<Container>(find.byType(Container).first);
          final decoration = box.decoration! as BoxDecoration;
          final background =
              Color.alphaBlend(decoration.color!, colors.surface);

          expect(_contrast(text.style!.color!, background),
              greaterThanOrEqualTo(4.5));
        });
      }
    }
  });

  group('màu nhận diện làm chữ', () {
    for (final (name, _, colors) in modes) {
      test('chế độ $name: đọc được trên cả thẻ lẫn ô nhập liệu', () {
        for (final hue in [
          AppColors.success,
          AppColors.warning,
          AppColors.info,
          AppColors.error,
          AppColors.primary,
          ...AppColors.jlptLevels.values,
        ]) {
          final color = colors.readable(hue);
          expect(_contrast(color, colors.surface), greaterThanOrEqualTo(4.5));
          expect(_contrast(color, colors.surfaceVariant),
              greaterThanOrEqualTo(4.5));
        }
      });
    }

    test('màu đã đủ tương phản thì giữ nguyên sắc', () {
      expect(
          AppThemeColors.light.readable(AppColors.primary), AppColors.primary);
    });

    test('tính cả nền nhạt khi được truyền vào', () {
      const colors = AppThemeColors.light;
      const hue = AppColors.warning;
      final tint = Color.alphaBlend(hue.withValues(alpha: 0.2), colors.surface);

      expect(_contrast(colors.readable(hue, on: tint), tint),
          greaterThanOrEqualTo(4.5));
    });
  });

  group('nền đặc mang chữ trắng', () {
    for (final (name, fill) in const [
      ('success', AppColors.successStrong),
      ('warning', AppColors.warningStrong),
      ('error', AppColors.errorStrong),
    ]) {
      test('$name đạt 4,5:1', () {
        final contrast = 1.05 / (fill.computeLuminance() + 0.05);
        expect(contrast, greaterThanOrEqualTo(4.5));
        expect(AppColors.onFill(fill), Colors.white);
      });
    }
  });

  group('lịch hoạt động', () {
    for (final (name, _, colors) in modes) {
      test('chế độ $name: bốn mức khác nhau và đậm dần so với ô trống', () {
        final empty = colors.heatmap(0);
        final levels = [for (var i = 1; i <= 4; i += 1) colors.heatmap(i)];

        expect({empty, ...levels}, hasLength(5));

        var previous = empty;
        for (final level in levels) {
          // Càng nhiều hoạt động càng xa màu nền: tối đi ở chế độ sáng, sáng lên ở chế độ tối.
          expect(
              _contrast(level, empty), greaterThan(_contrast(previous, empty)));
          expect(_contrast(level, previous), greaterThanOrEqualTo(1.25));
          previous = level;
        }
      });

      test('chế độ $name: mức ngoài khoảng không làm hỏng màn', () {
        expect(colors.heatmap(-1), colors.heatmap(0));
        expect(colors.heatmap(9), colors.heatmap(4));
      });
    }

    testWidgets('ô lịch và chú giải dùng đúng sắc của từng mức',
        (tester) async {
      final year = DateTime.now().year;
      final data = [
        HeatmapData(date: '$year-01-01', count: 1, time: 0),
        HeatmapData(date: '$year-01-02', count: 4, time: 0),
        HeatmapData(date: '$year-01-03', count: 8, time: 0),
        HeatmapData(date: '$year-01-04', count: 20, time: 0),
      ];
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProgressHeatmapGrid(heatmap: data),
          ),
        ),
      ));

      final painted = tester
          .widgetList<Container>(find.byType(Container))
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .map((decoration) => decoration.color)
          .toList();

      // Mỗi mức có đúng hai chỗ: một ô lịch và một ô chú giải.
      for (var level = 1; level <= 4; level += 1) {
        final color = AppThemeColors.light.heatmap(level);
        expect(painted.where((value) => value == color), hasLength(2));
      }
    });
  });
}
