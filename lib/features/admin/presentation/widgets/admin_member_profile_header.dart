import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';

class AdminMemberProfileHeader extends StatelessWidget {
  final VoidCallback onBack;
  final String displayName;
  final String displayPhone;
  final String initials;
  final int totalBookings;
  final int activeCount;
  final int pendingCount;
  final int expiredCount;
  final String? statusFilter;
  final ValueChanged<String?> onStatusFilterChanged;

  const AdminMemberProfileHeader({
    super.key,
    required this.onBack,
    required this.displayName,
    required this.displayPhone,
    required this.initials,
    required this.totalBookings,
    required this.activeCount,
    required this.pendingCount,
    required this.expiredCount,
    required this.statusFilter,
    required this.onStatusFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                color: EColorConstants.authTextDarkBrown,
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F1F0),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (statusFilter != null) {
                        onStatusFilterChanged(null);
                      }
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(0xFFE8CFA8),
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3F2B1A),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: EColorConstants.authTextDarkBrown,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Iconsax.call5,
                                    size: 13,
                                    color: EColorConstants.authPlaceholderGray,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      displayPhone,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color:
                                            EColorConstants.authPlaceholderGray,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Iconsax.calendar_1,
                                    size: 14,
                                    color: EColorConstants.authPlaceholderGray,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$totalBookings Booking${totalBookings == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: EColorConstants.authTextDarkBrown,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(height: 1, color: const Color(0xFFE2DEDA)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatusPill(
                        label: 'Active',
                        count: activeCount,
                        backgroundColor: const Color(0xFFD8F0E2),
                        textColor: const Color(0xFF2E7D5B),
                        isSelected: statusFilter == 'active',
                        onTap: () => onStatusFilterChanged(
                          statusFilter == 'active' ? null : 'active',
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusPill(
                        label: 'Pending',
                        count: pendingCount,
                        backgroundColor: const Color(0xFFF5E7CE),
                        textColor: const Color(0xFF9D6D1F),
                        isSelected: statusFilter == 'pending',
                        onTap: () => onStatusFilterChanged(
                          statusFilter == 'pending' ? null : 'pending',
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusPill(
                        label: 'Expired',
                        count: expiredCount,
                        backgroundColor: const Color(0xFFE8E6E5),
                        textColor: const Color(0xFF706F6E),
                        isSelected: statusFilter == 'expired',
                        onTap: () => onStatusFilterChanged(
                          statusFilter == 'expired' ? null : 'expired',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final int count;
  final Color backgroundColor;
  final Color textColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusPill({
    required this.label,
    required this.count,
    required this.backgroundColor,
    required this.textColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? textColor : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Text(
            '$count $label',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textColor,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }
}

class AdminBookingSectionHeader extends StatelessWidget {
  final String title;

  const AdminBookingSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: EColorConstants.authPlaceholderGray,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}
