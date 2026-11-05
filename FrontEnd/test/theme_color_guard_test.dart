import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Màu chỉ đúng ở chế độ sáng: dùng trong màn hình thì chữ tối nằm trên nền tối.
///
/// Màn hình quá nhiều để dựng từng màn ở chế độ tối, nên test đọc mã nguồn: màu
/// nào có vai trò chữ hoặc nền trung tính phải đi qua `context.colors`.
const _forbidden = <String, String>{
  r'\bAppColors\.(textPrimary|textSecondary|textDisabled|background|surface|surfaceVariant|border|primaryLight)\b':
      'màu trung tính của chế độ sáng; dùng context.colors',
  r'\bAppTheme\.(textPrimaryColor|textSecondaryColor|textDisabledColor|backgroundColor|surfaceColor|cardColor)\b':
      'alias của màu trung tính; dùng context.colors',
  r'\bColor\(0x': 'mã màu rời; thêm token trong app_tokens.dart',
  r'\bColors\.(grey|blueGrey)\b': 'xám cố định; dùng context.colors',
  r'\bColors\.[a-zA-Z]+(\[(50|100|200|300)\]|\.shade(50|100|200|300))':
      'nền nhạt cố định; dùng màu.withValues(alpha:)',
  r'(?<!Color\.lerp\([^\n]*)\bColors\.black(87|54)?\b(?!\.with)':
      'chữ đen cố định; dùng context.colors.textPrimary',
  r'Color _?get_?[lL]evelColor|Color _levelColor':
      'màu cấp độ riêng từng màn; dùng LevelBadge hoặc AppTheme.getJlptLevelColor',
  r'\b(TextStyle|Icon)\([^()]*\bcolor: AppColors\.(success|warning|info|accent|secondary)\b(?!\.with)':
      'màu quá sáng để làm chữ trên nền thẻ; dùng context.colors.readable(...)',
  r'\bcolor: (AppTheme\.getJlptLevelColor\([^()]*\)|AppColors\.(success|warning|info|accent)),(?:(?!BoxDecoration)[\s\S]){0,260}?color: Colors\.white\b(?!\.with|70|54)':
      'chữ trắng trên nền màu sáng chỉ đạt khoảng 2:1; dùng AppColors.onFill hoặc LevelBadge',
  r'backgroundColor:\s*(?:[^,;\n]*\?\s*)?AppColors\.(success|warning|error)\b(?!\.with)':
      'nền đặc mang chữ trắng không đủ tương phản; dùng AppColors.successStrong/warningStrong/errorStrong',
  r'colors: (?:\w+\s*\?\s*)?\[\s*AppColors\.(success|warning|error)\b(?!\.with)':
      'gradient đặc mang chữ trắng không đủ tương phản; dùng màu đặc AppColors.successStrong/warningStrong/errorStrong',
  r'BoxDecoration\(\s*color: Colors\.white\b(?!\.with)':
      'nền trắng cố định; dùng context.colors.surface',
  r'(backgroundColor|fillColor): Colors\.white\b(?!\.with)':
      'nền trắng cố định; dùng context.colors.surface',
  r'\b(TextStyle|Icon)\([^()]*\bcolor: (AppColors\.(primary|primaryDark|vocabulary|jlpt|exercise|lesson|error)|AppTheme\.primaryColor|Colors\.(purple|deepPurple|indigo|blue|red|pink|teal|green|brown))\b(?!\.with)':
      'màu quá tối để làm chữ trên nền tối; dùng context.colors.primary/error hoặc context.colors.readable(...)',
  r'BoxDecoration\(\s*color: (AppColors\.\w+),(?:(?!BoxDecoration)[\s\S]){0,400}?(?:TextStyle|Icon)\([^()]*\bcolor: \1\b(?!\.with)':
      'chữ cùng màu với nền đặc của nó, không đọc được; làm nhạt nền bằng withValues(alpha:)',
};

/// Chỗ được phép, kèm lý do: giao diện ở đây không đổi theo chế độ sáng / tối.
const _allowed = <String, String>{
  'lib/features/home/widgets/next_lesson_card.dart':
      'nút trắng trên thẻ xanh, thẻ giữ màu ở cả hai chế độ',
  'lib/features/lessons/widgets/video/lesson_video_player.dart':
      'khung video luôn nền đen',
  'lib/shared/widgets/chunky_card.dart':
      'mép thẻ tính từ màu nền bằng Color.lerp',
};

void main() {
  test('màn hình không dùng màu chỉ đúng ở chế độ sáng', () {
    final violations = <String>[];

    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => (file: file, path: file.path.replaceAll(r'\', '/')))
        .where((entry) =>
            !entry.path.startsWith('lib/app/theme/') &&
            !_allowed.containsKey(entry.path));

    for (final (:file, :path) in files) {
      final source = _withoutComments(file.readAsStringSync());
      for (final rule in _forbidden.entries) {
        for (final match in RegExp(rule.key).allMatches(source)) {
          final line =
              '\n'.allMatches(source.substring(0, match.start)).length + 1;
          violations.add(
              '$path:$line ${match.group(0)!.split('\n').first.trim()} — ${rule.value}');
        }
      }
    }

    expect(violations, isEmpty,
        reason: '${violations.length} chỗ:\n${violations.join('\n')}');
  });

  test('danh sách ngoại lệ không giữ file đã xoá', () {
    for (final path in _allowed.keys) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
}

/// Bỏ chú thích `//`, giữ nguyên số dòng. Chuỗi có `//` (đường dẫn URL) bị cắt cũng
/// không sao vì quy tắc chỉ nhắm vào mã màu.
String _withoutComments(String source) =>
    source.replaceAll(RegExp(r'//[^\n]*'), '');
