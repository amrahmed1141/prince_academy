import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';

/// Coach name with a plain verify icon directly beside it.
class CoachNameWithVerify extends StatelessWidget {
  final String name;
  final double fontSize;
  final bool showVerifyIcon;

  const CoachNameWithVerify({
    super.key,
    required this.name,
    this.fontSize = 15,
    this.showVerifyIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: EColorConstants.authTextDarkBrown,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        if (showVerifyIcon) ...[
          const SizedBox(width: 4),
          Icon(
            Iconsax.verify5,
            size: fontSize + 1,
            color: EColorConstants.primaryColor,
          ),
        ],
      ],
    );
  }
}
