import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../models/password_policy.dart';
import '../providers/auth_provider.dart';
import '../widgets/password_form_field.dart';

/// Đăng ký tài khoản. Số điện thoại, địa chỉ… điền sau ở trang hồ sơ: API đăng
/// ký chỉ nhận tên đăng nhập, họ tên, email và mật khẩu.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  static final _email = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    // `register` không ném: thất bại (trùng tên, mất mạng…) trả `false` kèm `auth.error`.
    final registered = await auth.register(
      _usernameController.text,
      _fullNameController.text,
      _emailController.text,
      _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(registered ? 'Đăng ký thành công!' : 'Đăng ký thất bại: ${auth.error ?? 'vui lòng thử lại.'}'),
        backgroundColor: registered ? AppColors.successStrong : AppColors.errorStrong,
      ),
    );
    if (registered) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const gap = SizedBox(height: AppSpacing.lg);
    return AppScaffold(
      title: 'Đăng ký',
      body: SafeArea(
        child: SingleChildScrollView(
          child: ContentPane(
            maxWidth: AppContentWidth.form,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  Icon(Icons.person_add, size: 80, color: context.colors.primary),
                  gap,
                  Text(
                    'Tạo tài khoản mới',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên người dùng',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Vui lòng nhập tên người dùng';
                      if (value.length < 3) return 'Tên người dùng phải có ít nhất 3 ký tự';
                      return null;
                    },
                  ),
                  gap,
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và Tên',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập họ và tên' : null,
                    textCapitalization: TextCapitalization.words,
                  ),
                  gap,
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Vui lòng nhập email';
                      if (!_email.hasMatch(value)) return 'Email không hợp lệ';
                      return null;
                    },
                  ),
                  gap,
                  PasswordFormField(
                    controller: _passwordController,
                    labelText: 'Mật khẩu',
                    helperText: l10n.passwordMinHint(PasswordPolicy.minLength),
                    prefixIcon: Icons.lock,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
                      if (value.length < PasswordPolicy.minLength) {
                        return l10n.passwordMinLength(PasswordPolicy.minLength);
                      }
                      return null;
                    },
                  ),
                  gap,
                  PasswordFormField(
                    controller: _confirmPasswordController,
                    labelText: 'Xác nhận mật khẩu',
                    prefixIcon: Icons.lock_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                      if (value != _passwordController.text) return 'Mật khẩu không khớp';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Đăng ký', style: TextStyle(fontSize: AppTypography.body)),
                  ),
                  gap,
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Đã có tài khoản?'),
                      TextButton(onPressed: () => context.go('/login'), child: const Text('Đăng nhập')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
