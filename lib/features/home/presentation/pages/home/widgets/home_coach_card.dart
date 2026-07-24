import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/booking/presentation/helpers/book_now_navigation.dart';
import 'package:prince_academy/features/home/data/models/coaches_model.dart';
import 'package:prince_academy/features/home/presentation/pages/home/coach_profile.dart';

class HomeCoachCard extends StatelessWidget {
  final CoachModel coach;
  final String? classType;

  const HomeCoachCard({
    super.key,
    required this.coach,
    this.classType,
  });

  @override
  Widget build(BuildContext context) {
    final displayClassType = (classType != null && classType!.isNotEmpty)
        ? classType!
        : '—';

    void openCoachProfile() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CoachProfilePage(coachId: coach.id),
        ),
      );
    }

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: openCoachProfile,
                child: CoachAvatar(
                  coachName: coach.name,
                  photoUrl: coach.photoUrl,
                  size: 76,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: openCoachProfile,
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  coach.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Iconsax.verify5,
                                size: 18,
                                color: EColorConstants.primaryColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _ClassTypeChip(
                            label: displayClassType,
                          ),
                          const SizedBox(height: 6),
                          _MemberCountRow(
                            count: coach.memberCount,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () => BookNowNavigation.openBookingForCoach(
                          context: context,
                          coachId: coach.id,
                          coachName: coach.name,
                          coachImage: coach.photoUrl ?? '',
                          specialty: coach.specialty,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EColorConstants.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                          shadowColor:
                              EColorConstants.primaryColor.withOpacity(0.25),
                        ),
                        icon: const Icon(
                          Iconsax.calendar,
                          size: 15,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Book Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberCountRow extends StatelessWidget {
  final int count;

  const _MemberCountRow({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    // MODIFIED: members label with singular/plural
    final label = count == 1 ? '1 member' : '$count members';

    return Row(
      children: [
        Icon(
          Iconsax.user,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

class _ClassTypeChip extends StatelessWidget {
  final String label;

  const _ClassTypeChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: EColorConstants.authFieldBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: EColorConstants.authFieldBorder,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: EColorConstants.primaryColor,
          fontFamily: 'Poppins',
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
