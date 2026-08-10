import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/booking/data/models/booking_freeze_model.dart';

class MemberFreezeRequestCard extends StatelessWidget {
  const MemberFreezeRequestCard({
    super.key,
    required this.request,
  });

  final MemberFreezeRequest request;

  static const _innerFill = Color(0xFFF8F1E8);
  static const _pillFill = Color(0xFFF0E8DE);

  @override
  Widget build(BuildContext context) {
    final dateLabels =
        request.sessionDates.map(formatFreezeDisplayDate).toList();
    final coachLabel = request.coachName.trim().isEmpty
        ? 'Coach'
        : request.coachName.trim();
    final statusMeta = _statusMeta(request.status);

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
            children: [
              Expanded(
                child: Text(
                  coachLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: EColorConstants.authTextDarkBrown,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusMeta.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusMeta.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusMeta.foreground,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _pillFill,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${request.sessionCount} session${request.sessionCount == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: EColorConstants.authPlaceholderGray,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 14),
          _InfoBlock(
            label: 'FROZEN SESSIONS',
            child: dateLabels.isEmpty
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
                      for (final date in dateLabels)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: EColorConstants.authCardWhite,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: EColorConstants.authFieldBorder
                                  .withOpacity(0.55),
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
          ),
          if (request.isApproved) ...[
            const SizedBox(height: 10),
            _InfoBlock(
              label: 'EXPIRY',
              child: Text(
                _expiryLine(request),
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
        ],
      ),
    );
  }

  static String _expiryLine(MemberFreezeRequest request) {
    final original = request.originalSubscriptionEnd == null
        ? '—'
        : formatFreezeDisplayDate(request.originalSubscriptionEnd!);
    final updated = request.newSubscriptionEnd == null
        ? '—'
        : formatFreezeDisplayDate(request.newSubscriptionEnd!);
    return '$original → $updated';
  }

  static _StatusMeta _statusMeta(String status) {
    switch (status) {
      case 'approved':
        return const _StatusMeta(
          label: 'Approved',
          background: Color(0xFFE8F5E9),
          foreground: Color(0xFF2E7D32),
        );
      case 'rejected':
        return const _StatusMeta(
          label: 'Rejected',
          background: Color(0xFFFFEBEE),
          foreground: Color(0xFFC62828),
        );
      case 'cancelled':
        return const _StatusMeta(
          label: 'Cancelled',
          background: Color(0xFFF5F5F5),
          foreground: Color(0xFF757575),
        );
      default:
        return const _StatusMeta(
          label: 'Pending',
          background: Color(0xFFFFF3E0),
          foreground: Color(0xFFE65100),
        );
    }
  }
}

class _StatusMeta {
  const _StatusMeta({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
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
        color: MemberFreezeRequestCard._innerFill,
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
