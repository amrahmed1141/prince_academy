import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_dismissible_card.dart';
import 'package:prince_academy/features/admin/presentation/widgets/delete_confirmation_sheet.dart';
import 'package:prince_academy/features/admin/presentation/widgets/specialty_chip.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_name_with_verify.dart';

class CoachListCard extends StatelessWidget {
  final String coachId;
  final String name;
  final String specialty;
  final int sessionCount;
  final String? imagePath;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const CoachListCard({
    super.key,
    required this.coachId,
    required this.name,
    required this.specialty,
    required this.sessionCount,
    this.imagePath,
    required this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return AdminDismissibleCard(
      dismissKey: ValueKey('coach_$coachId'),
      confirmTitle: 'Delete Coach?',
      confirmSubtitle:
          'This will permanently delete $name and all their sessions.',
      onDismissConfirmed: onDelete,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: EColorConstants.authCardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: EColorConstants.primaryColor.withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
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
            PopupMenuButton<String>(
              icon: const Icon(
                Iconsax.more,
                size: 18,
                color: EColorConstants.authPlaceholderGray,
              ),
              onSelected: (value) async {
                if (value == 'edit') {
                  onEdit?.call();
                } else if (value == 'delete') {
                  final confirmed = await DeleteConfirmationSheet.show(
                    context: context,
                    title: 'Delete Coach?',
                    subtitle:
                        'This will permanently delete $name and all their sessions.',
                  );
                  if (confirmed) onDelete();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit Coach', style: TextStyle(fontFamily: 'Poppins')),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(fontFamily: 'Poppins')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Backward-compatible alias.
typedef CoachCard = CoachListCard;
