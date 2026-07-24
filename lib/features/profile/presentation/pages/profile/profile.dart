import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/theme/app_gradients.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/auth/data/models/app_user.dart';
import 'package:prince_academy/features/auth/domain/repositories/auth_repo.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_event.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_state.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_history_page.dart';
import 'package:prince_academy/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:prince_academy/features/profile/presentation/pages/profile/edit_profile_page.dart';
import 'package:prince_academy/features/profile/presentation/pages/profile/payments_page.dart';
import 'package:prince_academy/features/sessions/presentation/pages/sessions_page.dart';

class ProfilePage extends StatefulWidget {
  final bool isActive;

  const ProfilePage({
    super.key,
    this.isActive = false,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool notificationsEnabled = true;
  bool _isUploadingAvatar = false;

  Future<void> _openEditProfile(UserModel user) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditProfilePage(user: user)),
    );
  }

  Future<void> _pickAndUploadAvatar(UserModel user) async {
    if (_isUploadingAvatar) return;

    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 88,
      );
      if (image == null || !mounted) return;

      setState(() => _isUploadingAvatar = true);

      final repo = sl<AuthRepo>();
      final avatarUrl = await repo.uploadAvatar(File(image.path));
      await repo.updateProfile(
        fullName: user.fullName ?? 'Member',
        phone: user.phone ?? '',
        avatarUrl: avatarUrl,
      );

      if (!mounted) return;
      context.read<AuthBloc>().add(const AuthRefreshProfile());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update photo: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppGradients.screenDecoration(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Profile'),
          actions: [
            const NotificationBellButton(
              variant: NotificationBellVariant.plain,
              padded: false,
            ),
          ],
        ),
        body: BlocSelector<AuthBloc, AuthState, UserModel?>(
          selector: (state) => state is AuthAuthed ? state.user : null,
          builder: (context, user) {
            final name = user?.fullName?.trim().isNotEmpty == true
                ? user!.fullName!.trim()
                : 'Member';
            final phone = user?.phone?.trim().isNotEmpty == true
                ? user!.phone!.trim()
                : 'Not set';
            final email = user?.email?.trim().isNotEmpty == true
                ? user!.email!.trim()
                : 'Not set';
            final isAdmin = user?.role == 'admin';

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
              children: [
                _ProfileHeaderCard(
                  name: name,
                  phone: phone,
                  email: email,
                  badgeText: isAdmin ? 'Admin' : 'Member',
                  photoUrl: user?.avatarUrl,
                  isUploadingAvatar: _isUploadingAvatar,
                  onAvatarTap: user == null
                      ? null
                      : () => _pickAndUploadAvatar(user),
                ),
                const SizedBox(height: 16),
                const _SectionTitle(title: 'My Account'),
                const SizedBox(height: 10),
                _Card(
                  child: Column(
                    children: [
                      _ActionTile(
                        icon: Iconsax.edit_2,
                        title: 'Edit Profile',
                        subtitle: 'Update your name, photo and contact info',
                        onTap:
                            user == null ? null : () => _openEditProfile(user),
                      ),
                      const _DividerLine(),
                      _ActionTile(
                        icon: Iconsax.calendar_1,
                        title: 'My Sessions',
                        subtitle: 'Upcoming & completed sessions',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SessionsPage(
                                showBackButton: true,
                                usePlainBackground: true,
                              ),
                            ),
                          );
                        },
                      ),
                      const _DividerLine(),
                      _ActionTile(
                        icon: Iconsax.ticket,
                        title: 'Booking History',
                        subtitle: 'All your enrollments & packages',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BookingHistoryPage(),
                            ),
                          );
                        },
                      ),
                      const _DividerLine(),
                      _ActionTile(
                        icon: Iconsax.wallet_2,
                        title: 'Payments',
                        subtitle: 'Transactions & receipts',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PaymentsPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const _SectionTitle(title: 'Preferences'),
                const SizedBox(height: 10),
                _Card(
                  child: _SwitchTile(
                    icon: Iconsax.notification,
                    title: 'Notifications',
                    subtitle: 'Booking updates & reminders',
                    value: notificationsEnabled,
                    onChanged: (v) =>
                        setState(() => notificationsEnabled = v),
                  ),
                ),
                const SizedBox(height: 16),
                const _SectionTitle(title: 'Support'),
                const SizedBox(height: 10),
                _Card(
                  child: Column(
                    children: [
                      _ActionTile(
                        icon: Iconsax.message,
                        title: 'WhatsApp Support',
                        subtitle: 'Chat with the academy',
                        onTap: () {},
                      ),
                      const _DividerLine(),
                      _ActionTile(
                        icon: Iconsax.info_circle,
                        title: 'Help Center',
                        subtitle: 'FAQs and guidance',
                        onTap: () {},
                      ),
                      const _DividerLine(),
                      _ActionTile(
                        icon: Iconsax.shield_tick,
                        title: 'Privacy Policy',
                        subtitle: 'Read our terms',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Card(
                  child: _ActionTile(
                    icon: Iconsax.logout_1,
                    title: 'Logout',
                    subtitle: 'Sign out of your account',
                    titleColor: Colors.red,
                    iconColor: Colors.red,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Logout'),
                          content:
                              const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                context.read<AuthBloc>().add(const AuthSignOut());
                                Navigator.pop(context);
                              },
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.name,
    required this.phone,
    required this.email,
    required this.badgeText,
    this.photoUrl,
    this.onAvatarTap,
    this.isUploadingAvatar = false,
  });

  final String name;
  final String phone;
  final String email;
  final String badgeText;
  final String? photoUrl;
  final VoidCallback? onAvatarTap;
  final bool isUploadingAvatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.04),
          )
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CoachAvatar(
                  coachName: name,
                  photoUrl: photoUrl,
                  size: 62,
                ),
                if (isUploadingAvatar)
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: EColorConstants.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Iconsax.camera,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _Badge(text: badgeText),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Iconsax.call, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        phone,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w700,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Iconsax.sms, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.04),
          )
        ],
      ),
      child: child,
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return ListTile(
      onTap: onTap,
      enabled: enabled,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: (iconColor ?? EColorConstants.primaryColor).withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor ?? EColorConstants.primaryColor,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
      ),
      trailing: const Icon(Iconsax.arrow_right_3, size: 18, color: Colors.grey),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      secondary: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: EColorConstants.primaryColor.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 20, color: EColorConstants.primaryColor),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: Colors.grey.shade200);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: EColorConstants.primaryColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(99),
        border:
            Border.all(color: EColorConstants.primaryColor.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: EColorConstants.primaryColor,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}
