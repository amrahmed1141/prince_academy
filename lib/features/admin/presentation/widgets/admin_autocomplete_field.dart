import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_form_styles.dart';

/// Text field with inline suggestions styled like admin form fields.
class AdminAutocompleteField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final List<String> options;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final String? hint;

  const AdminAutocompleteField({
    super.key,
    required this.label,
    required this.controller,
    required this.options,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.hint,
  });

  @override
  State<AdminAutocompleteField> createState() => _AdminAutocompleteFieldState();
}

class _AdminAutocompleteFieldState extends State<AdminAutocompleteField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFormStyles.fieldLabel(widget.label),
        const SizedBox(height: 8),
        RawAutocomplete<String>(
          textEditingController: widget.controller,
          focusNode: _focusNode,
          optionsBuilder: (textEditingValue) {
            final query = textEditingValue.text.trim().toLowerCase();
            if (query.isEmpty) return widget.options;
            return widget.options.where(
              (option) => option.toLowerCase().contains(query),
            );
          },
          onSelected: (selection) {
            widget.controller.text = selection;
            widget.onChanged?.call(selection);
          },
          fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: fieldController,
              focusNode: focusNode,
              keyboardType: widget.keyboardType,
              validator: widget.validator,
              onChanged: widget.onChanged,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: EColorConstants.authTextDarkBrown,
                fontFamily: 'Poppins',
              ),
              decoration: AdminFormStyles.fieldDecoration(hintText: widget.hint),
            );
          },
          optionsViewBuilder: (context, onSelected, iterableOptions) {
            final items = iterableOptions.toList();
            if (items.isEmpty) return const SizedBox.shrink();

            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(14),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180, minWidth: 200),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),
                    itemBuilder: (context, index) {
                      final option = items[index];
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Text(
                            option,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
