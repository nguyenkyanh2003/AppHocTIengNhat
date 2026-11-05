import 'package:flutter/material.dart';
import '../../../app/theme/app_tokens.dart';

Color adminUserRoleColor(String role) {
  switch (role) {
    case 'admin':
      return AppColors.error;
    default:
      return AppColors.primary;
  }
}
