import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/app/theme/app_tokens.dart';

/// Độ tương phản WCAG 2.x giữa hai màu đặc.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return ((la > lb ? la : lb) + 0.05) / ((la > lb ? lb : la) + 0.05);
}

void _expectReadable(Color foreground, Color background, String name,
    [double minimum = 4.5]) {
  expect(_contrast(foreground, background), greaterThanOrEqualTo(minimum),
      reason:
          '$name: ${_contrast(foreground, background).toStringAsFixed(2)}:1');
}

void main() {
  // Dựng theme là nạp font google_fonts, việc cần binding của test.
  TestWidgetsFlutterBinding.ensureInitialized();

  const light = AppThemeColors.light;
  const dark = AppThemeColors.dark;

  test('chế độ sáng giữ nguyên đúng màu đang dùng, các màn không đổi diện mạo',
      () {
    expect(light.background, AppColors.background);
    expect(light.surface, AppColors.surface);
    expect(light.surfaceVariant, AppColors.surfaceVariant);
    expect(light.border, AppColors.border);
    expect(light.textPrimary, AppColors.textPrimary);
    expect(light.textSecondary, AppColors.textSecondary);
    expect(light.textDisabled, AppColors.textDisabled);
    expect(light.primary, AppColors.primary);
    expect(light.primaryStrong, AppColors.primaryDark);
    expect(light.primarySoft, AppColors.primaryLight);
    expect(light.error, AppColors.error);
  });

  group('chế độ tối: mọi cặp chữ / nền đạt tương phản ≥ 4.5:1', () {
    for (final (backgroundName, background) in [
      ('nền màn', dark.background),
      ('thẻ', dark.surface),
      ('ô nhập liệu', dark.surfaceVariant),
    ]) {
      test('trên $backgroundName', () {
        _expectReadable(dark.textPrimary, background, 'chữ chính');
        _expectReadable(dark.textSecondary, background, 'chữ phụ');
        _expectReadable(dark.primary, background, 'màu nhấn');
        _expectReadable(dark.error, background, 'chữ lỗi');
      });
    }

    test('trên nền nhấn nhạt', () {
      _expectReadable(dark.primary, dark.primarySoft, 'màu nhấn');
      _expectReadable(dark.primaryStrong, dark.primarySoft, 'chữ nhấn đậm');
      _expectReadable(dark.textPrimary, dark.primarySoft, 'chữ chính');
    });

    test('chữ mờ (nội dung không bấm được) đạt mức đồ hoạ ≥ 3:1 trên thẻ', () {
      _expectReadable(dark.textDisabled, dark.surface, 'chữ mờ', 3);
    });
  });

  group('readable: màu nhận diện dùng làm chữ hoặc icon', () {
    const hues = <String, Color>{
      'primary': AppColors.primary,
      'error': AppColors.error,
      'vocabulary': AppColors.vocabulary,
      'lesson': AppColors.lesson,
      'exercise': AppColors.exercise,
      'jlpt': AppColors.jlpt,
      'purple': Colors.purple,
      'deepPurple': Colors.deepPurple,
      'indigo': Colors.indigo,
      'blue': Colors.blue,
      'red': Colors.red,
      'pink': Colors.pink,
      'teal': Colors.teal,
      'green': Colors.green,
      'brown': Colors.brown,
      'black': Colors.black,
    };

    test('chế độ sáng giữ nguyên màu', () {
      for (final hue in hues.values) {
        expect(light.readable(hue).computeLuminance(),
            lessThanOrEqualTo(hue.computeLuminance()));
      }
    });

    for (final entry in hues.entries) {
      test('chế độ tối: ${entry.key} đọc được trên thẻ và ô nhập liệu', () {
        final color = dark.readable(entry.value);

        _expectReadable(color, dark.surface, 'trên thẻ');
        _expectReadable(color, dark.surfaceVariant, 'trên ô nhập liệu');
      });
    }

    test('chế độ tối: màu vốn đã đọc được thì không đổi', () {
      expect(dark.readable(AppColors.warning), AppColors.warning);
    });
  });

  group('context.colors', () {
    Future<AppThemeColors> colorsUnder(
        WidgetTester tester, ThemeData? theme) async {
      late AppThemeColors colors;
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Builder(builder: (context) {
          colors = context.colors;
          return const SizedBox();
        }),
      ));
      await tester.pumpAndSettle();
      return colors;
    }

    testWidgets('đọc đúng bộ màu của theme đang dùng', (tester) async {
      expect(await colorsUnder(tester, AppTheme.lightTheme),
          same(AppThemeColors.light));
      expect(await colorsUnder(tester, AppTheme.darkTheme),
          same(AppThemeColors.dark));
    });

    testWidgets('theme không khai báo bộ màu thì dùng bộ sáng', (tester) async {
      expect(
          await colorsUnder(tester, ThemeData()), same(AppThemeColors.light));
    });
  });

  group('theme tối: các thành phần dựng sẵn đọc được', () {
    late ThemeData theme;
    late Color surface;
    late Color scaffold;

    setUp(() {
      theme = AppTheme.darkTheme;
      surface = theme.colorScheme.surface;
      scaffold = theme.scaffoldBackgroundColor;
    });

    Color resolved(WidgetStateProperty<Color?>? property) =>
        property!.resolve(const {})!;

    test('nút chữ và nút viền', () {
      _expectReadable(resolved(theme.textButtonTheme.style!.foregroundColor),
          surface, 'TextButton trên thẻ');
      _expectReadable(resolved(theme.textButtonTheme.style!.foregroundColor),
          scaffold, 'TextButton trên nền');
      _expectReadable(
          resolved(theme.outlinedButtonTheme.style!.foregroundColor),
          surface,
          'OutlinedButton');
    });

    test('nút đặc giữ nền thương hiệu, chữ trắng', () {
      final style = theme.elevatedButtonTheme.style!;
      _expectReadable(resolved(style.foregroundColor),
          resolved(style.backgroundColor), 'ElevatedButton');
    });

    test(
        'colorScheme.primary (TabBar, Switch, FilledButton mặc định) nổi trên thẻ',
        () {
      _expectReadable(theme.colorScheme.primary, surface, 'primary trên thẻ');
      _expectReadable(theme.colorScheme.onPrimary, theme.colorScheme.primary,
          'onPrimary trên primary');
    });

    test('nhãn ô nhập liệu và viền đang chọn', () {
      final input = theme.inputDecorationTheme;
      _expectReadable(
          input.hintStyle!.color!, input.fillColor!, 'gợi ý trong ô');
      _expectReadable(input.floatingLabelStyle!.color!, surface, 'nhãn nổi');
      _expectReadable(
          (input.focusedBorder as OutlineInputBorder).borderSide.color,
          input.fillColor!,
          'viền đang chọn',
          3);
    });

    test('snackbar tách khỏi nền màn', () {
      final snackBar = theme.snackBarTheme;
      expect(snackBar.backgroundColor, isNot(scaffold));
      _expectReadable(snackBar.contentTextStyle!.color!,
          snackBar.backgroundColor!, 'chữ snackbar');
    });

    test('nút hành động trên snackbar ("Xem", "Thử lại") đọc được ở cả hai chế độ', () {
      // Mặc định lấy `inversePrimary`, vốn dành cho nền sáng: trên nền snackbar
      // tối của chế độ tối nó gần như chìm.
      for (final (name, mode) in [('tối', AppTheme.darkTheme), ('sáng', AppTheme.lightTheme)]) {
        final snackBar = mode.snackBarTheme;
        _expectReadable(snackBar.actionTextColor!, snackBar.backgroundColor!,
            'nút snackbar chế độ $name');
      }
    });

    test('thanh dưới cũ và vòng tiến độ dùng màu nhấn sáng', () {
      _expectReadable(theme.bottomNavigationBarTheme.selectedItemColor!,
          surface, 'mục đang chọn');
      _expectReadable(
          theme.progressIndicatorTheme.color!, surface, 'vòng tiến độ', 3);
    });
  });

  test('theme sáng và tối đều mang bộ màu', () {
    expect(AppTheme.lightTheme.extension<AppThemeColors>(),
        same(AppThemeColors.light));
    expect(AppTheme.darkTheme.extension<AppThemeColors>(),
        same(AppThemeColors.dark));
  });

  group('chip đang chọn', () {
    double contrast(Color a, Color b) {
      final x = a.computeLuminance();
      final y = b.computeLuminance();
      return ((x > y ? x : y) + 0.05) / ((x > y ? y : x) + 0.05);
    }

    for (final (name, theme, colors) in [
      ('sáng', () => AppTheme.lightTheme, AppThemeColors.light),
      ('tối', () => AppTheme.darkTheme, AppThemeColors.dark),
    ]) {
      test('chế độ $name: chữ đủ tương phản trên nền chip', () {
        final chip = theme().chipTheme;
        final background =
            Color.alphaBlend(chip.selectedColor!, colors.surface);

        expect(contrast(chip.secondaryLabelStyle!.color!, background),
            greaterThanOrEqualTo(4.5));
      });
    }
  });
}
