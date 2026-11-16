import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/network/api_envelope.dart';
import '../models/admin_content_type.dart';

/// Chữ chính của một mục trong cột "Nội dung" của bảng: mỗi loại nội dung lưu
/// mặt chữ ở một trường khác nhau.
String adminContentHeadline(AdminContentType type, JsonObject item) => switch (type) {
      AdminContentType.vocabulary => '${item['word'] ?? ''} (${item['hiragana'] ?? ''})',
      AdminContentType.kanji => '${item['character'] ?? ''}',
      AdminContentType.grammar || AdminContentType.lessons => '${item['title'] ?? item['structure'] ?? ''}',
    };

/// Tên đầy đủ của một mục, kèm nghĩa — dùng ở thẻ và hộp xác nhận xoá.
String adminContentTitle(AdminContentType type, JsonObject item) => switch (type) {
      AdminContentType.vocabulary => adminContentHeadline(type, item),
      AdminContentType.kanji => '${item['character'] ?? ''} — ${item['meaning'] ?? ''}',
      AdminContentType.grammar => '${item['title'] ?? ''} — ${item['meaning'] ?? ''}',
      AdminContentType.lessons => '${item['title'] ?? ''}',
    };

/// `_id` của một tham chiếu: chuỗi id, hoặc document đã populate.
String? adminContentReferenceId(Object? value) {
  if (value is Map) return (value['_id'] ?? value['id'])?.toString();
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

String? adminContentItemId(JsonObject? item) => item == null ? null : adminContentReferenceId(item['_id']);

/// Báo kết quả thao tác nội dung.
void showAdminContentMessage(BuildContext context, String message, {required bool success}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: success ? AppColors.successStrong : AppColors.errorStrong,
    ),
  );
}
