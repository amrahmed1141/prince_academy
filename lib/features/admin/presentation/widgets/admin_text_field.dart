import 'package:flutter/material.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_form_styles.dart';

class AdminTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final VoidCallback? onSuffixTap;
  final Widget? suffix;
  final bool readOnly;
  final ValueChanged<String>? onChanged;

  const AdminTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.focusNode,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onSuffixTap,
    this.suffix,
    this.readOnly = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFormStyles.fieldLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          focusNode: focusNode,
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          readOnly: readOnly,
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A2A0D),
            fontFamily: 'Poppins',
          ),
          decoration: AdminFormStyles.fieldDecoration(hintText: hint).copyWith(
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}
