import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/state/provider_reset_service.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../shared/widgets/content_pane.dart';
import '../../../app/theme/app_typography.dart';

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
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Xử lý đăng nhập
  Future<void> _handleLogin() async {
    context.read<AuthProvider>().clearError();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Reset tất cả providers trước khi login (clear dữ liệu user cũ)
    ProviderResetService.resetAllProviders(context);

    // Gọi API login
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // Đăng nhập thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng nhập thành công!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );

      // Finish autofill context để browser lưu thông tin
      TextInput.finishAutofillContext();

      // Clear controllers for security
      _usernameController.clear();
      _passwordController.clear();

      // Về đúng trang người dùng định mở trước khi bị chặn đăng nhập;
      // `go` thay stack nên nút Back không quay lại được màn đăng nhập.
      final target = GoRouterState.of(context).uri.queryParameters['from'];
      context.go(target == null || target.isEmpty ? '/home' : target);
    } else {
      // Chỉ clear password khi login thất bại (giữ nguyên username).
      // Lỗi hiện ở khối ngay trong form, không bắn thêm SnackBar: hai chỗ báo
      // cùng một lỗi làm người dùng tưởng có hai vấn đề khác nhau.
      _passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
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
                      _buildHeader(),

                      const SizedBox(height: 48),

                      // Lỗi đăng nhập: nền đỏ nhạt để chữ đọc được. Trước đây
                      // nền, viền, icon và chữ cùng dùng `AppColors.error` nên
                      // khối trông như một mảng đỏ rỗng.
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          final error = authProvider.error;
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
                              border: Border.all(color: AppColors.error),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    error,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimaryColor,
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
                      _buildLoginForm(),

                      const SizedBox(height: 16),

                      // Ghi nhớ & Quên mật khẩu
                      _buildRememberAndForgot(),

                      const SizedBox(height: 24),

                      // Nút đăng nhập
                      _buildLoginButton(),

                      const SizedBox(height: 16),

                      // Hoặc
                      _buildDivider(),

                      const SizedBox(height: 16),

                      // Nút đăng ký
                      _buildRegisterButton(),
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

  /// Header với logo và tiêu đề
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo với gradient và shadow đẹp hơn
        Container(
          width: 180,
          height: 180,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _buildLogoContent(),
        ),

        const SizedBox(height: 24),

        // Tiêu đề thân thiện hơn
        Text(
          'Chào mừng trở lại!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
        ),

        const SizedBox(height: 8),

        // Mô tả
        Text(
          'Đăng nhập để tiếp tục học tiếng Nhật',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Form đăng nhập
  Widget _buildLoginForm() {
    return Column(
      children: [
        // Tên đăng nhập
        TextFormField(
          controller: _usernameController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
          enableInteractiveSelection: true,
          decoration: const InputDecoration(
            labelText: 'Tên đăng nhập',
            hintText: 'Nhập tên đăng nhập',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập tên đăng nhập';
            }
            if (value.trim().length < 3) {
              return 'Tên đăng nhập phải có ít nhất 3 ký tự';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Mật khẩu
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onFieldSubmitted: (_) => _handleLogin(),
          decoration: InputDecoration(
            labelText: 'Mật khẩu',
            hintText: 'Nhập mật khẩu',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập mật khẩu';
            }
            if (value.length < 6) {
              return 'Mật khẩu phải có ít nhất 6 ký tự';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Ghi nhớ đăng nhập và quên mật khẩu
  Widget _buildRememberAndForgot() {
    // Wrap thay Row: màn hẹp (điện thoại 320–360px, cỡ chữ lớn) không đủ chỗ
    // cho cả hai trên một dòng, Row sẽ tràn; Wrap đẩy "Quên mật khẩu?" xuống.
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Checkbox ghi nhớ
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (value) {
                setState(() {
                  _rememberMe = value ?? false;
                });
              },
            ),
            Text(
              'Ghi nhớ đăng nhập',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),

        // Quên mật khẩu
        TextButton(
          onPressed: () {
            context.push('/forgot-password');
          },
          child: const Text('Quên mật khẩu?'),
        ),
      ],
    );
  }

  /// Nút đăng nhập với gradient đẹp
  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: authProvider.isLoading
                ? null
                : const LinearGradient(
                    colors: [AppTheme.primaryColor, Color(0xFF1565C0)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            boxShadow: authProvider.isLoading
                ? []
                : [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: ElevatedButton(
            onPressed: authProvider.isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: authProvider.isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Đăng Nhập',
                    style: TextStyle(
                      fontSize: AppTypography.subtitle,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        );
      },
    );
  }

  /// Đường phân cách "Hoặc"
  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Hoặc',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  /// Nút đăng ký với border đẹp
  Widget _buildRegisterButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor,
          width: 2,
        ),
      ),
      child: OutlinedButton(
        onPressed: () {
          context.push('/register');
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Tạo tài khoản mới',
          style: TextStyle(
            fontSize: AppTypography.subtitle,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  /// Xây dựng nội dung logo (ảnh hoặc icon)
  Widget _buildLogoContent() {
    // Thử load ảnh từ assets, nếu không có thì dùng icon
    return FutureBuilder<bool>(
      future: _checkImageExists('assets/images/logo.png'),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == true) {
          // Có ảnh logo -> hiển thị ảnh
          return ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Nếu load ảnh lỗi, fallback về icon
                return _buildDefaultIcon();
              },
            ),
          );
        } else {
          // Không có ảnh hoặc đang load -> dùng icon mặc định
          return _buildDefaultIcon();
        }
      },
    );
  }

  /// Icon mặc định khi không có ảnh
  Widget _buildDefaultIcon() {
    return const Icon(
      Icons.translate, // Icon dịch thuật - liên quan đến học ngôn ngữ
      size: 80,
      color: AppTheme.primaryColor,
    );
  }

  /// Kiểm tra xem file ảnh có tồn tại không
  Future<bool> _checkImageExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }
}
