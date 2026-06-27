import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/data/models/branch_model.dart';

class BranchSelectorField extends StatelessWidget {
  final List<Branch> branches;
  final String? selectedBranchId;
  final bool isLoading;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String?> onChanged;
  final VoidCallback? onAddBranch;

  const BranchSelectorField({
    super.key,
    required this.branches,
    required this.selectedBranchId,
    this.isLoading = false,
    this.enabled = true,
    this.errorText,
    required this.onChanged,
    this.onAddBranch,
  });

  @override
  Widget build(BuildContext context) {
    final hasValidValue =
        selectedBranchId != null && branches.any((b) => b.id == selectedBranchId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Branch',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: EColorConstants.authTextDarkBrown,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      value: hasValidValue ? selectedBranchId : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: 'Select Branch',
                        hintStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: EColorConstants.authPlaceholderGray,
                        ),
                        prefixIcon: const Icon(
                          Iconsax.building,
                          size: 18,
                          color: EColorConstants.primaryColor,
                        ),
                        errorText: errorText,
                        filled: true,
                        fillColor: EColorConstants.authFieldBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: EColorConstants.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: EColorConstants.primaryColor.withOpacity(0.3),
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
                      items: branches
                          .map(
                            (branch) => DropdownMenuItem(
                              value: branch.id,
                              child: Text(
                                branch.name,
                                style: const TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: enabled && branches.isNotEmpty ? onChanged : null,
                    ),
            ),
            if (onAddBranch != null) ...[
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 48,
                  child: IconButton.filled(
                    onPressed: enabled ? onAddBranch : null,
                    style: IconButton.styleFrom(
                      backgroundColor: EColorConstants.primaryColor,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                    ),
                    icon: const Icon(Icons.add_business_outlined, size: 22),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (!isLoading && branches.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            onAddBranch != null
                ? 'No branches yet. Tap + to add one.'
                : 'No branches available.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange.shade700,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ],
    );
  }
}
