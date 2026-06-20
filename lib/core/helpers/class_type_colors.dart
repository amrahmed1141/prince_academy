import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';

class ClassTypeColors {
  static Color background(String type) {
    switch (type.trim()) {
      case 'Striking':
        return const Color(0xFFFFE8E8);
      case 'Grappling':
        return const Color(0xFFE8F5E9);
      case 'BJJ':
        return const Color(0xFFE3F2FD);
      case 'MMA':
        return const Color(0xFFF3E5F5);
      case 'Boxing':
        return const Color(0xFFFFF3E0);
      case 'Wrestling':
        return const Color(0xFFFCE4EC);
      case 'Kickboxing':
        return const Color(0xFFE8EAF6);
      case 'Fitness':
        return const Color(0xFFE0F7FA);
      default:
        return EColorConstants.primaryColor.withOpacity(0.08);
    }
  }

  static Color foreground(String type) {
    switch (type.trim()) {
      case 'Striking':
        return const Color(0xFFD32F2F);
      case 'Grappling':
        return const Color(0xFF2E7D32);
      case 'BJJ':
        return const Color(0xFF1565C0);
      case 'MMA':
        return const Color(0xFF6A1B9A);
      case 'Boxing':
        return const Color(0xFFE65100);
      case 'Wrestling':
        return const Color(0xFFC62828);
      case 'Kickboxing':
        return const Color(0xFF283593);
      case 'Fitness':
        return const Color(0xFF006064);
      default:
        return EColorConstants.primaryColor;
    }
  }
}
