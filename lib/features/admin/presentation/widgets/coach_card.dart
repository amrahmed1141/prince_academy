import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/presentation/widgets/specialty_chip.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_name_with_verify.dart';

class CoachListCard extends StatelessWidget {
  final String name;
  final String specialty;
  final int sessionCount;
  final String? imagePath;
  final VoidCallback? onMenuTap;

  const CoachListCard({
    super.key,
    required this.name,
    required this.specialty,
    required this.sessionCount,
    this.imagePath,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: EColorConstants.authCardWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: EColorConstants.authFieldBorder.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CoachAvatar(
            name: name,
            photoUrl: imagePath,
            radius: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CoachNameWithVerify(name: name),
                const SizedBox(height: 6),
                SpecialtyChip(specialty: specialty),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Iconsax.calendar_1,
                      size: 13,
                      color: EColorConstants.authPlaceholderGray,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$sessionCount Session${sessionCount == 1 ? '' : 's'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: EColorConstants.authPlaceholderGray,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onMenuTap != null)
            GestureDetector(
              onTap: onMenuTap,
              child: Container(
                padding: const EdgeInsets.all(6),
                child: const Icon(
                  Iconsax.more,
                  size: 18,
                  color: EColorConstants.authPlaceholderGray,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Backward-compatible alias.
typedef CoachCard = CoachListCard;
