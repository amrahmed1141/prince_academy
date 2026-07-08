import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_form_styles.dart';

typedef AdminSearchTextBuilder<T> = String Function(T item);

/// Drop-in field that matches admin dropdown styling but supports search.
class AdminSearchableDropdownField<T> extends StatelessWidget {
  final String? label;
  final T? value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final AdminSearchTextBuilder<T>? searchText;
  final Widget Function(T item)? selectedBuilder;
  final Widget Function(T item)? itemBuilder;
  final IconData? prefixIcon;
  final String? hintText;
  final String? errorText;
  final bool enabled;
  final ValueChanged<T?> onChanged;
  final Color? fillColor;

  const AdminSearchableDropdownField({
    super.key,
    this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    this.searchText,
    this.selectedBuilder,
    this.itemBuilder,
    this.prefixIcon,
    this.hintText,
    this.errorText,
    this.enabled = true,
    required this.onChanged,
    this.fillColor,
  });

  String _searchFor(T item) => searchText?.call(item) ?? itemLabel(item);

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled || items.isEmpty) return;

    final selected = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SearchablePickerSheet<T>(
        items: items,
        itemLabel: itemLabel,
        searchText: _searchFor,
        itemBuilder: itemBuilder,
        selectedValue: value,
      ),
    );

    if (selected != null) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final field = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => _openPicker(context) : null,
        borderRadius: BorderRadius.circular(16),
        child: InputDecorator(
          decoration: AdminFormStyles.fieldDecoration(
            prefixIcon: prefixIcon,
            hintText: hintText,
            errorText: errorText,
          ).copyWith(
            fillColor: fillColor ?? AdminFormStyles.fieldFill,
            suffixIcon: const Icon(
              Iconsax.arrow_down_1,
              size: 16,
              color: EColorConstants.authPlaceholderGray,
            ),
          ),
          isEmpty: value == null,
          child: value == null
              ? Text(
                  hintText ?? 'Select option',
                  style: const TextStyle(
                    fontSize: 13,
                    color: EColorConstants.authPlaceholderGray,
                    fontFamily: 'Poppins',
                  ),
                )
              : (selectedBuilder?.call(value as T) ??
                  Text(
                    itemLabel(value as T),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: EColorConstants.authTextDarkBrown,
                      fontFamily: 'Poppins',
                    ),
                  )),
        ),
      ),
    );

    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFormStyles.fieldLabel(label!),
        const SizedBox(height: 8),
        field,
      ],
    );
  }
}

class _SearchablePickerSheet<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T item) itemLabel;
  final String Function(T item) searchText;
  final Widget Function(T item)? itemBuilder;
  final T? selectedValue;

  const _SearchablePickerSheet({
    required this.items,
    required this.itemLabel,
    required this.searchText,
    this.itemBuilder,
    this.selectedValue,
  });

  @override
  State<_SearchablePickerSheet<T>> createState() =>
      _SearchablePickerSheetState<T>();
}

class _SearchablePickerSheetState<T> extends State<_SearchablePickerSheet<T>> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<T> get _filteredItems {
    final trimmed = _query.trim().toLowerCase();
    if (trimmed.isEmpty) return widget.items;
    return widget.items
        .where((item) => widget.searchText(item).toLowerCase().contains(trimmed))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
                decoration: AdminFormStyles.fieldDecoration(
                  hintText: 'Search...',
                  prefixIcon: Iconsax.search_normal_1,
                ),
              ),
            ),
            Flexible(
              child: _filteredItems.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No matches found',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: EColorConstants.authPlaceholderGray,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      itemCount: _filteredItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final isSelected = item == widget.selectedValue;
                        return Material(
                          color: isSelected
                              ? EColorConstants.primaryColor.withOpacity(0.08)
                              : AdminFormStyles.sessionPanelFill,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.of(context).pop(item),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: widget.itemBuilder?.call(item) ??
                                  Text(
                                    widget.itemLabel(item),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: EColorConstants.authTextDarkBrown,
                                    ),
                                  ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
