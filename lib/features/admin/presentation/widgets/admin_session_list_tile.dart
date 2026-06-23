import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';

enum AdminSessionTileStatus { completed, upcoming, missed }

class AdminSessionListTile extends StatelessWidget {
  final String coachName;
  final String dateTimeLabel;
  final String location;
  final AdminSessionTileStatus status;
  final bool canReAttend;
  final bool canUnmark;
  final bool isReAttending;
  final bool isUnmarking;
  final VoidCallback? onReAttend;
  final VoidCallback? onUnmark;

  const AdminSessionListTile({
    super.key,
    required this.coachName,
    required this.dateTimeLabel,
    this.location = 'Prince Academy - Main Gym',
    required this.status,
    this.canReAttend = false,
    this.canUnmark = false,
    this.isReAttending = false,
    this.isUnmarking = false,
    this.onReAttend,
    this.onUnmark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusIcon(status: status),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coachName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: EColorConstants.authTextDarkBrown,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Iconsax.calendar_1,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        dateTimeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Iconsax.location,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _Trailing(
            status: status,
            canReAttend: canReAttend,
            canUnmark: canUnmark,
            isReAttending: isReAttending,
            isUnmarking: isUnmarking,
            onReAttend: onReAttend,
            onUnmark: onUnmark,
          ),
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final AdminSessionTileStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, icon, color) = switch (status) {
      AdminSessionTileStatus.completed => (
          const Color(0xFFE8F5E9),
          Icons.check,
          const Color(0xFF2E7D32),
        ),
      AdminSessionTileStatus.upcoming => (
          EColorConstants.authSoftGold,
          Icons.circle_outlined,
          EColorConstants.primaryColor,
        ),
      AdminSessionTileStatus.missed => (
          const Color(0xFFFFEBEE),
          Icons.close,
          const Color(0xFFD32F2F),
        ),
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _Trailing extends StatelessWidget {
  final AdminSessionTileStatus status;
  final bool canReAttend;
  final bool canUnmark;
  final bool isReAttending;
  final bool isUnmarking;
  final VoidCallback? onReAttend;
  final VoidCallback? onUnmark;

  const _Trailing({
    required this.status,
    required this.canReAttend,
    required this.canUnmark,
    required this.isReAttending,
    required this.isUnmarking,
    this.onReAttend,
    this.onUnmark,
  });

  @override
  Widget build(BuildContext context) {
    if (status == AdminSessionTileStatus.missed && canReAttend) {
      return _ActionButton(
        label: 'Re-Attend',
        color: const Color(0xFF2E7D32),
        isLoading: isReAttending,
        onPressed: onReAttend,
      );
    }

    if (status == AdminSessionTileStatus.completed && canUnmark) {
      return _ActionButton(
        label: 'Undo',
        color: const Color(0xFFD32F2F),
        isLoading: isUnmarking,
        onPressed: onUnmark,
      );
    }

    final (label, color, bg) = switch (status) {
      AdminSessionTileStatus.completed => (
          'Completed',
          const Color(0xFF2E7D32),
          const Color(0xFFE8F5E9),
        ),
      AdminSessionTileStatus.upcoming => (
          'Scheduled',
          EColorConstants.authPlaceholderGray,
          Colors.grey.shade100,
        ),
      AdminSessionTileStatus.missed => (
          'Expired',
          EColorConstants.authPlaceholderGray,
          Colors.grey.shade100,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 11, fontFamily: 'Poppins'),
            ),
    );
  }
}
