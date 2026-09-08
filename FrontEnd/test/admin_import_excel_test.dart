import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/features/admin/providers/admin_provider.dart';
import 'package:apphoctiengnnhat/features/admin/services/admin_service.dart';
import 'package:apphoctiengnnhat/features/admin/widgets/excel_import_options_dialog.dart';

const _lessonId = '507f1f77bcf86cd799439011';
final _bytes = <int>[1, 2, 3];

/// Service giả: không chạm mạng, ghi lại tham số của mỗi lần import.
class _FakeAdminService extends AdminService {
  final List<Map<String, String?>> vocabularyImports = [];
  final List<String> kanjiImports = [];
  int vocabularyReloads = 0;

  Object? importError;

  @override
  Future<Map<String, dynamic>> importVocabularyExcel(
    List<int> bytes,
    String fileName, {
    required String lesson,
    required String level,
  }) async {
    vocabularyImports.add({
      'fileName': fileName,
      'lesson': lesson,
      'level': level,
    });
    if (importError != null) throw importError!;
    return {'message': 'ok'};
  }

  @override
  Future<Map<String, dynamic>> importKanjiExcel(
    List<int> bytes,
    String fileName,
  ) async {
    kanjiImports.add(fileName);
    if (importError != null) throw importError!;
    return {'message': 'ok'};
  }

  @override
  Future<List<dynamic>> getVocabulary({
    int page = 1,
    int limit = 50,
    String? level,
  }) async {
    vocabularyReloads += 1;
    return const [];
  }

  @override
  Future<List<dynamic>> getKanji({
    int page = 1,
    int limit = 50,
    String? level,
  }) async =>
      const [];

  @override
  Future<List<dynamic>> getLessons({
    int page = 1,
    int limit = 50,
    String? level,
  }) async =>
      const [
        {'_id': _lessonId, 'title': 'Bài 1', 'level': 'N4'},
      ];
}

Widget _dialogHost(
  List<Map<String, dynamic>> lessons,
  void Function(ExcelImportOptions?) onResult,
) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            final result = await showDialog<ExcelImportOptions>(
              context: context,
              builder: (_) => ExcelImportOptionsDialog(lessons: lessons),
            );
            onResult(result);
          },
          child: const Text('Mở'),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('provider gửi metadata import', () {
    test('từ vựng gửi kèm lesson và level rồi tải lại danh sách', () async {
      final service = _FakeAdminService();
      final provider = AdminProvider(adminService: service);

      final ok = await provider.importExcel(
        'vocabulary',
        _bytes,
        'tu-vung.xlsx',
        lesson: _lessonId,
        level: 'N4',
      );

      expect(ok, isTrue);
      expect(service.vocabularyImports, [
        {'fileName': 'tu-vung.xlsx', 'lesson': _lessonId, 'level': 'N4'},
      ]);
      expect(service.vocabularyReloads, 1);
    });

    test('thiếu lesson hoặc level thì không gửi request', () async {
      final service = _FakeAdminService();
      final provider = AdminProvider(adminService: service);

      expect(
        await provider.importExcel('vocabulary', _bytes, 'a.xlsx', level: 'N4'),
        isFalse,
      );
      expect(
        await provider.importExcel(
          'vocabulary',
          _bytes,
          'a.xlsx',
          lesson: _lessonId,
        ),
        isFalse,
      );
      expect(
        await provider.importExcel(
          'vocabulary',
          _bytes,
          'a.xlsx',
          lesson: '',
          level: '',
        ),
        isFalse,
      );

      expect(service.vocabularyImports, isEmpty);
      expect(provider.error, isNotNull);
    });

    test('lỗi API được giữ lại để màn hình hiển thị', () async {
      final service = _FakeAdminService()
        ..importError = Exception('Dữ liệu gửi lên không hợp lệ.');
      final provider = AdminProvider(adminService: service);

      final ok = await provider.importExcel(
        'vocabulary',
        _bytes,
        'tu-vung.xlsx',
        lesson: _lessonId,
        level: 'N4',
      );

      expect(ok, isFalse);
      expect(provider.error, contains('không hợp lệ'));
    });

    test('Kanji giữ contract theo dòng, không nhận lesson/level dùng chung',
        () async {
      final service = _FakeAdminService();
      final provider = AdminProvider(adminService: service);

      final ok = await provider.importExcel('kanji', _bytes, 'kanji.xlsx');

      expect(ok, isTrue);
      expect(service.kanjiImports, ['kanji.xlsx']);
      expect(service.vocabularyImports, isEmpty);
    });
  });

  group('hộp thoại chọn bài học và cấp độ', () {
    testWidgets('huỷ thì không trả về lựa chọn nào', (tester) async {
      ExcelImportOptions? result;
      var called = false;

      await tester.pumpWidget(_dialogHost(
        const [
          {'_id': _lessonId, 'title': 'Bài 1', 'level': 'N4'},
        ],
        (value) {
          called = true;
          result = value;
        },
      ));

      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(result, isNull);
    });

    testWidgets('chọn bài học tự điền cấp độ của bài đó', (tester) async {
      ExcelImportOptions? result;

      await tester.pumpWidget(_dialogHost(
        const [
          {'_id': _lessonId, 'title': 'Bài 1', 'level': 'N4'},
        ],
        (value) => result = value,
      ));

      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bài học'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bài 1').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chọn tệp'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.lessonId, _lessonId);
      expect(result!.level, 'N4');
    });

    testWidgets('chưa chọn đủ thì nút xác nhận bị khoá', (tester) async {
      await tester.pumpWidget(_dialogHost(const [], (_) {}));

      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.textContaining('Chưa có bài học nào'), findsOneWidget);
    });
  });
}
