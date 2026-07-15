import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

class CoachBranchOption {
  const CoachBranchOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

List<CoachBranchOption> uniqueBranchesFromSessions(
  List<CoachSessionModel> sessions,
) {
  final map = <String, String>{};
  for (final session in sessions) {
    final id = session.branchId;
    if (id == null || id.isEmpty) continue;
    final name = session.branchName?.trim();
    map.putIfAbsent(
      id,
      () => (name != null && name.isNotEmpty) ? name : 'Branch',
    );
  }
  return map.entries
      .map((e) => CoachBranchOption(id: e.key, name: e.value))
      .toList();
}

Future<CoachBranchOption?> showBranchPickerSheet({
  required BuildContext context,
  required List<CoachBranchOption> branches,
  String? selectedBranchId,
  String title = 'Choose Branch',
}) {
  return showModalBottomSheet<CoachBranchOption>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'This coach trains at more than one location. Pick a branch to continue.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
            ),
            const SizedBox(height: 16),
            ...branches.map((branch) {
              final selected = branch.id == selectedBranchId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => Navigator.pop(context, branch),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? EColorConstants.primaryColor.withOpacity(0.1)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? EColorConstants.primaryColor
                            : Colors.grey[200]!,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.location,
                          size: 18,
                          color: selected
                              ? EColorConstants.primaryColor
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            branch.name,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? EColorConstants.primaryColor
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Iconsax.tick_circle5,
                            size: 20,
                            color: EColorConstants.primaryColor,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    },
  );
}
