import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/data/models/low_attendance_member_model.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_section_card.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';

class DashboardAttentionList extends StatefulWidget {
  const DashboardAttentionList({
    super.key,
    required this.members,
    this.onSeeAll,
    this.onMemberTap,
  });

  final List<LowAttendanceMemberModel> members;
  final VoidCallback? onSeeAll;
  final ValueChanged<LowAttendanceMemberModel>? onMemberTap;

  @override
  State<DashboardAttentionList> createState() => _DashboardAttentionListState();
}

class _DashboardAttentionListState extends State<DashboardAttentionList> {
  static const _cardWidth = 280.0;
  static const _gap = 12.0;
  static const _maxExpanded = 3;

  // Tight, measured slots — every collapsed card uses exactly this height.
  static const _verticalPadding = 20.0;
  static const _headerHeight = 36.0;
  static const _headerGap = 8.0;
  static const _coachRowHeight = 48.0;
  static const _coachRowGap = 6.0;
  static const _footerHeight = 18.0;

  static const _collapsedHeight = _verticalPadding +
      _headerHeight +
      _headerGap +
      _coachRowHeight +
      _footerHeight;

  final Set<String> _expandedIds = {};

  bool _isExpanded(String id) => _expandedIds.contains(id);

  void _toggle(String id) {
    setState(() {
      if (!_expandedIds.remove(id)) _expandedIds.add(id);
    });
  }

  int _visibleCount(LowAttendanceMemberModel m) {
    if (m.coaches.isEmpty) return 0;
    return _isExpanded(m.userId) ? m.coaches.length.clamp(0, _maxExpanded) : 1;
  }

  double _cardHeight(LowAttendanceMemberModel m) {
    if (!_isExpanded(m.userId)) return _collapsedHeight;

    final count = _visibleCount(m);
    var h = _verticalPadding + _headerHeight + _headerGap;
    if (count == 0) {
      h += 16;
    } else {
      h += count * _coachRowHeight + (count - 1) * _coachRowGap;
    }
    if (m.coaches.length > 1) h += _footerHeight;
    return h;
  }

