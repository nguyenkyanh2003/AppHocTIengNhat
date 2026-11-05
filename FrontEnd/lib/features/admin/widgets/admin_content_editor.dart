import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../../../shared/widgets/app_dialog.dart';
import 'admin_content_format.dart';

/// Hộp thoại thêm, sửa hoặc nhân bản một mục nội dung.
Future<void> showAdminContentEditor(BuildContext context,
    {Map<String, dynamic>? item,
    bool duplicate = false,
    required String selectedContentType}) async {
  final hostContext = context;
  final type = selectedContentType;
  final editing = item != null && !duplicate;
  final formKey = GlobalKey<FormState>();
  final controllers = _editorControllers(type, item, duplicate);
  var level =
      _levels.contains(item?['level']) ? item!['level'] as String : 'N5';

  // Biểu mẫu này chặn bấm ra ngoài để khỏi mất dữ liệu đang nhập, nhưng Esc
  // vẫn phải đóng được — `showDialog` gộp hai thứ đó vào một cờ.
  final payload = await showAppDialog<Map<String, dynamic>>(
    context: context,
    dismissOnBarrierTap: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(
          editing
              ? 'Chỉnh sửa ${adminContentTypeLabel(type)}'
              : duplicate
                  ? 'Nhân bản ${adminContentTypeLabel(type)}'
                  : 'Thêm ${adminContentTypeLabel(type)}',
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: _editorFields(
                type,
                controllers,
                level,
                (value) => setDialogState(() => level = value),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(
                dialogContext,
                _editorPayload(type, controllers, level),
              );
            },
            child: Text(editing ? 'Lưu' : 'Tạo'),
          ),
        ],
      ),
    ),
  );

  for (final controller in controllers.values) {
    controller.dispose();
  }
  if (payload == null || !hostContext.mounted) return;

  final provider = context.read<AdminProvider>();
  final id = adminContentItemId(item);
  final success = switch (type) {
    'vocabulary' => editing
        ? await provider.updateVocabulary(id!, payload)
        : await provider.createVocabulary(payload),
    'kanji' => editing
        ? await provider.updateKanji(id!, payload)
        : await provider.createKanji(payload),
    'grammar' => editing
        ? await provider.updateGrammar(id!, payload)
        : await provider.createGrammar(payload),
    'lessons' => editing
        ? await provider.updateLesson(id!, payload)
        : await provider.createLesson(payload),
    _ => false,
  };
  if (!hostContext.mounted) return;
  showAdminContentMessage(
      context,
      success
          ? editing
              ? 'Đã cập nhật nội dung.'
              : 'Đã tạo nội dung mới.'
          : provider.error ?? 'Không thể lưu nội dung.',
      success: success);
}

Map<String, TextEditingController> _editorControllers(
  String type,
  Map<String, dynamic>? item,
  bool duplicate,
) {
  String text(String key) => item?[key]?.toString() ?? '';
  String listText(String key) {
    final value = item?[key];
    return value is List ? value.join(', ') : value?.toString() ?? '';
  }

  final firstExample = item?['examples'] is List &&
          (item!['examples'] as List).isNotEmpty &&
          (item['examples'] as List).first is Map
      ? Map<String, dynamic>.from((item['examples'] as List).first as Map)
      : const <String, dynamic>{};
  var title = text(type == 'vocabulary'
      ? 'word'
      : type == 'kanji'
          ? 'character'
          : 'title');
  if (duplicate && type == 'kanji') title = '';
  if (duplicate && (type == 'grammar' || type == 'lessons')) {
    title = '$title (bản sao)';
  }

  return {
    'title': TextEditingController(text: title),
    'reading': TextEditingController(text: text('hiragana')),
    'meaning': TextEditingController(text: text('meaning')),
    'lesson': TextEditingController(
      text: adminContentReferenceId(
              item?[type == 'grammar' ? 'lesson_id' : 'lesson']) ??
          adminContentReferenceId(item?['lessonId']) ??
          '',
    ),
    'context': TextEditingController(text: text('usage_context')),
    'onyomi': TextEditingController(text: listText('onyomi')),
    'kunyomi': TextEditingController(text: listText('kunyomi')),
    'hanviet': TextEditingController(text: text('hanviet')),
    'structure': TextEditingController(text: text('structure')),
    'usage': TextEditingController(text: text('usage')),
    'example': TextEditingController(
      text: firstExample['sentence']?.toString() ?? '',
    ),
    'exampleMeaning': TextEditingController(
      text: firstExample['meaning']?.toString() ?? '',
    ),
    'description': TextEditingController(text: text('description')),
    'content': TextEditingController(text: text('content_html')),
    'lessonType': TextEditingController(text: text('type')),
    'order': TextEditingController(
      text: text('order').isEmpty ? '1' : text('order'),
    ),
  };
}

