import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/localization/app_localizations.dart';
import '../models/password_policy.dart';
import '../providers/auth_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../widgets/password_form_field.dart';
import '../widgets/change_password_parts.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  static final _fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
  );
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Bảng "Yêu cầu mật khẩu" đọc cả ba ô: gõ ở ô nào cũng vẽ lại để dấu tích
    // cập nhật ngay, không đợi bấm nút.
    for (final controller in [
      _oldPasswordController,
      _newPasswordController,
      _confirmPasswordController
    ]) {
      controller.addListener(_refreshRequirements);
    }
  }

  void _refreshRequirements() => setState(() {});

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Đổi mật khẩu qua [AuthProvider].
  ///
  /// Đổi mật khẩu thành công cũng thu hồi chính phiên đang dùng, nên không thể
  /// `pop` về màn trước như trước đây: token trong tay app đã chết và mọi màn
  /// hình phía sau sẽ lần lượt báo lỗi. Provider dọn phiên, màn hình đưa người
  /// dùng về đăng nhập và xoá lịch sử điều hướng.
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.changePassword(
      _oldPasswordController.text,
      _newPasswordController.text,
    );

    if (!mounted) return;

    if (!success) {
      setState(() {
        _isLoading = false;
        _errorMessage = authProvider.error ?? 'Không thể đổi mật khẩu.';
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đổi mật khẩu thành công! Vui lòng đăng nhập lại.'),
        backgroundColor: AppColors.successStrong,
      ),
    );

    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Đổi mật khẩu',
      body: SingleChildScrollView(
        child: ContentPane(
          maxWidth: AppContentWidth.form,
          child: Column(
            children: [
              const ChangePasswordHeader(),

              // Form
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null) ...[
                        FormErrorBox(message: _errorMessage!),
                        const SizedBox(height: 20),
                      ],

                      // Old Password
                      PasswordFormField(
                        controller: _oldPasswordController,
                        labelText: 'Mật khẩu hiện tại',
                        hintText: 'Nhập mật khẩu hiện tại',
                        prefixIcon: Icons.lock_outline,
                        border: _fieldBorder,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mật khẩu hiện tại';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // New Password
                      PasswordFormField(
                        controller: _newPasswordController,
                        labelText: 'Mật khẩu mới',
                        hintText: 'Nhập mật khẩu mới',
                        prefixIcon: Icons.lock,
                        border: _fieldBorder,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mật khẩu mới';
                          }
                          if (value.length < PasswordPolicy.minLength) {
                            return AppLocalizations.of(context)
                                .passwordMinLength(PasswordPolicy.minLength);
                          }
                          if (value == _oldPasswordController.text) {
                            return 'Mật khẩu mới phải khác mật khẩu hiện tại';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Confirm Password
                      PasswordFormField(
                        controller: _confirmPasswordController,
                        labelText: 'Xác nhận mật khẩu mới',
                        hintText: 'Nhập lại mật khẩu mới',
                        prefixIcon: Icons.lock_clock,
                        border: _fieldBorder,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng xác nhận mật khẩu mới';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Mật khẩu xác nhận không khớp';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Password requirements
                      PasswordRequirements(
                        rules: [
                          (
                            AppLocalizations.of(context)
                                .passwordMinHint(PasswordPolicy.minLength),
                            _newPasswordController.text.length >=
                                PasswordPolicy.minLength,
                          ),
                          (
                            'Khác mật khẩu hiện tại',
                            _newPasswordController.text.isNotEmpty &&
                                _newPasswordController.text !=
                                    _oldPasswordController.text,
                          ),
                          (
                            'Xác nhận mật khẩu khớp',
                            _confirmPasswordController.text.isNotEmpty &&
                                _confirmPasswordController.text ==
                                    _newPasswordController.text,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor:
                                AppColors.primary.withValues(alpha: 0.5),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Đổi mật khẩu',
                                  style: TextStyle(
                                    fontSize: AppTypography.body,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
