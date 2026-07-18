import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/data/models/session_conflict_info.dart';

class SessionConflictDialog extends StatelessWidget {
  final SessionConflictInfo conflict;

  const SessionConflictDialog({
    super.key,
    required this.conflict,
  });

  /// Returns `true` when the admin chooses to create anyway, `false` on cancel.
  static Future<bool> show(
    BuildContext context, {
    required SessionConflictInfo conflict,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SessionConflictDialog(conflict: conflict),
    ).then((value) => value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.warning_2,
              size: 20,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Schedule Conflict',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: EColorConstants.authTextDarkBrown,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
      content: Text(
        conflict.message,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.45,
          color: EColorConstants.authTextDarkBrown,
          fontFamily: 'Poppins',
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: EColorConstants.authTextDarkBrown,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EColorConstants.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Create Anyway',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
