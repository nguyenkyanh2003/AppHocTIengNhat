import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Máy kiểm "một kiểu" của luồng dữ liệu Flutter (spec one-style §4.3): service
/// trả model, provider giữ `ViewState`. Phần màn hình/widget không tự gọi
/// service đã có `screen_guard_test.dart` giữ.
///
/// Feature chưa chuyển khuôn nằm trong [_legacyFeatures]. Chuyển xong feature
/// nào thì gỡ tên nó; danh sách phải rỗng khi đợt chuyển khuôn kết thúc.
const _legacyFeatures = <String>{
  'admin',
  'auth',
  'exercise',
  'flashcards',
  'jlpt',
  'lessons',
  'profile',
  'streaks',
  'study_groups',
};

/// Provider tự quản bộ ba cờ thay vì `ViewState`. Cờ có tên riêng
/// (`_isLoadingMore`, `_isSaving`) vẫn được phép: so khớp nguyên từ.
final _manualState = RegExp(r'\b(?:bool|String\??)\s+(_isLoading|_error)\b');

/// Lời gọi API trả `Map` thô, buộc provider phải đoán tên khoá. Hàm đồng bộ dựng
/// body/query của request (trả `Map` ngay) không tính.
final _rawMapReturn = RegExp(r'Future<Map<String,\s*dynamic>\??>\s+\w+\(');

Iterable<String> _features() => Directory('lib/features')
    .listSync()
    .whereType<Directory>()
    .map((dir) => dir.uri.pathSegments.where((segment) => segment.isNotEmpty).last);

Iterable<File> _dartFiles(String feature, String layer) {
  final dir = Directory('lib/features/$feature/$layer');
  if (!dir.existsSync()) return const [];
  return dir.listSync(recursive: true).whereType<File>().where((file) => file.path.endsWith('.dart'));
}

String _path(File file) => file.path.replaceAll(r'\', '/');

/// Mọi chỗ một feature còn lệch khuôn; rỗng là feature đã theo khuôn.
List<String> _violationsOf(String feature) {
  final found = <String>[];
  for (final file in _dartFiles(feature, 'providers')) {
    for (final match in _manualState.allMatches(file.readAsStringSync())) {
      found.add('${_path(file)}: provider tự giữ ${match.group(1)} thay vì ViewState');
    }
  }
  for (final file in _dartFiles(feature, 'services')) {
    final lines = file.readAsLinesSync();
    for (var index = 0; index < lines.length; index++) {
      // Hàm riêng của file (tên bắt đầu bằng `_`) không phải mặt ngoài của service.
      final line = lines[index];
      if (_rawMapReturn.hasMatch(line) && !RegExp(r'\s_\w+\(').hasMatch(line)) {
        found.add('${_path(file)}:${index + 1}: service trả Map thô');
      }
    }
  }
  return found;
}

void main() {
  test('feature ngoài danh sách miễn: provider dùng ViewState, service trả model', () {
    final violations = _features().where((feature) => !_legacyFeatures.contains(feature)).expand(_violationsOf);

    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('danh sách miễn chỉ chứa feature có thật và còn lệch khuôn', () {
    final features = _features().toSet();
    expect(_legacyFeatures.difference(features), isEmpty, reason: 'tên không còn là thư mục feature');

    final alreadyClean = _legacyFeatures.where((feature) => _violationsOf(feature).isEmpty);
    expect(alreadyClean, isEmpty, reason: 'feature đã theo khuôn thì gỡ khỏi danh sách miễn');
  });
}
