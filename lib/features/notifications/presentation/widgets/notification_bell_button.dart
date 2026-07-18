import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:prince_academy/features/notifications/presentation/bloc/notification_state.dart';
import 'package:prince_academy/features/notifications/presentation/pages/notifications_page.dart';

/// AppBar / header bell with live unread badge (powered by [NotificationBloc]).
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({
    super.key,
    this.padded = true,
    this.variant = NotificationBellVariant.home,
  });

  /// Matches the circular home AppBar treatment when true.
  final bool padded;

  final NotificationBellVariant variant;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      buildWhen: (prev, next) {
        final a = prev is NotificationLoaded ? prev.unreadCount : -1;
        final b = next is NotificationLoaded ? next.unreadCount : -1;
        return a != b;
      },
      builder: (context, state) {
        final unread = state is NotificationLoaded ? state.unreadCount : 0;

        return IconButton(
          tooltip: 'Notifications',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BlocProvider.value(
                  value: context.read<NotificationBloc>(),
                  child: const NotificationsPage(),
                ),
              ),
            );
          },
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              _BellGlyph(variant: variant, padded: padded),
                  if (unread > 0)
                Positioned(
                  right: padded ? 2 : -2,
                  top: padded ? 2 : -2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    height: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

enum NotificationBellVariant { home, plain, admin }

class _BellGlyph extends StatelessWidget {
  const _BellGlyph({required this.variant, required this.padded});

  final NotificationBellVariant variant;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case NotificationBellVariant.home:
        return Container(
          padding: padded ? const EdgeInsets.all(8) : EdgeInsets.zero,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[100],
          ),
          child: const Icon(Iconsax.notification, size: 20),
        );
      case NotificationBellVariant.admin:
        return Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: EColorConstants.authCardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: EColorConstants.authFieldBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Iconsax.notification,
            size: 20,
            color: EColorConstants.authTextDarkBrown,
          ),
        );
      case NotificationBellVariant.plain:
        return const Icon(Iconsax.notification);
    }
  }
}
