import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';

class CoachHeaderCard extends StatelessWidget {
  const CoachHeaderCard({super.key, required this.info});

  final MMABookingModel info;

  Widget _buildCoachImage(String path) {
    return CoachAvatar(
      coachName: info.coachName,
      photoUrl: path.isEmpty ? null : path,
      size: 70,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EColorConstants.primaryColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _buildCoachImage(info.coachImage),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      info.coachName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Iconsax.verify5,
                        size: 18, color: EColorConstants.primaryColor),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  info.branchName?.trim().isNotEmpty == true
                      ? info.branchName!
                      : (info.specialty ?? 'Private Coach'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}