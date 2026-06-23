import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';

class TrackingSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const TrackingSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EColorConstants.authCardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EColorConstants.authFieldBorder),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'Poppins',
          color: EColorConstants.authTextDarkBrown,
        ),
        decoration: InputDecoration(
          hintText: 'Search by name or phone...',
          hintStyle: const TextStyle(
            fontSize: 13,
            color: EColorConstants.authPlaceholderGray,
            fontFamily: 'Poppins',
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: EColorConstants.authPlaceholderGray,
            size: 20,
          ),
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: EColorConstants.authPlaceholderGray,
                  ),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
