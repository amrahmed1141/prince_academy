import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/helpers/helper_function.dart';
import 'package:prince_academy/core/theme/app_gradients.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_event.dart';
import 'package:prince_academy/core/services/user_qr_service.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_history_page.dart';
import 'package:prince_academy/features/profile/presentation/widgets/member_qr_display.dart';
import 'package:prince_academy/features/profile/presentation/pages/profile/my_qr_screen.dart';

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
  // Demo values (replace later from Auth/User profile)
  final String userName = 'Amr Ahmed';
  final String phone = '+20 10 0000 0000';
  final String email = 'amrahmed5222@gmail.com';
  final bool isAdmin = false;

  // Demo stats (replace later from enrollments/sessions repo)
  final int activeEnrollments = 1;
  final int completedEnrollments = 3;
  final int remainingSessions = 7;

  bool notificationsEnabled = true;
  bool darkModeEnabled = false;
  late final UserQrService _qrService;

  @override
  void initState() {
    super.initState();
    _qrService = sl<UserQrService>();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _qrService.refresh();
      });
    }
  }

  void _openMyQrScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyQrScreen()),
    ).then((_) => _qrService.refresh());
  }

  @override
  Widget build(BuildContext context) {
    final dark = EHelperFunction.isDarkMode(context);

    return Container(
      decoration: dark ? null : AppGradients.screenDecoration(),
      color: dark ? Colors.black : null,
      child: Scaffold(
        backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Iconsax.setting_2),
                onPressed: () {
                  // later: open settings page (optional)
                },
              ),
            ],
          ),
          body: ListenableBuilder(
            listenable: _qrService,
            builder: (context, _) {
              return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            children: [
              _ProfileHeaderCard(
                name: userName,
                phone: phone,
                email: email,
                badgeText: isAdmin ? 'Admin' : 'Member',
              ),
              const SizedBox(height: 12),
              _StatsRow(
                activeEnrollments: activeEnrollments,
                completedEnrollments: completedEnrollments,
                remainingSessions: remainingSessions,
              ),
              if (_qrService.hasQrCode) ...[
                const SizedBox(height: 16),
                _QrPreviewCard(
                  qrCode: _qrService.qrCode!,
                  onTap: _openMyQrScreen,
                ),
              ],
              const SizedBox(height: 16),
              _SectionTitle(title: 'My Account'),
              const SizedBox(height: 10),
              _Card(
                child: Column(
                  children: [
                    _ActionTile(
                      icon: Iconsax.edit_2,
                      title: 'Edit Profile',
                      subtitle: 'Update your name and contact info',
                      onTap: () {},
                    ),
                    _DividerLine(),
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
                    _DividerLine(),
                    _ActionTile(
                      icon: Iconsax.calendar_1,
                      title: 'My Sessions',
                      subtitle: 'Upcoming & completed sessions',
                      onTap: () {
                        // Navigator.push to Sessions screen
                      },
                    ),
                    _DividerLine(),
                    _ActionTile(
                      icon: Icons.qr_code_2,
                      title: 'My QR Code',
                      subtitle: _qrService.isLoading
                          ? 'Checking QR status...'
                          : _qrService.hasQrCode
                              ? 'Show your member QR at the front desk'
                              : 'Book a coach to get your QR code',
                      onTap: _qrService.hasQrCode ? _openMyQrScreen : null,
                      titleColor: !_qrService.hasQrCode && !_qrService.isLoading
                          ? Colors.grey.shade500
                          : null,
                      iconColor: !_qrService.hasQrCode && !_qrService.isLoading
                          ? Colors.grey.shade500
                          : null,
                    ),
                    _DividerLine(),
                    _ActionTile(
                      icon: Iconsax.wallet_2,
                      title: 'Payments',
                      subtitle: 'Transactions & receipts',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionTitle(title: 'Preferences'),
              const SizedBox(height: 10),
              _Card(
                child: Column(
                  children: [
                    _SwitchTile(
                      icon: Iconsax.notification,
                      title: 'Notifications',
                      subtitle: 'Booking updates & reminders',
                      value: notificationsEnabled,
                      onChanged: (v) =>
                          setState(() => notificationsEnabled = v),
                    ),
                    _DividerLine(),
                    _SwitchTile(
                      icon: Iconsax.moon,
                      title: 'Dark Mode',
                      subtitle: 'Comfortable at night',
                      value: darkModeEnabled,
                      onChanged: (v) => setState(() => darkModeEnabled = v),
                    ),
                    _DividerLine(),
                    _ActionTile(
                      icon: Iconsax.global,
                      title: 'Language',
                      subtitle: 'English',
                      onTap: () {
                        // later: language picker bottom sheet
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionTitle(title: 'Support'),
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
                    _DividerLine(),
                    _ActionTile(
                      icon: Iconsax.info_circle,
                      title: 'Help Center',
                      subtitle: 'FAQs and guidance',
                      onTap: () {},
                    ),
                    _DividerLine(),
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
                    // later: AuthBloc -> SignOut
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<AuthBloc>().add(AuthSignOut());
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

class _QrPreviewCard extends StatelessWidget {
  const _QrPreviewCard({
    required this.qrCode,
    required this.onTap,
  });

  final String qrCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 8),
              color: Colors.black.withOpacity(0.04),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: EColorConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.qr_code_2,
                    color: EColorConstants.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your Member QR Code',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const Icon(Iconsax.arrow_right_3, size: 18, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 16),
            MemberQrDisplay(
              qrCode: qrCode,
              size: 160,
              hint: 'Tap to view subscriptions',
            ),
          ],
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
  });

  final String name;
  final String phone;
  final String email;
  final String badgeText;

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
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: EColorConstants.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Iconsax.user,
              color: EColorConstants.primaryColor,
              size: 26,
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.activeEnrollments,
    required this.completedEnrollments,
    required this.remainingSessions,
  });

  final int activeEnrollments;
  final int completedEnrollments;
  final int remainingSessions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _StatCard(label: 'Active', value: '$activeEnrollments')),
        const SizedBox(width: 10),
        Expanded(
            child:
                _StatCard(label: 'Completed', value: '$completedEnrollments')),
        const SizedBox(width: 10),
        Expanded(
            child: _StatCard(label: 'Remaining', value: '$remainingSessions')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
          ),
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
