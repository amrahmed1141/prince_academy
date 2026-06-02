import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColorConstants.authFieldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Iconsax.arrow_left_2, color: EColorConstants.authTextDarkBrown),
        ),
        title: const Text(
          'Admin Profile',
          style: TextStyle(
            color: EColorConstants.authTextDarkBrown,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar Section
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: EColorConstants.primaryColor, width: 3),
                    ),
                    child: const CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      child: Icon(Iconsax.user, size: 64, color: EColorConstants.primaryColor),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: EColorConstants.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Iconsax.edit, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Main Admin',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: EColorConstants.authTextDarkBrown,
                fontFamily: 'Poppins',
              ),
            ),
            const Text(
              'Prince MMA Academy',
              style: TextStyle(
                fontSize: 14,
                color: EColorConstants.authPlaceholderGray,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 32),

            // Profile Info Cards
            _ProfileInfoTile(
              icon: Iconsax.sms,
              label: 'Email Address',
              value: 'admin@princemma.com',
            ),
            const SizedBox(height: 16),
            
            // Statistics Section
            const Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Iconsax.user_tag,
                    label: 'Coaches',
                    count: '12',
                    color: EColorConstants.primaryColor,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    icon: Iconsax.calendar_tick,
                    label: 'Sessions',
                    count: '48',
                    color: Color(0xFF4A2A0D),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Settings / Logout
            _ProfileInfoTile(
              icon: Iconsax.setting_2,
              label: 'App Settings',
              value: 'Manage notifications & security',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _ProfileInfoTile(
              icon: Iconsax.logout,
              label: 'Logout',
              value: 'Exit administration',
              isDestructive: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive 
                    ? Colors.red.withOpacity(0.1) 
                    : EColorConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : EColorConstants.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: EColorConstants.authPlaceholderGray,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDestructive ? Colors.red : EColorConstants.authTextDarkBrown,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Iconsax.arrow_right_3,
                size: 18,
                color: EColorConstants.authPlaceholderGray.withOpacity(0.5),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
          const SizedBox(height: 16),
          Text(
            count,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
