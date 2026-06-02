import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';

class CoachCard extends StatelessWidget {
  final String name;
  final String specialty;
  final String experience;
  final String sessionCount;
  final String? rating;

  const CoachCard({
    super.key,
    required this.name,
    required this.specialty,
    required this.experience,
    required this.sessionCount,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .join()
        .substring(0, 1)
        .toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: EColorConstants.authCardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EColorConstants.authFieldBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: EColorConstants.authSoftGold,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials.length >= 1 ? initials : name.isNotEmpty ? name[0] : '?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: EColorConstants.authCardWhite,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: EColorConstants.authTextDarkBrown,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  specialty,
                  style: TextStyle(
                    fontSize: 12,
                    color: EColorConstants.primaryColor,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '$experience · $sessionCount sessions',
                      style: const TextStyle(
                        fontSize: 11,
                        color: EColorConstants.authPlaceholderGray,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (rating != null && rating!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: EColorConstants.authFieldBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: EColorConstants.authFieldBorder),
              ),
              child: Text(
                rating!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: EColorConstants.primaryColor,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
