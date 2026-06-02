import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';

class SessionCard extends StatelessWidget {
  final String title;
  final String type;
  final String coach;
  final String date;
  final String duration;
  final String spots;

  const SessionCard({
    super.key,
    required this.title,
    required this.type,
    required this.coach,
    required this.date,
    required this.duration,
    required this.spots,
  });

  @override
  Widget build(BuildContext context) {
    Color typeColor;
    switch (type.toLowerCase()) {
      case 'striking':
        typeColor = Colors.redAccent;
        break;
      case 'grappling':
        typeColor = Colors.teal;
        break;
      case 'conditioning':
        typeColor = Colors.orange;
        break;
      case 'sparring':
        typeColor = Colors.deepPurple;
        break;
      default:
        typeColor = EColorConstants.primaryColor;
    }

    return Container(
      decoration: BoxDecoration(
        color: EColorConstants.authCardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EColorConstants.authFieldBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: EColorConstants.authTextDarkBrown,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: typeColor,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Iconsax.user, size: 14, color: EColorConstants.authPlaceholderGray),
              const SizedBox(width: 6),
              Text(
                coach,
                style: const TextStyle(
                  fontSize: 12,
                  color: EColorConstants.authTextDarkBrown,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Iconsax.calendar, size: 14, color: EColorConstants.authPlaceholderGray),
              const SizedBox(width: 6),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 12,
                  color: EColorConstants.authTextDarkBrown,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Iconsax.clock, size: 14, color: EColorConstants.authPlaceholderGray),
              const SizedBox(width: 6),
              Text(
                duration,
                style: const TextStyle(
                  fontSize: 12,
                  color: EColorConstants.authTextDarkBrown,
                  fontFamily: 'Poppins',
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: EColorConstants.authFieldBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: EColorConstants.authFieldBorder),
                ),
                child: Text(
                  spots,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: EColorConstants.authTextDarkBrown,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
