import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/features/admin/data/models/branch_model.dart';
import 'package:prince_academy/features/admin/data/models/coach_with_sessions.dart';
import 'package:prince_academy/features/admin/data/models/session_draft.dart';
import 'package:prince_academy/features/admin/data/repositories/branch_repository.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/presentation/widgets/branch_selector_field.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_dropdown_field.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_text_field.dart';
import 'package:prince_academy/features/admin/presentation/widgets/session_draft_row.dart';
import 'package:prince_academy/features/admin/presentation/widgets/session_frequency_selector.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/admin/presentation/widgets/branch_management_dialog.dart';

class EditSessionPage extends StatefulWidget {
  final CoachSessionModel session;

  const EditSessionPage({
    super.key,
    required this.session,
  });

  @override
  State<EditSessionPage> createState() => _EditSessionPageState();
}

class _EditSessionPageState extends State<EditSessionPage> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedTimeSlot;
  late final TextEditingController _priceController;
  late int _sessionsPerWeek;
  late List<SessionSlot> _sessionSlots;
  String? _selectedBranchId;
  List<Branch> _branches = [];
  bool _isLoadingBranches = false;
  bool _isSaving = false;

  static const _weekDays = SessionDraft.weekDays;
  static const _classTypes = SessionDraft.classTypes;

  @override
  void initState() {
    super.initState();
    _selectedTimeSlot = widget.session.timeSlots.isNotEmpty
        ? widget.session.timeSlots.first
        : SessionDraft.defaultTimeSlot;
    _priceController = TextEditingController(
      text: widget.session.pricePerSession.toStringAsFixed(0),
    );
    _sessionsPerWeek = widget.session.sessionsPerWeek;

    // Convert coach session days & types to SessionSlot list
    final slots = CoachWithSessions.sessionSlotsFor(widget.session);
    _sessionSlots = slots
        .map((s) => SessionSlot(day: s.day == '—' ? SessionSlot.defaultDay : s.day, classType: s.classType))
        .toList();

    // Ensure slot length matches sessionsPerWeek
    if (_sessionSlots.length != _sessionsPerWeek) {
      _sessionSlots = SessionDraft.resizeSlots(_sessionSlots, _sessionsPerWeek);
    }

    _selectedBranchId = widget.session.branchId;
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    setState(() => _isLoadingBranches = true);
    try {
      final branches = await sl<BranchRepository>().getAllBranches();
      if (!mounted) return;
      setState(() {
        _branches = branches;
        if (_selectedBranchId == null && widget.session.branchName != null) {
          for (final branch in branches) {
            if (branch.name == widget.session.branchName) {
              _selectedBranchId = branch.id;
              break;
            }
          }
        }
        if (_selectedBranchId == null && branches.isNotEmpty) {
          _selectedBranchId = branches.first.id;
        }
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to load branches: $e', Colors.redAccent);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingBranches = false);
      }
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _showAddBranchDialog() async {
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => const BranchManagementDialog(),
    );

    await _fetchBranches();
  }

  void _onSessionsPerWeekChanged(int count) {
    setState(() {
      _sessionsPerWeek = count;
      _sessionSlots = SessionDraft.resizeSlots(_sessionSlots, count);
    });
  }

  void _updateSessionSlot(int index, SessionSlot slot) {
    setState(() {
      _sessionSlots[index] = slot;
    });
  }

  Future<void> _handleSaveChanges() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    for (int i = 0; i < _sessionSlots.length; i++) {
      final slot = _sessionSlots[i];
      if (slot.day.isEmpty) {
        _showSnackBar('Session ${i + 1}: please select a day.', Colors.orange);
        return;
      }
      if (slot.classType.isEmpty) {
        _showSnackBar('Session ${i + 1}: please select a class type.', Colors.orange);
        return;
      }
    }

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    if (price <= 0) {
      _showSnackBar('Enter a valid price greater than 0', Colors.orange);
      return;
    }

    if (_selectedBranchId == null) {
      _showSnackBar('Please select a branch', Colors.orange);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final days = _sessionSlots.map((s) => s.day).toList();
      final classTypes = _sessionSlots.map((s) => s.classType).toList();

      await sl<CoachRepository>().updateSession(
        sessionId: widget.session.id,
        branchId: _selectedBranchId,
        timeSlot: _selectedTimeSlot,
        pricePerSession: price,
        sessionsPerWeek: _sessionsPerWeek,
        days: days,
        classTypes: classTypes,
      );

      _showSnackBar('Session updated successfully!', Colors.green);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showSnackBar('Failed to update session: $e', Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColorConstants.authFieldBackground,
      appBar: AppBar(
        title: const Text(
          'Edit Session',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: EColorConstants.authTextDarkBrown,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: EColorConstants.authTextDarkBrown, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: EColorConstants.authCardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: EColorConstants.primaryColor.withOpacity(0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Coach',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: EColorConstants.authTextDarkBrown,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Disabled coach field displaying coach name and image
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: EColorConstants.authFieldBackground.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: EColorConstants.authFieldBorder),
                      ),
                      child: Row(
                        children: [
                          CoachAvatar(
                            coachName: widget.session.coachName ?? 'Coach',
                            photoUrl: widget.session.coachPhotoUrl,
                            size: 36,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.session.coachName ?? 'Unknown Coach',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: EColorConstants.authTextDarkBrown,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: EColorConstants.authPlaceholderGray,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    BranchSelectorField(
                      branches: _branches,
                      selectedBranchId: _selectedBranchId,
                      isLoading: _isLoadingBranches,
                      onChanged: (value) {
                        setState(() => _selectedBranchId = value);
                      },
                      onAddBranch: _showAddBranchDialog,
                    ),
                    const SizedBox(height: 20),
                    AdminDropdownField<String>(
                      label: 'Time Slot',
                      value: _selectedTimeSlot,
                      items: SessionDraft.presetTimeSlots,
                      itemLabel: (item) => item,
                      prefixIcon: Iconsax.clock,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedTimeSlot = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    AdminTextField(
                      label: 'Price per Session (EGP)',
                      hint: 'Enter price',
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        final parsed = double.tryParse(value?.trim() ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid price greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SessionsPerWeekDropdown(
                      selectedCount: _sessionsPerWeek,
                      onChanged: _onSessionsPerWeekChanged,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Session Details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: EColorConstants.authTextDarkBrown,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_sessionSlots.length, (index) {
                      return SessionDraftRow(
                        index: index,
                        slot: _sessionSlots[index],
                        weekDays: _weekDays,
                        classTypes: _classTypes,
                        onChanged: (slot) => _updateSessionSlot(index, slot),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSaveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EColorConstants.primaryColor,
                    disabledBackgroundColor: EColorConstants.authPlaceholderGray,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
