import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/data/models/session_detail_model.dart';
import 'package:prince_academy/features/booking/data/models/booking_freeze_model.dart';

class FreezeSessionSelector extends StatelessWidget {
  const FreezeSessionSelector({
    super.key,
    required this.sessions,
    required this.selectedKeys,
    required this.onToggle,
  });

  final List<SessionDetail> sessions;
  final Set<String> selectedKeys;
  final ValueChanged<SessionDetail> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final session in sessions) ...[
          _FreezeSessionTile(
            key: ValueKey(
              '${session.sessionDate.year}-${session.sessionDate.month}-${session.sessionDate.day}',
            ),
            session: session,
            selected: selectedKeys.contains(
              '${session.sessionDate.year}-${session.sessionDate.month}-${session.sessionDate.day}',
            ),
            onTap: () => onToggle(session),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _FreezeSessionTile extends StatelessWidget {
  const _FreezeSessionTile({
    super.key,
    required this.session,
    required this.selected,
    required this.onTap,
  });

  final SessionDetail session;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = session.status.toLowerCase();
    final statusColor = switch (status) {
      'missed' => const Color(0xFFC62828),
      'today' => EColorConstants.primaryColor,
      _ => EColorConstants.authPlaceholderGray,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: EColorConstants.authCardWhite,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: selected
                      ? EColorConstants.primaryColor
                      : EColorConstants.authPlaceholderGray,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatFreezeDisplayDate(session.sessionDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: EColorConstants.authTextDarkBrown,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session.dayName.trim().isEmpty
                            ? status
                            : '${session.dayName.trim()} · $status',
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
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
      ),
    );
  }
}
