import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/l10n/app_strings.dart';
import 'package:prince_academy/core/l10n/locale_cubit.dart';
import 'package:prince_academy/core/widgets/directional_icon.dart';
import 'package:prince_academy/features/admin/presentation/pages/admin_edit_name_page.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/auth/data/models/app_user.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_event.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_state.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  bool _notificationsEnabled = true;

  Future<void> _confirmSignOut() async {
    final s = context.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(s.confirmLogout),
          content: Text(s.signOutConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(s.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(s.logout),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      context.read<AuthBloc>().add(const AuthSignOut());
    }
  }

  Future<void> _openEditName(UserModel user) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminEditNamePage(user: user)),
    );
  }

  Future<void> _pickLanguage() async {
    final s = context.s;
    final cubit = sl<LocaleCubit>();
    final selected = await showModalBottomSheet<Locale>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.chooseLanguage,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: EColorConstants.authTextDarkBrown,
                  ),
                ),
                const SizedBox(height: 16),
                _LanguageOption(
                  label: s.languageEnglish,
                  selected: !cubit.isArabic,
                  onTap: () => Navigator.pop(context, AppLocales.english),
                ),
                const SizedBox(height: 10),
                _LanguageOption(
                  label: s.languageArabic,
                  selected: cubit.isArabic,
                  onTap: () => Navigator.pop(context, AppLocales.arabic),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      await cubit.setLocale(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return Scaffold(
      backgroundColor: EColorConstants.authFieldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            DirectionalIcons.back(context),
            color: EColorConstants.authTextDarkBrown,
            textDirection: TextDirection.ltr,
          ),
        ),
        title: Text(
          s.adminProfile,
          style: const TextStyle(
            color: EColorConstants.authTextDarkBrown,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: BlocSelector<AuthBloc, AuthState, UserModel?>(
        selector: (state) => state is AuthAuthed ? state.user : null,
        builder: (context, user) {
          final name = user?.fullName?.trim().isNotEmpty == true
              ? user!.fullName!.trim()
              : s.admin;
          final email = user?.email?.trim().isNotEmpty == true
              ? user!.email!.trim()
              : s.notSet;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: EColorConstants.primaryColor,
                        width: 3,
                      ),
                    ),
                    child: CoachAvatar(
                      coachName: name,
                      photoUrl: user?.avatarUrl,
                      size: 120,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: EColorConstants.authTextDarkBrown,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  s.princeMmaAcademy,
                  style: const TextStyle(
                    fontSize: 14,
                    color: EColorConstants.authPlaceholderGray,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 32),
                _ProfileInfoTile(
                  icon: Iconsax.sms,
                  label: s.emailAddress,
                  value: email,
                ),
                const SizedBox(height: 12),
                _ProfileInfoTile(
                  icon: Iconsax.edit_2,
                  label: s.editProfile,
                  value: s.updateDisplayName,
                  onTap: user == null ? null : () => _openEditName(user),
                ),
                const SizedBox(height: 12),
                _NotificationToggleTile(
                  label: s.notifications,
                  subtitle: s.adminAlertsUpdates,
                  value: _notificationsEnabled,
                  onChanged: (v) => setState(() => _notificationsEnabled = v),
                ),
                const SizedBox(height: 12),
                _ProfileInfoTile(
                  icon: Iconsax.global,
                  label: s.language,
                  value: s.currentLanguageLabel,
                  onTap: _pickLanguage,
                ),
                const SizedBox(height: 12),
                _ProfileInfoTile(
                  icon: Iconsax.logout,
                  label: s.logout,
                  value: s.exitAdministration,
                  isDestructive: true,
                  onTap: _confirmSignOut,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? EColorConstants.primaryColor.withOpacity(0.1)
          : EColorConstants.authFieldBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: selected
                        ? EColorConstants.primaryColor
                        : EColorConstants.authTextDarkBrown,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Iconsax.tick_circle,
                  color: EColorConstants.primaryColor,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationToggleTile extends StatelessWidget {
  const _NotificationToggleTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: EColorConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Iconsax.notification,
            color: EColorConstants.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: EColorConstants.authPlaceholderGray,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: EColorConstants.authTextDarkBrown,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        activeColor: EColorConstants.primaryColor,
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
                color:
                    isDestructive ? Colors.red : EColorConstants.primaryColor,
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
                    style: const TextStyle(
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
                      color: isDestructive
                          ? Colors.red
                          : EColorConstants.authTextDarkBrown,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const FixedDirectionIcon(
                DirectionalIcons.forwardFixed,
                size: 18,
                color: EColorConstants.authPlaceholderGray,
              ),
          ],
        ),
      ),
    );
  }
}
