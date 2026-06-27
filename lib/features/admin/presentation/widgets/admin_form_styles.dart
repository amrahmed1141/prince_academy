import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';

/// Shared label + field styling for admin create/edit forms.
abstract final class AdminFormStyles {
  static const screenBackground = Color(0xFFF7F4EF);
  static const fieldFill = Color(0xFFFFFFFF);
  static const sessionPanelFill = Color(0xFFF3EDE4);
  static const statChipFill = Color(0xFFF0EBF8);

  static const fieldLabelStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: Color(0xFF9E9E9E),
    fontFamily: 'Poppins',
  );

  static const sectionTitleStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: EColorConstants.authTextDarkBrown,
    fontFamily: 'Poppins',
  );

  static Widget fieldLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: fieldLabelStyle,
    );
  }

  static Widget sectionTitle(String text) {
    return Text(text, style: sectionTitleStyle);
  }

  static InputDecoration fieldDecoration({
    IconData? prefixIcon,
    String? hintText,
    String? errorText,
    Color? iconColor,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 13,
        color: EColorConstants.authPlaceholderGray,
        fontFamily: 'Poppins',
      ),
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              size: 18,
              color: iconColor ?? EColorConstants.primaryColor,
            )
          : null,
      filled: true,
      fillColor: fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300.withOpacity(0.55)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300.withOpacity(0.55)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: EColorConstants.primaryColor,
          width: 1.2,
        ),
      ),
      errorText: errorText,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  static BoxDecoration formCardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: Colors.grey.shade200.withOpacity(0.8)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration sessionDetailsPanelDecoration = BoxDecoration(
    color: sessionPanelFill,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFE8DDD0)),
  );
}
