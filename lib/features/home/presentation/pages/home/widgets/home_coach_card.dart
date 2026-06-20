import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_details/booking.dart';
import 'package:prince_academy/features/home/data/models/coaches_model.dart';
import 'package:prince_academy/features/home/presentation/pages/home/coach_profile.dart';

class HomeCoachCard extends StatelessWidget {
  final CoachModel coach;
  final String? classType;
  final bool dark;

  const HomeCoachCard({
    super.key,
    required this.coach,
    this.classType,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final displayClassType = (classType != null && classType!.isNotEmpty)
        ? classType!
        : '—';

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CoachProfilePage(coachId: coach.id),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: dark ? Colors.grey[800] : Colors.white,
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
                _CoachCircleAvatar(
                  name: coach.name,
                  photoUrl: coach.photoUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
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
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: dark ? Colors.white : Colors.black,
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
                        dark: dark,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {},
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingPage(
                                    bookingInfo: MMABookingModel(
                                      coachId: coach.id,
                                      coachName: coach.name,
                                      coachImage: coach.photoUrl ?? '',
                                      specialty: coach.specialty,
                                      coachWhatsapp: '+1234567890',
                                    ),
                                  ),
                                ),
                              );
                            },
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
                              'Booking Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                              ),
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
      ),
    );
  }
}

class _ClassTypeChip extends StatelessWidget {
  final String label;
  final bool dark;

  const _ClassTypeChip({
    required this.label,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: dark
            ? EColorConstants.primaryColor.withOpacity(0.18)
            : EColorConstants.authFieldBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark
              ? EColorConstants.primaryColor.withOpacity(0.35)
              : EColorConstants.authFieldBorder,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: dark
              ? EColorConstants.authLightPrimary
              : EColorConstants.primaryColor,
          fontFamily: 'Poppins',
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _CoachCircleAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;

  const _CoachCircleAvatar({
    required this.name,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    const radius = 38.0;
    final initial =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        backgroundImage: _imageProvider(photoUrl!),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.black54,
          fontWeight: FontWeight.w700,
          fontSize: 24,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  ImageProvider _imageProvider(String path) {
    if (path.startsWith('assets/')) return AssetImage(path);
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    return FileImage(File(path));
  }
}
