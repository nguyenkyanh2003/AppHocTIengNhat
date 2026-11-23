import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../app/state/provider_reset_service.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_typography.dart';
import '../widgets/login_header.dart';
import '../widgets/login_form_fields.dart';
import '../widgets/login_actions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  /// Lỗi của lần đăng nhập gần nhất, hiện ngay trong form.
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Xử lý đăng nhập
  Future<void> _handleLogin() async {
    setState(() => _error = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Reset tất cả providers trước khi login (clear dữ liệu user cũ)
    ProviderResetService.resetAllProviders(context);

    // Gọi API login
    final error = await context.read<AuthProvider>().login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (error == null) {
      // Đăng nhập thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng nhập thành công!'),
          backgroundColor: AppColors.successStrong,
          duration: Duration(seconds: 2),
        ),
      );

      // Finish autofill context để browser lưu thông tin
      TextInput.finishAutofillContext();

      // Clear controllers for security
      _usernameController.clear();
      _passwordController.clear();
      // Không tự chuyển trang: router nghe AuthProvider và đưa về trang định
      // mở (`AppRouter.resolveRedirect`), thay cả stack nên Back không quay
      // lại màn đăng nhập.
    } else {
      // Chỉ clear password khi login thất bại (giữ nguyên username).
      // Lỗi hiện ở khối ngay trong form, không bắn thêm SnackBar: hai chỗ báo
      // cùng một lỗi làm người dùng tưởng có hai vấn đề khác nhau.
      _passwordController.clear();
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ContentPane(
              maxWidth: AppContentWidth.form,
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo và tiêu đề
                      const LoginHeader(),

                      const SizedBox(height: 48),

                      // Lỗi đăng nhập: nền đỏ nhạt để chữ đọc được. Trước đây
                      // nền, viền, icon và chữ cùng dùng `AppColors.error` nên
                      // khối trông như một mảng đỏ rỗng.
                      Builder(
                        builder: (context) {
                          final error = _error;
                          if (error == null || error.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Container(
                            margin:
                                const EdgeInsets.only(bottom: AppSpacing.lg),
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.12),
                              borderRadius: AppRadius.mdAll,
                              border: Border.all(color: context.colors.error),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: context.colors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    error,
                                    style: TextStyle(
                                      color: context.colors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: AppTypography.bodySmall,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Form đăng nhập
                      LoginFormFields(
                          usernameController: _usernameController,
                          passwordController: _passwordController,
                          obscurePassword: _obscurePassword,
                          handleLogin: _handleLogin,
                          togglePassword: _togglePassword),

                      const SizedBox(height: 16),

                      const LoginForgotPasswordLink(),

                      const SizedBox(height: 24),

                      // Nút đăng nhập
                      LoginButton(handleLogin: _handleLogin),

                      const SizedBox(height: 16),

                      // Hoặc
                      const LoginDivider(),

                      const SizedBox(height: 16),

                      // Nút đăng ký
                      const LoginRegisterButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _togglePassword() =>
      setState(() => _obscurePassword = !_obscurePassword);
}
