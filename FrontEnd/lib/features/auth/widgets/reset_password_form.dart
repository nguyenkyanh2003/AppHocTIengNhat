import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';

/// Form nhập mật khẩu mới của luồng khôi phục mật khẩu.
///
/// Chỉ trình bày và kiểm tra dữ liệu nhập; việc gọi service do màn hình đảm nhận.
class ResetPasswordForm extends StatefulWidget {
  const ResetPasswordForm({
    super.key,
    required this.isSubmitting,
    required this.onSubmit,
    this.errorMessage,
  });

  /// Ngưỡng này phải khớp với rule của backend, nếu không người dùng sẽ nhận
  /// lỗi 400 sau khi form đã báo hợp lệ.
  static const int minPasswordLength = 8;

  final bool isSubmitting;
  final String? errorMessage;
  final Future<void> Function(String newPassword) onSubmit;

  @override
  State<ResetPasswordForm> createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends State<ResetPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.errorMessage != null) ...[
            _ErrorBanner(message: widget.errorMessage!),
            const SizedBox(height: AppSpacing.lg),
          ],
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mật khẩu mới',
              hintText:
                  'Tối thiểu ${ResetPasswordForm.minPasswordLength} ký tự',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: const OutlineInputBorder(borderRadius: AppRadius.mdAll),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mật khẩu mới';
              }
              if (value.length < ResetPasswordForm.minPasswordLength) {
                return 'Mật khẩu phải có ít nhất '
                    '${ResetPasswordForm.minPasswordLength} ký tự';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Nhập lại mật khẩu mới',
              prefixIcon: const Icon(Icons.lock_reset),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              border: const OutlineInputBorder(borderRadius: AppRadius.mdAll),
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Mật khẩu nhập lại không khớp';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: widget.isSubmitting ? null : _submit,
            child: widget.isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Đặt lại mật khẩu'),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(message, style: TextStyle(color: color))),
        ],
      ),
    );
  }
}
