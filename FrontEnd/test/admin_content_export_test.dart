import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/app/theme/app_theme.dart';
import 'package:apphoctiengnnhat/core/network/api_envelope.dart';
import 'package:apphoctiengnnhat/features/admin/models/admin_content_type.dart';
import 'package:apphoctiengnnhat/features/admin/screens/admin_content_management_screen.dart';
import 'package:apphoctiengnnhat/features/admin/services/admin_service.dart';

class _FakeAdminService extends AdminService {
  @override
  Future<Paged<JsonObject>> content(AdminContentType type, {int page = 1}) async => const Paged(
        items: [
          {'_id': 'v1', 'word': '学校', 'hiragana': 'がっこう', 'meaning': 'trường học', 'level': 'N5'},
          {'_id': 'v2', 'word': '先生', 'hiragana': 'せんせい', 'meaning': 'giáo viên', 'level': 'N5'},
          {'_id': 'v3', 'word': '学生', 'hiragana': 'がくせい', 'meaning': 'học sinh', 'level': 'N5'},
        ],
        page: 1,
        limit: 50,
        total: 3,
        totalPages: 1,
      );
}

/// Hộp "Lưu tệp" giả: luôn chọn [path].
class _SaveTo extends FilePicker {
  _SaveTo(this.path);

  final String path;

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async =>
      path;
}

void main() {
  testWidgets('xuất CSV chỉ gồm các dòng đang hiện sau khi lọc', (tester) async {
    final folder = Directory.systemTemp.createTempSync('xuat_csv');
    addTearDown(() => folder.deleteSync(recursive: true));
    final file = File('${folder.path}/tu_vung.csv');
    FilePicker.platform = _SaveTo(file.path);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: AdminContentManagementScreen(service: _FakeAdminService()),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'giáo viên');
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.tap(find.byTooltip('Xuất CSV'));
      for (var waited = 0; waited < 50 && !file.existsSync(); waited++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pumpAndSettle();

    final rows = const LineSplitter().convert(utf8.decode(file.readAsBytesSync()).trim());
    expect(rows, hasLength(2), reason: 'dòng tiêu đề + đúng một dòng đang hiện');
    expect(rows.last, contains('先生'));
    expect(find.text('Đã xuất 1 dòng dữ liệu.'), findsOneWidget);
  });
}
