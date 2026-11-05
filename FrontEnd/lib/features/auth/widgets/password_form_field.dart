import 'package:flutter/material.dart';

/// Ô nhập mật khẩu có nút ẩn hiện. Trạng thái ẩn hiện thuộc về chính ô này nên
/// màn hình không phải giữ một cờ cho mỗi ô.
class PasswordFormField extends StatefulWidget {
  const PasswordFormField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    required this.validator,
    this.hintText,
    this.helperText,
    this.border = const OutlineInputBorder(),
  });

  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? helperText;
  final IconData prefixIcon;
  final FormFieldValidator<String> validator;
  final InputBorder border;

  @override
  State<PasswordFormField> createState() => _PasswordFormFieldState();
}

class _PasswordFormFieldState extends State<PasswordFormField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        helperText: widget.helperText,
        prefixIcon: Icon(widget.prefixIcon),
        border: widget.border,
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: widget.validator,
    );
  }
}
