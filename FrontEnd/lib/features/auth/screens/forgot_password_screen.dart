import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/forgot_password_sent.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final provider = context.read<AuthProvider>();
    final sent = await provider.forgotPassword(_emailController.text.trim());
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _emailSent = sent;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(sent
            ? 'Email đặt lại mật khẩu đã được gửi!'
            : provider.error ?? 'Không thể gửi yêu cầu đặt lại mật khẩu.'),
        backgroundColor: sent ? AppColors.successStrong : AppColors.errorStrong,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Quên mật khẩu',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ContentPane(
              maxWidth: AppContentWidth.form,
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: _emailSent
                  ? ForgotPasswordSentView(
                      email: _emailController.text,
                      onResend: () => setState(() => _emailSent = false),
                    )
                  : _buildFormView(),
            ),
          ),
        ),
      ),
      backgroundColor: context.colors.background,
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_reset,
              size: 40,
              color: context.colors.primary,
            ),
          ),

          const SizedBox(height: 24),

          // Tiêu đề
          Text(
            'Đặt lại mật khẩu',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.primary,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Mô tả
          Text(
            'Nhập email của bạn để nhận liên kết đặt lại mật khẩu',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleResetPassword(),
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Nhập địa chỉ email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Email không hợp lệ';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Nút gửi
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleResetPassword,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Gửi email',
                      style: TextStyle(
                        fontSize: AppTypography.body,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Quay lại đăng nhập
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Nhớ mật khẩu?'),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đăng nhập'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
