import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';

class AdminTabSelector extends StatelessWidget {
  final List<String> labels;
  final List<IconData>? icons;
  final ValueChanged<int>? onChanged;
  final int selectedIndex;

  const AdminTabSelector({
    super.key,
    required this.labels,
    this.icons,
    this.onChanged,
    this.selectedIndex = 0,
  }) : assert(labels.length >= 1);

  @override
  Widget build(BuildContext context) {
    debugPrint('AdminTabSelector build selectedIndex=$selectedIndex');
    return Container(
      decoration: BoxDecoration(
        color: EColorConstants.authDeepPrimary.withOpacity(0.35),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isSelected = selectedIndex == index;
          final IconData? icon =
              icons != null && index < icons!.length ? icons![index] : null;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                debugPrint('AdminTabSelector tapped index=$index');
                onChanged?.call(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? EColorConstants.authCardWhite
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null)
                      Icon(
                        icon,
                        size: 18,
                        color: isSelected
                            ? EColorConstants.primaryColor
                            : EColorConstants.authPlaceholderGray,
                      ),
                    if (icon != null) const SizedBox(width: 6),
                    Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? EColorConstants.authTextDarkBrown
                            : EColorConstants.authPlaceholderGray,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
