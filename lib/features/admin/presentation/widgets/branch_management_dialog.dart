import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/features/admin/data/models/branch_model.dart';
import 'package:prince_academy/features/admin/data/repositories/branch_repository.dart';

class BranchManagementDialog extends StatefulWidget {
  const BranchManagementDialog({super.key});

  @override
  State<BranchManagementDialog> createState() => _BranchManagementDialogState();
}

class _BranchManagementDialogState extends State<BranchManagementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  List<Branch> _branches = [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasChanges = false;

  // If editing an existing branch
  Branch? _editingBranch;

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchBranches() async {
    setState(() => _isLoading = true);
    try {
      final branches = await sl<BranchRepository>().getAllBranches();
      setState(() {
        _branches = branches;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load branches: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final repo = sl<BranchRepository>();
      if (_editingBranch != null) {
        // Edit mode
        final updated = await repo.updateBranch(
          id: _editingBranch!.id,
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
        );
        _showSuccessSnackBar('Branch updated: ${updated.name}');
        setState(() {
          _editingBranch = null;
          _hasChanges = true;
        });
      } else {
        // Add mode
        final added = await repo.addBranch(
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
        );
        _showSuccessSnackBar('Branch added: ${added.name}');
        setState(() {
          _hasChanges = true;
        });
      }

      // Reset fields
      _nameController.clear();
      _addressController.clear();
      _phoneController.clear();
      await _fetchBranches();
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDelete(Branch branch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Branch',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${branch.name}"?',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await sl<BranchRepository>().deleteBranch(branch.id);
      _showSuccessSnackBar('Branch "${branch.name}" deleted');
      setState(() {
        _hasChanges = true;
        if (_editingBranch?.id == branch.id) {
          _editingBranch = null;
          _nameController.clear();
          _addressController.clear();
          _phoneController.clear();
        }
      });
      await _fetchBranches();
    } catch (e) {
      _showErrorSnackBar(
        'Could not delete branch. It may be linked to existing sessions. Detail: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startEditing(Branch branch) {
    setState(() {
      _editingBranch = branch;
      _nameController.text = branch.name;
      _addressController.text = branch.address ?? '';
      _phoneController.text = branch.phone ?? '';
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingBranch = null;
      _nameController.clear();
      _addressController.clear();
      _phoneController.clear();
    });
  }

  Widget _buildCompactFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: EColorConstants.authTextDarkBrown,
        fontFamily: 'Poppins',
      ),
    );
  }

  InputDecoration _compactInputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 12,
        color: EColorConstants.authPlaceholderGray,
        fontFamily: 'Poppins',
      ),
      prefixIcon: Icon(
        prefixIcon,
        size: 18,
        color: EColorConstants.authPlaceholderGray,
      ),
      filled: true,
      fillColor: EColorConstants.authFieldBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: EColorConstants.authFieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: EColorConstants.authFieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: EColorConstants.primaryColor,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context, _hasChanges),
            icon: const Icon(Icons.close, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _editingBranch != null ? 'Edit Branch' : 'Manage Branches',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                color: EColorConstants.authTextDarkBrown,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompactFieldLabel(_editingBranch != null ? 'Edit Branch Name *' : 'New Branch Name *'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      decoration: _compactInputDecoration(
                        hint: 'Enter branch name',
                        prefixIcon: Iconsax.building,
                      ),
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) return 'Branch name is required';
                        if (trimmed.length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildCompactFieldLabel('Address (optional)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _addressController,
                      decoration: _compactInputDecoration(
                        hint: 'Enter address',
                        prefixIcon: Iconsax.location,
                      ),
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    _buildCompactFieldLabel('Phone (optional)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _compactInputDecoration(
                        hint: 'Enter phone number',
                        prefixIcon: Iconsax.call,
                      ),
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (_editingBranch != null) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSaving ? null : _cancelEditing,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: EColorConstants.authPlaceholderGray),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                  color: EColorConstants.authTextDarkBrown,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _handleSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: EColorConstants.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _editingBranch != null ? 'Update' : 'Add Branch',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: EColorConstants.authFieldBorder),
              const SizedBox(height: 8),
              const Text(
                'Existing Branches',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  color: EColorConstants.authTextDarkBrown,
                ),
              ),
              const SizedBox(height: 8),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(color: EColorConstants.primaryColor),
                  ),
                )
              else if (_branches.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text(
                      'No branches available.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: EColorConstants.authPlaceholderGray,
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _branches.length,
                  itemBuilder: (context, index) {
                    final branch = _branches[index];
                    final isCurrentEditing = _editingBranch?.id == branch.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCurrentEditing
                            ? EColorConstants.primaryColor.withOpacity(0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrentEditing
                              ? EColorConstants.primaryColor
                              : EColorConstants.authFieldBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  branch.name,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: isCurrentEditing
                                        ? EColorConstants.primaryColor
                                        : EColorConstants.authTextDarkBrown,
                                  ),
                                ),
                                if (branch.address != null && branch.address!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      branch.address!,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 10,
                                        color: EColorConstants.authPlaceholderGray,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _startEditing(branch),
                            icon: const Icon(Iconsax.edit, size: 16),
                            color: EColorConstants.authPlaceholderGray,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _handleDelete(branch),
                            icon: const Icon(Iconsax.trash, size: 16),
                            color: Colors.redAccent,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