  double _listHeight() {
    if (widget.members.isEmpty) return 0;
    var maxHeight = _collapsedHeight;
    for (final m in widget.members) {
      final h = _cardHeight(m);
      if (h > maxHeight) maxHeight = h;
    }
    return maxHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Needs attention',
                style: TextStyle(
                  color: EColorConstants.authTextDarkBrown,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            if (widget.members.isNotEmpty)
              TextButton(
                onPressed: widget.onSeeAll,
                style: TextButton.styleFrom(
                  foregroundColor: EColorConstants.primaryColor,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.members.isEmpty)
          AdminSectionCard(
            borderRadius: 18,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: Column(
              children: [
                Icon(
                  Iconsax.tick_circle,
                  size: 36,
                  color: EColorConstants.primaryColor.withOpacity(0.7),
                ),
                const SizedBox(height: 10),
                const Text(
                  'All clear',
                  style: TextStyle(
                    color: EColorConstants.authTextDarkBrown,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'No members with unusually low attendance right now.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: EColorConstants.authPlaceholderGray,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          )
        else
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            height: _listHeight(),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.members.length,
              cacheExtent: _cardWidth * 3,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              primary: false,
              itemBuilder: (context, index) {
                final member = widget.members[index];
                final expanded = _isExpanded(member.userId);
                final count = _visibleCount(member);
                final showExpand = !expanded && member.coaches.length > 1;
                final showLess = expanded && member.coaches.length > 1;
                final showAndMore =
                    expanded && member.coaches.length > _maxExpanded;

                return Padding(
                  padding: EdgeInsets.only(
                    right: index == widget.members.length - 1 ? 0 : _gap,
                  ),
                  child: SizedBox(
                    width: _cardWidth,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        height: _cardHeight(member),
                        child: _LowAttendanceCard(
                          key: ValueKey(member.userId),
                          member: member,
                          visibleCoaches: member.coaches.take(count).toList(),
                          showExpand: showExpand,
                          showLess: showLess,
                          showAndMore: showAndMore,
                          reserveFooter: !expanded || member.coaches.length > 1,
                          onToggle: () => _toggle(member.userId),
                          onOpenTracking: widget.onMemberTap == null
                              ? null
                              : () => widget.onMemberTap!(member),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _LowAttendanceCard extends StatelessWidget {
  const _LowAttendanceCard({
    super.key,
    required this.member,
    required this.visibleCoaches,
    required this.showExpand,
    required this.showLess,
    required this.showAndMore,
    required this.reserveFooter,
    this.onToggle,
    this.onOpenTracking,
  });

  final LowAttendanceMemberModel member;
  final List<LowAttendanceCoachProgress> visibleCoaches;
  final bool showExpand;
  final bool showLess;
  final bool showAndMore;
  final bool reserveFooter;
  final VoidCallback? onToggle;
  final VoidCallback? onOpenTracking;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AdminSectionCard(
        borderRadius: 18,
        padding: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onOpenTracking,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: _DashboardAttentionListState._headerHeight,
                        child: Row(
                          children: [
                            CoachAvatar(
                              coachName: member.fullName,
                              photoUrl: member.avatarUrl,
                              size: 36,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                member.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: EColorConstants.authTextDarkBrown,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: _DashboardAttentionListState._headerGap,
                      ),
                      if (visibleCoaches.isEmpty)
                        const SizedBox(
                          height:
                              _DashboardAttentionListState._coachRowHeight,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'No coach progress available',
                              style: TextStyle(
                                color: EColorConstants.authPlaceholderGray,
                                fontSize: 11,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        )
                      else
                        for (var i = 0; i < visibleCoaches.length; i++) ...[
                          if (i > 0)
                            const SizedBox(
                              height:
                                  _DashboardAttentionListState._coachRowGap,
                            ),
                          SizedBox(
                            height:
                                _DashboardAttentionListState._coachRowHeight,
                            child: _CoachMissedContainer(
                              coach: visibleCoaches[i],
                            ),
                          ),
                        ],
                    ],
                  ),
                ),
              ),
              if (reserveFooter)
                SizedBox(
                  height: _DashboardAttentionListState._footerHeight,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: showExpand
                        ? GestureDetector(
                            onTap: onToggle,
                            behavior: HitTestBehavior.opaque,
                            child: const Text(
                              'Show more',
                              style: TextStyle(
                                color: EColorConstants.primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          )
                        : showLess && !showAndMore
                            ? GestureDetector(
                                onTap: onToggle,
                                behavior: HitTestBehavior.opaque,
                                child: const Text(
                                  'Show less',
                                  style: TextStyle(
                                    color: EColorConstants.primaryColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              )
                            : showAndMore
                                ? Row(
                                    children: [
                                      GestureDetector(
                                        onTap: onToggle,
                                        behavior: HitTestBehavior.opaque,
                                        child: const Text(
                                          'Show less',
                                          style: TextStyle(
                                            color:
                                                EColorConstants.primaryColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: onOpenTracking,
                                        behavior: HitTestBehavior.opaque,
                                        child: const Text(
                                          'and more...',
                                          style: TextStyle(
                                            color: EColorConstants
                                                .authPlaceholderGray,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachMissedContainer extends StatelessWidget {
  const _CoachMissedContainer({required this.coach});

  final LowAttendanceCoachProgress coach;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  coach.missedSessionsLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFB71C1C),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    height: 1.2,
                  ),
                ),
                Text(
                  coach.withCoachLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: EColorConstants.authPlaceholderGray,
                    fontSize: 9,
                    fontFamily: 'Poppins',
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _AttendanceRing(
            progress: coach.progress,
            label: coach.ratioLabel,
          ),
        ],
      ),
    );
  }
}

class _AttendanceRing extends StatelessWidget {
  const _AttendanceRing({
    required this.progress,
    required this.label,
  });

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 3,
              strokeCap: StrokeCap.round,
              color: Color(0xFFE8E0D8),
              backgroundColor: Colors.transparent,
            ),
          ),
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              strokeCap: StrokeCap.round,
              color: EColorConstants.primaryColor,
              backgroundColor: Colors.transparent,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: EColorConstants.authTextDarkBrown,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
