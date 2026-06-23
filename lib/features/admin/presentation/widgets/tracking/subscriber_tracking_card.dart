import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/subscription_formatters.dart';
import 'package:prince_academy/features/admin/data/models/subscriber_tracking_model.dart';

class SubscriberTrackingCard extends StatelessWidget {
  final SubscriberTrackingModel subscriber;
  final VoidCallback onTap;

  const SubscriberTrackingCard({
    super.key,
    required this.subscriber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EColorConstants.authCardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: EColorConstants.authFieldBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: EColorConstants.primaryColor.withOpacity(0.15),
                  child: Text(
                    subscriber.initials,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: EColorConstants.primaryColor,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscriber.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: EColorConstants.authTextDarkBrown,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        '${subscriber.bookingCount} booking${subscriber.bookingCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: EColorConstants.authPlaceholderGray,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Iconsax.arrow_right_3,
                  size: 16,
                  color: EColorConstants.authPlaceholderGray,
                ),
              ],
            ),
            if (subscriber.phone != null && subscriber.phone!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Iconsax.call,
                    size: 14,
                    color: EColorConstants.authPlaceholderGray,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    subscriber.phone!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: EColorConstants.authTextDarkBrown,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                _StatusChip(
                  color: const Color(0xFF2E7D32),
                  label: '${subscriber.activeCount} active',
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  color: const Color(0xFFD32F2F),
                  label: '${subscriber.expiredCount} expired',
                ),
              ],
            ),
            if (subscriber.latestBookingDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Latest: ${SubscriptionFormatters.formatDate(subscriber.latestBookingDate)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: EColorConstants.authPlaceholderGray,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusChip({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}
