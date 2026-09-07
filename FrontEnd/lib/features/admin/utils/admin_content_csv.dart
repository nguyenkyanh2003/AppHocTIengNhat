import 'dart:convert';
import 'dart:typed_data';

abstract final class AdminContentCsv {
  static List<Map<String, dynamic>> decode(
    String contentType,
    List<int> bytes,
  ) {
    final csv =
        utf8.decode(bytes, allowMalformed: false).replaceFirst('\ufeff', '');
    final table = _parse(csv);
    if (table.length < 2) {
      throw const FormatException('Tệp CSV không có dòng dữ liệu.');
    }
    final headers = table.first.map((value) => value.trim()).toList();
    final rows = table
        .skip(1)
        .where((row) => row.any((cell) => cell.trim().isNotEmpty))
        .map((row) {
      final raw = <String, dynamic>{};
      for (var index = 0; index < headers.length; index++) {
        raw[headers[index]] = index < row.length ? row[index].trim() : '';
      }
      return _normalize(contentType, raw);
    }).toList();
    if (rows.isEmpty) {
      throw const FormatException('Tệp CSV không có dữ liệu.');
    }
    return rows;
  }

  static Uint8List encode(
    String contentType,
    List<Map<String, dynamic>> rows,
  ) {
    final selectedColumns = columns(contentType);
    final buffer = StringBuffer()
      ..writeln(selectedColumns.map(_cell).join(','));
    for (final row in rows) {
      buffer.writeln(
        selectedColumns
            .map((column) => _cell(displayValue(row[column])))
            .join(','),
      );
    }
    return Uint8List.fromList([
      0xEF,
      0xBB,
      0xBF,
      ...utf8.encode(buffer.toString()),
    ]);
  }

  static List<String> columns(String type) => switch (type) {
        'vocabulary' => [
            '_id',
            'lesson',
            'word',
            'hiragana',
            'meaning',
            'level',
            'usage_context',
          ],
        'kanji' => [
            '_id',
            'lessonId',
            'character',
            'hanviet',
            'onyomi',
            'kunyomi',
            'meaning',
            'level',
          ],
        'grammar' => [
            '_id',
            'title',
            'structure',
            'meaning',
            'usage',
            'level',
            'lesson_id',
            'difficulty',
            'is_active',
          ],
        'lessons' => [
            '_id',
            'title',
            'level',
            'order',
            'description',
            'type',
            'content_html',
          ],
        _ => throw ArgumentError('Loại nội dung không hợp lệ: $type'),
      };

  static String displayValue(dynamic value) {
    if (value is List) return value.join('|');
    if (value is Map) {
      return (value['_id'] ?? value['id'])?.toString() ?? jsonEncode(value);
    }
    return value?.toString() ?? '';
  }

  static List<List<String>> _parse(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    var quoted = false;

    for (var index = 0; index < input.length; index++) {
      final char = input[index];
      if (char == '"') {
        if (quoted && index + 1 < input.length && input[index + 1] == '"') {
          cell.write('"');
          index++;
        } else {
          quoted = !quoted;
        }
      } else if (char == ',' && !quoted) {
        row.add(cell.toString());
        cell.clear();
      } else if ((char == '\n' || char == '\r') && !quoted) {
        if (char == '\r' &&
            index + 1 < input.length &&
            input[index + 1] == '\n') {
          index++;
        }
        row.add(cell.toString());
        cell.clear();
        rows.add(row);
        row = <String>[];
      } else {
        cell.write(char);
      }
    }
    if (quoted) {
      throw const FormatException('Dấu ngoặc kép trong CSV chưa đóng.');
    }
    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      rows.add(row);
    }
    return rows;
  }

  static Map<String, dynamic> _normalize(
    String type,
    Map<String, dynamic> row,
  ) {
    String value(String key, [String? alias]) =>
        (row[key] ?? (alias == null ? null : row[alias]) ?? '')
            .toString()
            .trim();
    List<String> list(String key) => value(key)
        .split(RegExp(r'[|,;、]'))
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();

    return switch (type) {
      'vocabulary' => {
          'word': value('word'),
          'hiragana': value('hiragana', 'reading'),
          'meaning': value('meaning'),
          'level': value('level'),
          'lesson': value('lesson', 'lessonId'),
          if (value('usage_context').isNotEmpty)
            'usage_context': value('usage_context'),
        },
      'kanji' => {
          'character': value('character'),
          'meaning': value('meaning'),
          'level': value('level'),
          'lessonId': value('lessonId', 'lesson'),
          'onyomi': list('onyomi'),
          'kunyomi': list('kunyomi'),
          if (value('hanviet').isNotEmpty) 'hanviet': value('hanviet'),
        },
      'grammar' => {
          'title': value('title'),
          'structure': value('structure', 'pattern'),
          'meaning': value('meaning'),
          'level': value('level'),
          if (value('usage').isNotEmpty) 'usage': value('usage'),
          if (value('lesson_id', 'lessonID').isNotEmpty)
            'lessonID': value('lesson_id', 'lessonID'),
        },
      'lessons' => {
          'title': value('title'),
          'level': value('level'),
          'order': int.tryParse(value('order')) ?? 1,
          if (value('description').isNotEmpty)
            'description': value('description'),
          if (value('type').isNotEmpty) 'type': value('type'),
          if (value('content_html').isNotEmpty)
            'content_html': value('content_html'),
        },
      _ => throw ArgumentError('Loại nội dung không hợp lệ: $type'),
    };
  }

  static String _cell(Object? value) {
    final text = value?.toString() ?? '';
    return '"${text.replaceAll('"', '""')}"';
  }
}
