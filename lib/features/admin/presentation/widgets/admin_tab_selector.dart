import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';

class AdminTabSelector extends StatefulWidget {
  final List<String> labels;
  final List<IconData>? icons;
  final ValueChanged<int>? onChanged;
  final int initialIndex;

  const AdminTabSelector({
    super.key,
    required this.labels,
    this.icons,
    this.onChanged,
    this.initialIndex = 0,
  }) : assert(labels.length >= 1);

  @override
  State<AdminTabSelector> createState() => _AdminTabSelectorState();
}

class _AdminTabSelectorState extends State<AdminTabSelector> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EColorConstants.authDeepPrimary.withOpacity(0.35),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(widget.labels.length, (index) {
          final isSelected = _selectedIndex == index;
          final IconData? icon = widget.icons != null && index < widget.icons!.length
              ? widget.icons![index]
              : null;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedIndex = index);
                widget.onChanged?.call(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? EColorConstants.authCardWhite : Colors.transparent,
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
                      widget.labels[index],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
