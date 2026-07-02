import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';

class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: EColorConstants.authFieldBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EColorConstants.authFieldBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: EColorConstants.authPlaceholderGray),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: EColorConstants.authPlaceholderGray,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
