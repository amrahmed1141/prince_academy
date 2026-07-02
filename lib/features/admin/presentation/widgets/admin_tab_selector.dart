import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';

class AdminTabSelector extends StatelessWidget {
  final List<String> labels;
  final ValueChanged<int>? onChanged;
  final int selectedIndex;

  const AdminTabSelector({
    super.key,
    required this.labels,
    this.onChanged,
    this.selectedIndex = 0,
  }) : assert(labels.length >= 1);

  static const List<IconData> _defaultIcons = [
    Iconsax.profile_add,
    Iconsax.calendar_1,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isSelected = selectedIndex == index;
          final icon = index < _defaultIcons.length
              ? _defaultIcons[index]
              : Iconsax.element_3;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: index == 0 ? 0 : 10),
              child: GestureDetector(
                onTap: () => onChanged?.call(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? EColorConstants.primaryColor
                        : EColorConstants.authCardWhite,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected
                          ? EColorConstants.primaryColor
                          : EColorConstants.authFieldBorder.withOpacity(0.6),
                      width: 1.4,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: EColorConstants.primaryColor
                                  .withOpacity(0.22),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: isSelected
                            ? Colors.white
                            : EColorConstants.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          labels[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : EColorConstants.primaryColor,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
