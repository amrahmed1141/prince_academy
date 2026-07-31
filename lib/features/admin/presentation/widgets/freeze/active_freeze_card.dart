import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/booking/data/models/booking_freeze_model.dart';

class ActiveFreezeCard extends StatelessWidget {
  const ActiveFreezeCard({
    super.key,
    required this.freeze,
  });

  final ActiveBookingFreeze freeze;

  @override
  Widget build(BuildContext context) {
    final dates = freeze.sessionDates
        .map(formatFreezeDisplayDate)
        .join(' · ');
    final original = freeze.originalSubscriptionEnd == null
        ? '—'
        : formatFreezeDisplayDate(freeze.originalSubscriptionEnd!);
    final updated = freeze.newSubscriptionEnd == null
        ? '—'
        : formatFreezeDisplayDate(freeze.newSubscriptionEnd!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EColorConstants.authCardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CoachAvatar(
                coachName: freeze.fullName,
                photoUrl: freeze.avatarUrl,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      freeze.fullName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: EColorConstants.authTextDarkBrown,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      '${freeze.coachName} · ${freeze.sessionCount} frozen',
                      style: const TextStyle(
                        fontSize: 12,
                        color: EColorConstants.authPlaceholderGray,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Iconsax.pause_circle,
                size: 18,
                color: EColorConstants.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            dates.isEmpty ? 'No dates' : dates,
            style: const TextStyle(
              fontSize: 12,
              color: EColorConstants.authTextDarkBrown,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Expiry: $original → $updated',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: EColorConstants.primaryColor,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
