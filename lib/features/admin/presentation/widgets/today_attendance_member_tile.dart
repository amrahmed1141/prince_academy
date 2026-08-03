import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/data/models/today_attendance_member_model.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';

class TodayAttendanceMemberTile extends StatelessWidget {
  const TodayAttendanceMemberTile({
    super.key,
    required this.member,
    this.isMarking = false,
    this.onMarkAttended,
    this.onTap,
  });

  final TodayAttendanceMember member;
  final bool isMarking;
  final VoidCallback? onMarkAttended;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sessionLabel = [
      if ((member.sessionType ?? '').isNotEmpty) member.sessionType!,
      if ((member.sessionTime ?? '').isNotEmpty) member.sessionTime!,
    ].join(' • ');

    final metaParts = <String>[
      if (member.coachName.isNotEmpty) member.coachName,
      if (sessionLabel.isNotEmpty) sessionLabel,
      if ((member.branchName ?? '').isNotEmpty) member.branchName!,
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: EColorConstants.authCardWhite,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CoachAvatar(
                coachName: member.memberName,
                photoUrl: member.memberPhoto,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.memberName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: EColorConstants.authTextDarkBrown,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    if (metaParts.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        metaParts.join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: EColorConstants.authPlaceholderGray,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _StatusChip(attended: member.isAttended),
                        if (!member.isAttended && onMarkAttended != null)
                          _MarkButton(
                            isLoading: isMarking,
                            onTap: isMarking ? null : onMarkAttended,
                          ),
                      ],
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
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.attended});

  final bool attended;

  @override
  Widget build(BuildContext context) {
    final bg = attended
        ? const Color(0xFFE8F5E9)
        : EColorConstants.authFieldBackground;
    final fg = attended
        ? const Color(0xFF2E7D32)
        : EColorConstants.authTextDarkBrown;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        attended ? 'Attended' : 'Not yet',
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

class _MarkButton extends StatelessWidget {
  const _MarkButton({
    required this.isLoading,
    this.onTap,
  });

  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EColorConstants.primaryColor.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                // Absorb tap so the parent member InkWell does not navigate.
                onTap!();
              },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: isLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: EColorConstants.primaryColor,
                  ),
                )
              : const Text(
                  'Mark attended',
                  style: TextStyle(
                    color: EColorConstants.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
        ),
      ),
    );
  }
}
