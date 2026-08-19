import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/features/admin/data/models/branch_model.dart';
import 'package:prince_academy/features/admin/data/models/coach_model.dart';
import 'package:prince_academy/features/admin/data/models/session_conflict_info.dart';
import 'package:prince_academy/features/admin/data/models/session_draft.dart';
import 'package:prince_academy/features/admin/data/repositories/branch_repository.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/admin_home/admin_home_bloc.dart';
import 'package:prince_academy/features/admin/presentation/bloc/admin_home/admin_home_event.dart';
import 'package:prince_academy/features/admin/presentation/bloc/admin_home/admin_home_state.dart';
import 'package:prince_academy/features/admin/presentation/helpers/admin_session_form_helper.dart';
import 'package:prince_academy/features/admin/presentation/helpers/session_conflict_detector.dart';
import 'package:prince_academy/features/admin/presentation/pages/admin_create_coach_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/all_schedules_page.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_autocomplete_field.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_form_styles.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_searchable_dropdown_field.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_smooth_scroll.dart';
import 'package:prince_academy/features/admin/presentation/widgets/branch_management_dialog.dart';
import 'package:prince_academy/features/admin/presentation/widgets/create_choice_chips.dart';
import 'package:prince_academy/features/admin/presentation/widgets/session_card.dart';
import 'package:prince_academy/features/admin/presentation/widgets/session_conflict_dialog.dart';

class AdminCreateSessionPage extends StatefulWidget {
  const AdminCreateSessionPage({
    super.key,
    this.initialDraft,
  });

  final SessionDraft? initialDraft;

  static Future<void> open(
    BuildContext context, {
    SessionDraft? initialDraft,
  }) {
    final bloc = context.read<AdminHomeBloc>();
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: AdminCreateSessionPage(initialDraft: initialDraft),
        ),
      ),
    );
  }

  @override
  State<AdminCreateSessionPage> createState() => _AdminCreateSessionPageState();
}

class _AdminCreateSessionPageState extends State<AdminCreateSessionPage> {
  static const _totalSteps = 3;

  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _pageController = PageController();

  int _currentStep = 0;

  String? _selectedCoachId;
  String? _selectedBranchId;
  List<Branch> _branches = [];
  bool _isLoadingBranches = false;
  String _selectedTimeSlot = SessionDraft.defaultTimeSlot;
  int _selectedDurationMinutes = SessionDraft.defaultDurationMinutes;
  String _classType = SessionSlot.defaultClassType;
  List<SessionSlot> _sessionSlots = [SessionSlot.initial()];
  bool _customizePerDay = true;
  String? _coachError;
  String? _branchError;
  String? _daysError;
  String? _priceError;
  bool _hasAppliedInitialDefaults = false;
  bool _formTouched = false;

  Set<String> get _selectedDays =>
      _sessionSlots.map((slot) => slot.day).toSet();

