import 'package:flutter/material.dart';

import '../theme/app_decorations.dart';

class PkInput extends StatelessWidget {
  const PkInput({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.suffixIcon,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      readOnly: readOnly,
      decoration: AppDecorations.inputDecoration(label: label, hint: hint)
          .copyWith(suffixIcon: suffixIcon),
    );
  }
}
