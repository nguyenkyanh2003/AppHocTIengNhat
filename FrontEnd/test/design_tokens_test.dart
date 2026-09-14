import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Hàng rào giữ cho giao diện không lem nhem lại.
///
/// Trước đợt làm lại hệ thống thị giác, `lib/` có 475 chỗ đặt `fontSize` rời và
/// 20 cỡ chữ khác nhau — chữ lệch nhau 1-2px cạnh nhau đọc ra như lỗi. Các test
/// dưới đây khoá con số đó lại theo đúng cách `route-contract.test.js` khoá
/// route: muốn tăng thì phải sửa ngưỡng có chủ đích, không phải vô tình.
void main() {
  /// Ngưỡng chỉ được phép giảm. Khi dọn xong thêm màn nào thì hạ số này xuống
  /// đúng con số mới, đừng để nguyên.
  const maxHardcodedFontSize = 421;

  /// Sáu màn của luồng demo đã dọn sạch — không được để lọt `fontSize` mới vào.
  const cleanScreens = [
    'lib/features/home/screens/home_screen.dart',
    'lib/features/lessons/screens/lesson_list_screen.dart',
    'lib/features/lessons/screens/lesson_detail_screen.dart',
    'lib/features/vocabulary/screens/vocabulary_main_screen.dart',
    'lib/features/flashcards/screens/flashcard_study_screen.dart',
    'lib/features/profile/screens/profile_screen.dart',
  ];

  final hardcodedSize = RegExp(r'fontSize:\s*[0-9]');

  List<File> dartFilesIn(String path) => Directory(path)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  test('số chỗ hardcode fontSize trong lib/ không được tăng', () {
    var total = 0;
    for (final file in dartFilesIn('lib')) {
      total += hardcodedSize.allMatches(file.readAsStringSync()).length;
    }

    expect(
      total,
      lessThanOrEqualTo(maxHardcodedFontSize),
      reason: 'Dùng Theme.of(context).textTheme hoặc hằng số trong '
          'AppTypography thay vì đặt fontSize rời. Nếu thật sự cần thêm một '
          'bậc chữ mới thì thêm vào AppTypography rồi hạ/điều chỉnh ngưỡng '
          'trong test này có chủ đích.',
    );
  });

  test('sáu màn của luồng demo không còn fontSize hardcode', () {
    for (final path in cleanScreens) {
      final source = File(path).readAsStringSync();
      expect(
        hardcodedSize.allMatches(source).length,
        0,
        reason: '$path đã được dọn sạch, không đặt fontSize rời trở lại.',
      );
    }
  });

  test('sáu màn của luồng demo không hardcode màu Material', () {
    final hardcodedColor = RegExp(r'Colors\.(grey|blue|red|green|orange)\[');

    for (final path in cleanScreens) {
      final source = File(path).readAsStringSync();
      expect(
        hardcodedColor.allMatches(source).length,
        0,
        reason: '$path phải lấy màu từ AppColors, không dùng bảng màu '
            'Material trực tiếp.',
      );
    }
  });

  test('không còn dấu vết màu chủ đạo cũ #2196F3', () {
    for (final file in dartFilesIn('lib')) {
      expect(
        file.readAsStringSync().contains('2196F3'),
        isFalse,
        reason: '${file.path} vẫn dùng Material Blue cũ; màu chủ đạo hiện tại '
            'là AppColors.primary (#4F46E5).',
      );
    }
  });
}
