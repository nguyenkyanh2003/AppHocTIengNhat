import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../models/admin_user.dart';

Color adminUserRoleColor(AdminUser user) => user.isAdmin ? AppColors.error : AppColors.primary;

/// Chữ cái đầu của tên hiển thị, làm ảnh đại diện tạm.
String adminUserInitial(AdminUser user) {
  final name = user.displayName.trim();
  return name.isEmpty ? '?' : name.characters.first.toUpperCase();
}

/// Ngày dạng `d/M/yyyy`; không có ngày thì là [fallback].
String adminDate(DateTime? date, {String fallback = 'Chưa có'}) =>
    date == null ? fallback : '${date.day}/${date.month}/${date.year}';
