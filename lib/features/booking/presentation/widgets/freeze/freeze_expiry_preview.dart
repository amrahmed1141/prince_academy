import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/booking/data/models/booking_freeze_model.dart';

class FreezeExpiryPreview extends StatelessWidget {
  const FreezeExpiryPreview({
    super.key,
    required this.frozenCount,
    required this.newExpiry,
  });

  final int frozenCount;
  final DateTime? newExpiry;

  @override
  Widget build(BuildContext context) {
    final hasPreview = frozenCount > 0 && newExpiry != null;
    final text = hasPreview
        ? 'You froze $frozenCount session${frozenCount == 1 ? '' : 's'} → new expiry date will be ${formatFreezeDisplayDate(newExpiry!)}'
        : 'Select sessions to preview the new expiry date';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EColorConstants.authCardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Iconsax.calendar_1,
            size: 20,
            color: hasPreview
                ? EColorConstants.primaryColor
                : EColorConstants.authPlaceholderGray,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: hasPreview ? FontWeight.w600 : FontWeight.w400,
                color: hasPreview
                    ? EColorConstants.authTextDarkBrown
                    : EColorConstants.authPlaceholderGray,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
