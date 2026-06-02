import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';

class AdminHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onAvatarTap;

  const AdminHeader({
    super.key,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: EColorConstants.authFieldBackground,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              // Admin Avatar
              GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: EColorConstants.primaryColor, width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    child: Icon(Iconsax.user, size: 24, color: EColorConstants.primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Admin Label
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Admin',
                    style: TextStyle(
                      color: EColorConstants.authTextDarkBrown,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    'Management Portal',
                    style: TextStyle(
                      color: EColorConstants.authPlaceholderGray,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // App Logo
              Image.asset(
                'assets/icons/logo.png',
                height: 48,
                width: 48,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: EColorConstants.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.flash_1, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
