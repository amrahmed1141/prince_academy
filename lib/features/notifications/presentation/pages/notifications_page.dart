import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/notifications/data/models/app_notification.dart';
import 'package:prince_academy/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:prince_academy/features/notifications/presentation/bloc/notification_event.dart';
import 'package:prince_academy/features/notifications/presentation/bloc/notification_state.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _NotificationsView();
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            buildWhen: (prev, next) {
              final a = prev is NotificationLoaded ? prev.unreadCount : 0;
              final b = next is NotificationLoaded ? next.unreadCount : 0;
              return a != b;
            },
            builder: (context, state) {
              final unread =
                  state is NotificationLoaded ? state.unreadCount : 0;
              if (unread == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  context
                      .read<NotificationBloc>()
                      .add(const NotificationsMarkAllRead());
                },
                child: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading || state is NotificationInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationError) {
            return _ErrorView(
              message: state.message,
              onRetry: () {
                context
                    .read<NotificationBloc>()
                    .add(const NotificationsRefreshed());
              },
            );
          }

          if (state is! NotificationLoaded) {
            return const SizedBox.shrink();
          }

          if (state.notifications.isEmpty) {
            return const _EmptyView();
          }

          return RefreshIndicator(
            color: EColorConstants.primaryColor,
            onRefresh: () async {
              context
                  .read<NotificationBloc>()
                  .add(const NotificationsRefreshed());
              await context.read<NotificationBloc>().stream.firstWhere(
                    (s) =>
                        s is NotificationLoaded || s is NotificationError,
                  );
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: state.notifications.length +
                  (state.isRefreshing ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (state.isRefreshing && index == 0) {
                  return const LinearProgressIndicator(minHeight: 2);
                }
                final itemIndex = state.isRefreshing ? index - 1 : index;
                final notification = state.notifications[itemIndex];
                return _NotificationTile(notification: notification);
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (unread) {
            context
                .read<NotificationBloc>()
                .add(NotificationMarkedRead(notification.id));
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: unread
                  ? EColorConstants.authFieldBorder
                  : const Color(0xFFEEEEEE),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: unread
                      ? EColorConstants.primaryColor.withOpacity(0.12)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconForType(notification.type),
                  size: 20,
                  color: unread
                      ? EColorConstants.primaryColor
                      : Colors.grey.shade600,
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
                            notification.title,
                            style: TextStyle(
                              fontWeight:
                                  unread ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 15,
                              color: const Color(0xFF1A1A1A),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: EColorConstants.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (notification.body != null &&
                        notification.body!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontFamily: 'Poppins',
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _formatRelative(notification.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontFamily: 'Poppins',
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

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
      case 'payment':
        return Iconsax.ticket;
      case 'session':
      case 'attendance':
        return Iconsax.calendar;
      case 'admin':
        return Iconsax.shield_tick;
      default:
        return Iconsax.notification;
    }
  }

  String _formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(date);
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.notification, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Updates about bookings, sessions, and payments will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: EColorConstants.primaryColor,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
