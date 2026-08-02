import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/features/admin/data/repositories/finance_repository.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/admin/presentation/widgets/finance/finance_currency.dart';

class FinanceCoachTile extends StatelessWidget {
  const FinanceCoachTile({
    super.key,
    required this.coach,
  });

  final TopEarningCoach coach;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CoachAvatar(
            coachName: coach.name,
            photoUrl: coach.avatarUrl,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coach.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  coach.specialty,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            FinanceCurrency.egp(coach.amount, decimals: false),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
