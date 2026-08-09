import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/booking/data/models/booking_freeze_model.dart';

class ActiveFreezeCard extends StatelessWidget {
  const ActiveFreezeCard({
    super.key,
    required this.freeze,
  });

  final ActiveBookingFreeze freeze;

  static const _innerFill = Color(0xFFF8F1E8);
  static const _pillFill = Color(0xFFF0E8DE);

  @override
  Widget build(BuildContext context) {
    final dateLabels =
        freeze.sessionDates.map(formatFreezeDisplayDate).toList();
    final original = freeze.originalSubscriptionEnd == null
        ? '—'
        : formatFreezeDisplayDate(freeze.originalSubscriptionEnd!);
    final updated = freeze.newSubscriptionEnd == null
        ? '—'
        : formatFreezeDisplayDate(freeze.newSubscriptionEnd!);
    final coachLabel = freeze.coachName.trim().isEmpty
        ? 'Coach'
        : freeze.coachName.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EColorConstants.authCardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CoachAvatar(
                coachName: freeze.fullName,
                photoUrl: freeze.avatarUrl,
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      freeze.fullName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: EColorConstants.authTextDarkBrown,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _pillFill,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Coach: $coachLabel · ${freeze.sessionCount} frozen',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: EColorConstants.authPlaceholderGray,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _FrozenSessionsBlock(dates: dateLabels),
          const SizedBox(height: 10),
          _InfoBlock(
            label: 'EXPIRY',
            child: Text(
              '$original → $updated',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: EColorConstants.primaryColor,
                fontFamily: 'Poppins',
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FrozenSessionsBlock extends StatelessWidget {
  const _FrozenSessionsBlock({required this.dates});

  final List<String> dates;

  @override
  Widget build(BuildContext context) {
    return _InfoBlock(
      label: 'FROZEN SESSIONS',
      child: dates.isEmpty
          ? const Text(
              'No dates',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: EColorConstants.authTextDarkBrown,
                fontFamily: 'Poppins',
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final date in dates)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: EColorConstants.authCardWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: EColorConstants.authFieldBorder.withOpacity(0.55),
                      ),
                    ),
                    child: Text(
                      date,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: EColorConstants.authTextDarkBrown,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: ActiveFreezeCard._innerFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: EColorConstants.primaryColor.withOpacity(0.75),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
