import 'package:flutter/material.dart';

/// Ô tên đăng nhập và mật khẩu.
class LoginFormFields extends StatelessWidget {
  const LoginFormFields({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.handleLogin,
    required this.togglePassword,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final Future<void> Function() handleLogin;
  final VoidCallback togglePassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tên đăng nhập
        TextFormField(
          controller: usernameController,
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
          controller: passwordController,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onFieldSubmitted: (_) => handleLogin(),
          decoration: InputDecoration(
            labelText: 'Mật khẩu',
            hintText: 'Nhập mật khẩu',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                togglePassword();
              },
            ),
          ),
          // Chỉ bắt buộc nhập, không kiểm độ dài: tài khoản cũ đặt mật khẩu
          // ngắn hơn quy định hiện tại vẫn phải đăng nhập được; đúng sai do server.
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập mật khẩu';
            }
            return null;
          },
        ),
      ],
    );
  }
}