  @override
  void initState() {
    super.initState();
    _fetchBranches();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.initialDraft != null) {
        _applySessionSnapshot(
          AdminSessionFormSnapshot.fromDraft(widget.initialDraft!),
          overrideCustomizePerDay: true,
        );
        _formTouched = true;
        _hasAppliedInitialDefaults = true;
        return;
      }
      _maybeApplyInitialDefaults(context.read<AdminHomeBloc>().state);
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchBranches() async {
    setState(() => _isLoadingBranches = true);
    try {
      final branches = await sl<BranchRepository>().getAllBranches();
      if (!mounted) return;
      setState(() {
        _branches = branches;
        if (branches.length == 1) {
          _selectedBranchId = branches.first.id;
        } else if (_selectedBranchId == null && branches.isNotEmpty) {
          _selectedBranchId = branches.first.id;
        }
      });
      _maybeApplyInitialDefaults(context.read<AdminHomeBloc>().state);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load branches: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingBranches = false);
    }
  }

  void _maybeApplyInitialDefaults(AdminHomeState admin) {
    if (_hasAppliedInitialDefaults || _formTouched) return;
    if (admin.isLoadingCoaches ||
        admin.isLoadingSessions ||
        _isLoadingBranches) {
      return;
    }

    final snapshot = AdminSessionFormHelper.resolveInitial(
      coaches: admin.coaches,
      branches: _branches,
      sessions: admin.sessions,
      lastDraft: admin.lastSessionDraft,
      selectedCoachId: _selectedCoachId,
      selectedBranchId: _selectedBranchId,
      timeSlot: _selectedTimeSlot,
      durationMinutes: _selectedDurationMinutes,
      priceText: _priceController.text,
      sessionsPerWeek: _sessionSlots.length,
      slots: _sessionSlots,
    );
    _applySessionSnapshot(snapshot);
    _hasAppliedInitialDefaults = true;
  }

  void _applySessionSnapshot(AdminSessionFormSnapshot snapshot,
      {bool overrideCustomizePerDay = false}) {
    final slots = snapshot.slots.isEmpty
        ? [SessionSlot.initial()]
        : List<SessionSlot>.from(snapshot.slots);
    final types = slots.map((slot) => slot.classType).toSet();
    setState(() {
      _selectedCoachId = snapshot.coachId;
      _selectedBranchId = snapshot.branchId;
      _selectedTimeSlot = snapshot.timeSlot;
      _selectedDurationMinutes = snapshot.durationMinutes;
      _sessionSlots = slots;
      _classType = slots.first.classType;
      if (overrideCustomizePerDay) _customizePerDay = types.length > 1;
      _priceController.text = snapshot.priceText;
      _coachError = null;
      _branchError = null;
      _daysError = null;
      _priceError = null;
    });
  }

  void _onCoachChanged(String? coachId, AdminHomeState admin) {
    if (coachId == null) return;
    final snapshot = AdminSessionFormHelper.forCoachChange(
      coachId: coachId,
      coaches: admin.coaches,
      sessions: admin.sessions,
      current: AdminSessionFormSnapshot(
        coachId: _selectedCoachId,
        branchId: _selectedBranchId,
        timeSlot: _selectedTimeSlot,
        durationMinutes: _selectedDurationMinutes,
        priceText: _priceController.text,
        sessionsPerWeek: _sessionSlots.length,
        slots: _sessionSlots,
      ),
      lastDraft: admin.lastSessionDraft,
      singleBranchId: _branches.length == 1 ? _branches.first.id : null,
    );
    setState(() {
      _formTouched = true;
      _coachError = null;
    });
    _applySessionSnapshot(snapshot);
  }

  void _toggleDay(String day) {
    setState(() {
      _formTouched = true;
      _daysError = null;
      final existing = [
        for (final slot in _sessionSlots)
          if (slot.day == day) slot,
      ];
      if (existing.isNotEmpty) {
        if (_sessionSlots.length == 1) return;
        _sessionSlots = [
          for (final slot in _sessionSlots)
            if (slot.day != day) slot,
        ];
      } else {
        _sessionSlots = [
          ..._sessionSlots,
          SessionSlot(day: day, classType: _classType),
        ]..sort(
            (a, b) => SessionDraft.weekDays
                .indexOf(a.day)
                .compareTo(SessionDraft.weekDays.indexOf(b.day)),
          );
      }
    });
  }

  void _setClassType(String type) {
    setState(() {
      _formTouched = true;
      _classType = type;
      if (!_customizePerDay) {
        _sessionSlots = [
          for (final slot in _sessionSlots)
            slot.copyWith(classType: type),
        ];
      }
    });
  }

  void _updateSlotType(int index, String type) {
    setState(() {
      _formTouched = true;
      _sessionSlots[index] = _sessionSlots[index].copyWith(classType: type);
    });
  }

  Future<void> _showAddBranchDialog() async {
    await showDialog<bool>(
      context: context,
      builder: (_) => const BranchManagementDialog(),
    );
    await _fetchBranches();
    if (mounted) {
      context.read<AdminHomeBloc>().add(const RefreshSessions());
    }
  }

  bool _validateStep(int step) {
    if (step == 0) {
      String? coachErr;
      String? branchErr;
      if (_selectedCoachId == null) coachErr = 'Please select a coach';
      if (_selectedBranchId == null) branchErr = 'Please select a branch';
      setState(() {
        _coachError = coachErr;
        _branchError = branchErr;
      });
      return coachErr == null && branchErr == null;
    }
    if (step == 1) {
      String? daysErr;
      if (_sessionSlots.isEmpty) daysErr = 'Pick at least one day';
      setState(() => _daysError = daysErr);
      return daysErr == null;
    }
    return true;
  }

  bool _validateFinal() {
    var isValid = true;
    String? coachError;
    String? branchError;
    String? daysError;
    String? priceError;

    if (_selectedCoachId == null) {
      coachError = 'Please select a coach';
      isValid = false;
    }
    if (_selectedBranchId == null) {
      branchError = 'Please select a branch';
      isValid = false;
    }
    if (_sessionSlots.isEmpty) {
      daysError = 'Pick at least one day';
      isValid = false;
    }
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    if (price <= 0) {
      priceError = 'Enter a valid price greater than 0';
      isValid = false;
    }

    setState(() {
      _coachError = coachError;
      _branchError = branchError;
      _daysError = daysError;
      _priceError = priceError;
    });

    return isValid && (_formKey.currentState?.validate() ?? false);
  }

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = step);
  }

  void _handleNext(AdminHomeState admin) {
    if (!_validateStep(_currentStep)) return;
    if (_currentStep < _totalSteps - 1) {
      _goToStep(_currentStep + 1);
    }
  }

  void _handleBack() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleSave() async {
    final admin = context.read<AdminHomeBloc>().state;
    if (admin.coaches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a coach first before scheduling sessions.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (!_validateFinal()) return;

    final draft = AdminSessionFormSnapshot(
      coachId: _selectedCoachId,
      branchId: _selectedBranchId,
      timeSlot: _selectedTimeSlot,
      durationMinutes: _selectedDurationMinutes,
      priceText: _priceController.text,
      sessionsPerWeek: _sessionSlots.length,
      slots: _sessionSlots,
    ).toDraft();

    SessionConflictInfo? conflict = SessionConflictDetector.find(
      draft: draft,
      existingSessions: admin.sessions,
    );

    try {
      final remoteConflict =
          await sl<CoachRepository>().findSessionConflict(draft);
      if (remoteConflict != null) conflict = remoteConflict;
    } catch (e) {
      if (conflict == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not verify schedule conflicts: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
    }

    if (!mounted) return;

    if (conflict != null) {
      final createAnyway = await SessionConflictDialog.show(
        context,
        conflict: conflict,
      );
      if (!createAnyway) return;
    }

    if (!mounted) return;
    context.read<AdminHomeBloc>().add(SaveSessionSubmitted(draft));
    FocusScope.of(context).unfocus();
  }

  void _onSessionSaved(AdminHomeState admin) {
    final snapshot = AdminSessionFormHelper.afterSuccessfulSave(
      savedDraft: admin.lastSessionDraft ?? SessionDraft.initial(),
      keepValues: false,
    );
    _applySessionSnapshot(snapshot);
    _formTouched = false;
    _goToStep(0);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminHomeBloc, AdminHomeState>(
      listenWhen: (prev, next) => prev.message != next.message,
      listener: (context, state) {
        final message = state.message;
        if (message == null) return;

        if (state.messageType == AdminHomeMessageType.success &&
            message.contains('Session saved')) {
          _onSessionSaved(state);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Session created'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'View all',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AllSchedulesPage(),
                    ),
                  );
                },
              ),
            ),
          );
        } else if (state.messageType == AdminHomeMessageType.error &&
            (message.contains('Failed to save session') ||
                message.contains('Failed to load'))) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else {
          return;
        }

        context.read<AdminHomeBloc>().add(const ClearAdminHomeMessage());
      },
      builder: (context, admin) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _maybeApplyInitialDefaults(admin);
        });

        final hasCoaches = admin.coaches.isNotEmpty;
        CoachModel? selectedCoach;
        for (final coach in admin.coaches) {
          if (coach.id == _selectedCoachId) {
            selectedCoach = coach;
            break;
          }
        }
        Branch? selectedBranch;
        for (final branch in _branches) {
          if (branch.id == _selectedBranchId) {
            selectedBranch = branch;
            break;
          }
        }
        final recentPriceOptions = admin.recentPrices
            .map(
              (price) => price.toStringAsFixed(
                price == price.roundToDouble() ? 0 : 2,
              ),
            )
            .toList();
        final showBranchField = _branches.length != 1;

        final stepTitles = ['Coach & Branch', 'Schedule', 'Class & Price'];

        return Scaffold(
          backgroundColor: EColorConstants.authFieldBackground,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: BackButton(
              color: EColorConstants.authTextDarkBrown,
              onPressed: _handleBack,
            ),
            title: Column(
              children: [
                const Text(
                  'New session',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: EColorConstants.authTextDarkBrown,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  stepTitles[_currentStep],
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: EColorConstants.authPlaceholderGray,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: _StepIndicator(
                  totalSteps: _totalSteps,
                  currentStep: _currentStep,
                ),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentStep = index),
                    children: [
                      // Step 1 — Coach & Branch
                      AdminSmoothScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!hasCoaches)
                              _CoachRequiredBanner(
                                onAddCoach: () =>
                                    AdminCreateCoachPage.open(context),
                              ),
                            AdminFormStyles.fieldLabel('Coach'),
                            const SizedBox(height: 8),
                            AdminSearchableDropdownField<CoachModel>(
                              value: hasCoaches ? selectedCoach : null,
                              items: admin.coaches,
                              itemLabel: (coach) => coach.name,
                              searchText: (coach) =>
                                  '${coach.name} ${coach.specialty}',
                              errorText: _coachError,
                              enabled: hasCoaches,
                              hintText: 'Select coach',
                              selectedBuilder: (coach) =>
                                  SessionCoachDropdownTile(
                                name: coach.name,
                                photoUrl: coach.photoUrl,
                              ),
                              itemBuilder: (coach) => SessionCoachDropdownTile(
                                name: coach.name,
                                photoUrl: coach.photoUrl,
                              ),
                              onChanged: hasCoaches
                                  ? (coach) =>
                                      _onCoachChanged(coach?.id, admin)
                                  : (_) {},
                            ),
                            if (showBranchField) ...[
                              const SizedBox(height: 20),
                              AdminFormStyles.fieldLabel('Branch'),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _isLoadingBranches
                                        ? const Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 12),
                                            child: Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            ),
                                          )
                                        : AdminSearchableDropdownField<Branch>(
                                            value: selectedBranch,
                                            items: _branches,
                                            itemLabel: (branch) => branch.name,
                                            prefixIcon:
                                                Icons.location_city_outlined,
                                            errorText: _branchError,
                                            enabled: hasCoaches &&
                                                _branches.isNotEmpty,
                                            hintText: 'Select branch',
                                            onChanged: hasCoaches &&
                                                    _branches.isNotEmpty
                                                ? (branch) {
                                                    setState(() {
                                                      _formTouched = true;
                                                      _selectedBranchId =
                                                          branch?.id;
                                                      _branchError = null;
                                                    });
                                                  }
                                                : (_) {},
                                          ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Material(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      child: InkWell(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        onTap: _showAddBranchDialog,
                                        child: const Icon(
                                          Icons.add_business_outlined,
                                          size: 22,
                                          color: EColorConstants.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_branches.isEmpty &&
                                  !_isLoadingBranches) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'No branches yet. Tap + to add one.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade700,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),

                      // Step 2 — Schedule
                      AdminSmoothScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AdminFormStyles.fieldLabel('Days'),
                            const SizedBox(height: 8),
                            WeekDayChipRow(
                              selectedDays: _selectedDays,
                              enabled: hasCoaches,
                              onToggle: _toggleDay,
                            ),
                            if (_daysError != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _daysError!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            AdminFormStyles.fieldLabel('Time · Duration'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: AdminSearchableDropdownField<String>(
                                    value: _selectedTimeSlot,
                                    items: SessionDraft.presetTimeSlots,
                                    itemLabel: (item) => item,
                                    prefixIcon: Iconsax.clock,
                                    enabled: hasCoaches,
                                    hintText: 'Time',
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() {
                                        _formTouched = true;
                                        _selectedTimeSlot = value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: AdminSearchableDropdownField<int>(
                                    value: SessionDraft.presetDurations
                                            .contains(_selectedDurationMinutes)
                                        ? _selectedDurationMinutes
                                        : SessionDraft.defaultDurationMinutes,
                                    items: SessionDraft.presetDurations,
                                    itemLabel: SessionDraft.durationLabel,
                                    prefixIcon: Iconsax.timer_1,
                                    enabled: hasCoaches,
                                    hintText: 'Duration',
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() {
                                        _formTouched = true;
                                        _selectedDurationMinutes = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Step 3 — Class type & Price
                      AdminSmoothScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AdminFormStyles.fieldLabel('Class type'),
                            const SizedBox(height: 12),
                            _PerDayToggleRow(
                              value: _customizePerDay,
                              enabled: hasCoaches,
                              onChanged: (val) {
                                setState(() {
                                  _customizePerDay = val;
                                  if (!val) {
                                    _sessionSlots = [
                                      for (final slot in _sessionSlots)
                                        slot.copyWith(classType: _classType),
                                    ];
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            if (!_customizePerDay)
                              CreateChoiceChipWrap<String>(
                                items: SessionDraft.classTypes,
                                selected: _classType,
                                onSelected: _setClassType,
                                labelOf: (type) => type,
                              )
                            else
                              ..._sessionSlots.asMap().entries.map((entry) {
                                final index = entry.key;
                                final slot = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: AdminSearchableDropdownField<String>(
                                    label: WeekDayChipRow
                                            .shortLabels[slot.day] ??
                                        slot.day,
                                    value: slot.classType,
                                    items: SessionDraft.classTypes,
                                    itemLabel: (item) => item,
                                    prefixIcon: Iconsax.category,
                                    enabled: hasCoaches,
                                    hintText: 'Class type',
                                    onChanged: (value) {
                                      if (value != null) {
                                        _updateSlotType(index, value);
                                      }
                                    },
                                  ),
                                );
                              }),
                            const SizedBox(height: 20),
                            AdminAutocompleteField(
                              label: 'Price',
                              hint: '200',
                              suffixText: 'EGP',
                              controller: _priceController,
                              options: recentPriceOptions,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (value) {
                                final parsed =
                                    double.tryParse(value?.trim() ?? '');
                                if (parsed == null || parsed <= 0) {
                                  return 'Enter a valid price greater than 0';
                                }
                                return null;
                              },
                              onChanged: (_) {
                                setState(() {
                                  _formTouched = true;
                                  _priceError = null;
                                });
                              },
                            ),
                            if (_priceError != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _priceError!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: _currentStep < _totalSteps - 1
                  ? SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            hasCoaches ? () => _handleNext(admin) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EColorConstants.primaryColor,
                          disabledBackgroundColor:
                              EColorConstants.authPlaceholderGray,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Next',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (!admin.isSavingSession && hasCoaches)
                            ? _handleSave
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EColorConstants.primaryColor,
                          disabledBackgroundColor:
                              EColorConstants.authPlaceholderGray,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: admin.isSavingSession
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Create session',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.totalSteps,
    required this.currentStep,
  });

  final int totalSteps;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < totalSteps; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: i <= currentStep
                    ? EColorConstants.primaryColor
                    : const Color(0xFFE8DDD0),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PerDayToggleRow extends StatelessWidget {
  const _PerDayToggleRow({
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DDD0)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: EColorConstants.primaryColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Different type per day',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: enabled
                        ? EColorConstants.authTextDarkBrown
                        : EColorConstants.authPlaceholderGray,
                  ),
                ),
                Text(
                  value
                      ? 'Each day has its own class type'
                      : 'All days share the same type',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'Poppins',
                    color: EColorConstants.authPlaceholderGray,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: EColorConstants.primaryColor,
          ),
        ],
      ),
    );
  }
}

class _CoachRequiredBanner extends StatelessWidget {
  const _CoachRequiredBanner({required this.onAddCoach});

  final VoidCallback onAddCoach;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Iconsax.info_circle, size: 18, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Add a coach first before scheduling sessions.',
              style: TextStyle(fontSize: 12, fontFamily: 'Poppins'),
            ),
          ),
          TextButton(
            onPressed: onAddCoach,
            child: const Text(
              'Add',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
