import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/notifications/presentation/widgets/notification_bell_button.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.adminName,
    this.pendingCount = 0,
    this.onAvatarTap,
  });

  final String adminName;
  final int pendingCount;
  final VoidCallback? onAvatarTap;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEE d MMM').format(DateTime.now());
    final firstName = adminName.trim().isEmpty
        ? 'Admin'
        : adminName.trim().split(RegExp(r'\s+')).first;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_greeting, $firstName',
                    style: const TextStyle(
                      color: EColorConstants.authTextDarkBrown,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      color: EColorConstants.authPlaceholderGray,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            const NotificationBellButton(
              variant: NotificationBellVariant.admin,
              padded: false,
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onAvatarTap,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: EColorConstants.authFieldBorder,
                        width: 2,
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Iconsax.user,
                        size: 22,
                        color: EColorConstants.primaryColor,
                      ),
                    ),
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE65100),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          pendingCount > 99 ? '99+' : '$pendingCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
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
    );
  }
}
