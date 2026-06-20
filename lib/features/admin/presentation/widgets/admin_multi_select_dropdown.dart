import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';

class AdminMultiSelectDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final List<String> options;
  final List<String> selected;
  final IconData prefixIcon;
  final bool enabled;
  final ValueChanged<List<String>> onChanged;

  const AdminMultiSelectDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    required this.selected,
    required this.prefixIcon,
    this.enabled = true,
    required this.onChanged,
  });

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled) return;

    final tempSelected = List<String>.from(selected);

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EColorConstants.authCardWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: EColorConstants.authFieldBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: EColorConstants.authTextDarkBrown,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, tempSelected),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final isChecked = tempSelected.contains(option);
                        return CheckboxListTile(
                          value: isChecked,
                          activeColor: EColorConstants.primaryColor,
                          title: Text(
                            option,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                          ),
                          onChanged: (checked) {
                            setModalState(() {
                              if (checked == true) {
                                if (!tempSelected.contains(option)) {
                                  tempSelected.add(option);
                                }
                              } else {
                                tempSelected.remove(option);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      onChanged(result);
    }
  }

  String get _displayText {
    if (selected.isEmpty) return '';
    return selected.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: EColorConstants.authTextDarkBrown,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: enabled ? () => _openPicker(context) : null,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: EColorConstants.authPlaceholderGray,
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
              prefixIcon: Icon(
                prefixIcon,
                size: 18,
                color: EColorConstants.authPlaceholderGray,
              ),
              suffixIcon: const Icon(
                Iconsax.arrow_down_1,
                size: 16,
                color: EColorConstants.authPlaceholderGray,
              ),
              filled: true,
              fillColor: EColorConstants.authFieldBackground,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: EColorConstants.authFieldBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: EColorConstants.authFieldBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: EColorConstants.primaryColor,
                  width: 1.2,
                ),
              ),
            ),
            child: Text(
              _displayText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected.isEmpty
                    ? EColorConstants.authPlaceholderGray
                    : EColorConstants.authTextDarkBrown,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
