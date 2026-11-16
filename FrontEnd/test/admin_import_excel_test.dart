import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apphoctiengnnhat/core/network/api_client.dart';
import 'package:apphoctiengnnhat/core/network/api_envelope.dart';
import 'package:apphoctiengnnhat/features/admin/models/admin_content_type.dart';
import 'package:apphoctiengnnhat/features/admin/providers/admin_content_provider.dart';
import 'package:apphoctiengnnhat/features/admin/services/admin_service.dart';
import 'package:apphoctiengnnhat/features/admin/widgets/excel_import_options_dialog.dart';
import 'package:apphoctiengnnhat/features/lessons/models/lesson.dart';

const _lessonId = '507f1f77bcf86cd799439011';
final _bytes = <int>[1, 2, 3];
final _lesson = Lesson.fromJson(const {'_id': _lessonId, 'title': 'Bài 1', 'level': 'N4'});

/// Service giả: không chạm mạng, ghi lại tham số của mỗi lần import.
class _FakeAdminService extends AdminService {
  final List<Map<String, String?>> vocabularyImports = [];
  final List<String> kanjiImports = [];
  final List<AdminContentType> reloads = [];
  final List<JsonObject> created = [];

  Object? importError;

  /// Dòng CSV có `word` trùng giá trị này bị server từ chối.
  String? rejectWord;

  @override
  Future<void> importVocabularyExcel(List<int> bytes, String fileName, {required String lesson, required String level}) async {
    vocabularyImports.add({'fileName': fileName, 'lesson': lesson, 'level': level});
    if (importError != null) throw importError!;
  }

  @override
  Future<void> importKanjiExcel(List<int> bytes, String fileName) async {
    kanjiImports.add(fileName);
    if (importError != null) throw importError!;
  }

  @override
  Future<void> createContent(AdminContentType type, JsonObject document) async {
    if (document['word'] == rejectWord) throw BadRequestException('Từ đã tồn tại.');
    created.add(document);
  }

  @override
  Future<Paged<JsonObject>> content(AdminContentType type, {int page = 1}) async {
    reloads.add(type);
    return const Paged(items: [], page: 1, limit: 50, total: 0, totalPages: 0);
  }
}

Future<(AdminContentProvider, _FakeAdminService)> _provider(AdminContentType type) async {
  final service = _FakeAdminService();
  final provider = AdminContentProvider(service: service);
  await provider.selectType(type);
  service.reloads.clear();
  return (provider, service);
}

Widget _dialogHost(
  List<Lesson> lessons,
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
      final (provider, service) = await _provider(AdminContentType.vocabulary);

      final error = await provider.importExcel(_bytes, 'tu-vung.xlsx', lesson: _lessonId, level: 'N4');

      expect(error, isNull);
      expect(service.vocabularyImports, [
        {'fileName': 'tu-vung.xlsx', 'lesson': _lessonId, 'level': 'N4'},
      ]);
      expect(service.reloads, [AdminContentType.vocabulary]);
      expect(provider.isImporting, isFalse);
    });

    test('thiếu lesson hoặc level thì không gửi request và nói rõ cần chọn gì', () async {
      final (provider, service) = await _provider(AdminContentType.vocabulary);

      for (final (lesson, level) in [(null, 'N4'), (_lessonId, null), ('', '')]) {
        expect(
          await provider.importExcel(_bytes, 'a.xlsx', lesson: lesson, level: level),
          'Cần chọn bài học và cấp độ trước khi import.',
        );
      }
      expect(service.vocabularyImports, isEmpty);
    });

    test('lỗi API trả về để màn hình hiển thị, danh sách không tải lại', () async {
      final (provider, service) = await _provider(AdminContentType.vocabulary);
      service.importError = BadRequestException('Dữ liệu gửi lên không hợp lệ.');

      final error = await provider.importExcel(_bytes, 'tu-vung.xlsx', lesson: _lessonId, level: 'N4');

      expect(error, contains('không hợp lệ'));
      expect(service.reloads, isEmpty);
    });

    test('Kanji giữ contract theo dòng, không nhận lesson/level dùng chung', () async {
      final (provider, service) = await _provider(AdminContentType.kanji);

      expect(await provider.importExcel(_bytes, 'kanji.xlsx'), isNull);
      expect(service.kanjiImports, ['kanji.xlsx']);
      expect(service.vocabularyImports, isEmpty);
    });

    test('ngữ pháp không có importer Excel', () async {
      final (provider, _) = await _provider(AdminContentType.grammar);

      expect(await provider.importExcel(_bytes, 'a.xlsx'), 'Excel chỉ hỗ trợ từ vựng và Kanji.');
    });

    test('CSV dừng ở dòng hỏng đầu tiên và chỉ đúng dòng đó trong tệp', () async {
      final (provider, service) = await _provider(AdminContentType.vocabulary);
      service.rejectWord = '先生';

      final result = await provider.importRows([
        {'word': '学生'},
        {'word': '先生'},
        {'word': '学校'},
      ]);

      expect(result.imported, 1);
      expect(result.error, 'Dòng 3: Từ đã tồn tại.');
      expect(service.created, [
        {'word': '学生'},
      ]);
      expect(service.reloads, [AdminContentType.vocabulary], reason: 'đã tạo được dòng nào thì tải lại');
    });
  });

  group('hộp thoại chọn bài học và cấp độ', () {
    testWidgets('huỷ thì không trả về lựa chọn nào', (tester) async {
      ExcelImportOptions? result;
      var called = false;

      await tester.pumpWidget(_dialogHost(
        [_lesson],
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
        [_lesson],
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