Widget _editorFields(
  String type,
  Map<String, TextEditingController> controllers,
  String level,
  ValueChanged<String> onLevelChanged,
) {
  final fields = <Widget>[];
  void add(Widget child) {
    if (fields.isNotEmpty) fields.add(const SizedBox(height: 12));
    fields.add(child);
  }

  switch (type) {
    case 'vocabulary':
      add(_field(controllers['title']!, 'Từ vựng', required: true));
      add(_field(controllers['reading']!, 'Hiragana', required: true));
      add(_field(controllers['meaning']!, 'Nghĩa', required: true));
      add(_field(controllers['lesson']!, 'ID bài học', required: true));
      add(_field(controllers['context']!, 'Tình huống sử dụng'));
      break;
    case 'kanji':
      add(_field(controllers['title']!, 'Ký tự Kanji', required: true));
      add(_field(controllers['meaning']!, 'Nghĩa', required: true));
      add(_field(controllers['hanviet']!, 'Âm Hán Việt'));
      add(_field(controllers['onyomi']!, 'Âm On, cách nhau bằng dấu phẩy'));
      add(_field(controllers['kunyomi']!, 'Âm Kun, cách nhau bằng dấu phẩy'));
      add(_field(controllers['lesson']!, 'ID bài học', required: true));
      break;
    case 'grammar':
      add(_field(controllers['title']!, 'Tên ngữ pháp', required: true));
      add(_field(controllers['structure']!, 'Cấu trúc', required: true));
      add(_field(controllers['meaning']!, 'Ý nghĩa', required: true));
      add(_field(controllers['usage']!, 'Cách dùng', lines: 3));
      add(_field(controllers['lesson']!, 'ID bài học (không bắt buộc)'));
      add(_field(controllers['example']!, 'Câu ví dụ'));
      add(_field(controllers['exampleMeaning']!, 'Nghĩa câu ví dụ'));
      break;
    case 'lessons':
      add(_field(controllers['title']!, 'Tiêu đề bài học', required: true));
      add(_field(controllers['order']!, 'Thứ tự',
          required: true, number: true));
      add(_field(controllers['lessonType']!, 'Loại bài học'));
      add(_field(controllers['description']!, 'Mô tả', lines: 3));
      add(_field(controllers['content']!, 'Nội dung HTML', lines: 5));
      break;
  }
  add(
    DropdownButtonFormField<String>(
      value: level,
      decoration: const InputDecoration(
        labelText: 'Cấp độ',
        border: OutlineInputBorder(),
      ),
      items: _levels
          .map((value) => DropdownMenuItem(value: value, child: Text(value)))
          .toList(),
      onChanged: (value) {
        if (value != null) onLevelChanged(value);
      },
    ),
  );
  return Column(mainAxisSize: MainAxisSize.min, children: fields);
}

Widget _field(
  TextEditingController controller,
  String label, {
  bool required = false,
  bool number = false,
  int lines = 1,
}) {
  return TextFormField(
    controller: controller,
    maxLines: lines,
    keyboardType: number ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator: required
        ? (value) => value == null || value.trim().isEmpty
            ? 'Vui lòng nhập $label.'
            : number && int.tryParse(value) == null
                ? '$label phải là số nguyên.'
                : null
        : null,
  );
}

Map<String, dynamic> _editorPayload(
  String type,
  Map<String, TextEditingController> controllers,
  String level,
) {
  String value(String key) => controllers[key]!.text.trim();
  List<String> readings(String key) => value(key)
      .split(RegExp(r'[,;、]'))
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList();

  return switch (type) {
    'vocabulary' => {
        'word': value('title'),
        'hiragana': value('reading'),
        'meaning': value('meaning'),
        'level': level,
        'lesson': value('lesson'),
        if (value('context').isNotEmpty) 'usage_context': value('context'),
      },
    'kanji' => {
        'character': value('title'),
        'meaning': value('meaning'),
        'level': level,
        'lessonId': value('lesson'),
        'onyomi': readings('onyomi'),
        'kunyomi': readings('kunyomi'),
        if (value('hanviet').isNotEmpty) 'hanviet': value('hanviet'),
      },
    'grammar' => {
        'title': value('title'),
        'structure': value('structure'),
        'meaning': value('meaning'),
        'level': level,
        if (value('usage').isNotEmpty) 'usage': value('usage'),
        if (value('lesson').isNotEmpty) 'lessonID': value('lesson'),
        if (value('example').isNotEmpty)
          'examples': [
            {
              'sentence': value('example'),
              'meaning': value('exampleMeaning'),
            },
          ],
      },
    'lessons' => {
        'title': value('title'),
        'level': level,
        'order': int.parse(value('order')),
        if (value('lessonType').isNotEmpty) 'type': value('lessonType'),
        if (value('description').isNotEmpty)
          'description': value('description'),
        if (value('content').isNotEmpty) 'content_html': value('content'),
      },
    _ => const {},
  };
}

const _levels = ['N5', 'N4', 'N3', 'N2', 'N1'];
