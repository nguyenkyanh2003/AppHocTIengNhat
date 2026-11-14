import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';

/// Khung ô nhập dùng chung cho form bộ thẻ và thẻ.
InputDecoration flashcardInputDecoration({required String label, String? hint, required IconData icon}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(borderRadius: AppRadius.mdAll),
      prefixIcon: Icon(icon),
    );

/// Kiểm ô bắt buộc: trống thì trả [message].
FormFieldValidator<String> requiredText(String message) =>
    (value) => value == null || value.trim().isEmpty ? message : null;

/// Ô ghi chú nhỏ ở form thẻ.
class FlashcardInfoNote extends StatelessWidget {
  const FlashcardInfoNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.primarySoft,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: context.colors.primarySoft),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: context.colors.primaryStrong),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: AppTypography.caption, color: context.colors.primaryStrong),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút gửi form, hiện vòng xoay khi [loading].
class FlashcardSubmitButton extends StatelessWidget {
  const FlashcardSubmitButton({super.key, required this.label, required this.loading, required this.onPressed});

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(label, style: const TextStyle(fontSize: AppTypography.body, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
