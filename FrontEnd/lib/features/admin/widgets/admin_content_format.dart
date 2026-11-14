import 'package:flutter/material.dart';
import '../../../app/theme/app_tokens.dart';

String adminContentTypeLabel(String type) => switch (type) {
      'vocabulary' => 'Từ vựng',
      'kanji' => 'Kanji',
      'grammar' => 'Ngữ pháp',
      'lessons' => 'Bài học',
      _ => type,
    };

/// Chữ chính của một mục trong cột "Nội dung" của bảng: mỗi loại nội dung lưu
/// mặt chữ ở một trường khác nhau.
String adminContentHeadline(String type, Map<String, dynamic> item) => switch (type) {
      'vocabulary' => '${item['word'] ?? ''} (${item['hiragana'] ?? ''})',
      'kanji' => '${item['character'] ?? ''}',
      _ => '${item['title'] ?? item['structure'] ?? ''}',
    };

/// Tên đầy đủ của một mục, kèm nghĩa — dùng ở thẻ và hộp xác nhận xoá.
String adminContentTitle(String type, Map<String, dynamic> item) => switch (type) {
      'vocabulary' => adminContentHeadline(type, item),
      'kanji' => '${item['character'] ?? ''} — ${item['meaning'] ?? ''}',
      'grammar' => '${item['title'] ?? ''} — ${item['meaning'] ?? ''}',
      'lessons' => item['title']?.toString() ?? '',
      _ => '',
    };

String? adminContentReferenceId(dynamic value) {
  if (value is Map) return (value['_id'] ?? value['id'])?.toString();
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

String? adminContentItemId(Map<String, dynamic>? item) =>
    item == null ? null : adminContentReferenceId(item['_id'] ?? item['id']);

/// Báo kết quả thao tác nội dung.
void showAdminContentMessage(BuildContext context, String message,
    {required bool success}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor:
          success ? AppColors.successStrong : AppColors.errorStrong,
    ),
  );
}
