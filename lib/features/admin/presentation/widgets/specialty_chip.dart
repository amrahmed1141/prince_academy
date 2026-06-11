import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';

/// Compact specialty label that never overflows its parent width.
class SpecialtyChip extends StatelessWidget {
  final String specialty;
  final double fontSize;

  const SpecialtyChip({
    super.key,
    required this.specialty,
    this.fontSize = 11,
  });

  static String displayLabel(String specialty) {
    switch (specialty) {
      case 'Strength & Conditioning':
        return 'S & C';
      default:
        return specialty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: double.infinity),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: EColorConstants.authFieldBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: EColorConstants.authFieldBorder),
        ),
        child: Text(
          displayLabel(specialty),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: EColorConstants.primaryColor,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}
