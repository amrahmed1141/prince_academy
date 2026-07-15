import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prince_academy/core/cache/image_cache.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/coach_photo_helper.dart';
import 'package:prince_academy/core/widgets/shimmer_widgets.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/features/admin/data/models/branch_model.dart';
import 'package:prince_academy/features/admin/data/models/coach_model.dart';
import 'package:prince_academy/features/admin/data/models/coach_with_sessions.dart';
import 'package:prince_academy/features/admin/data/models/session_draft.dart';
import 'package:prince_academy/features/admin/data/models/session_draft_mapper.dart';
import 'package:prince_academy/features/admin/data/models/session_conflict_info.dart';
import 'package:prince_academy/features/admin/data/repositories/branch_repository.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/admin_home/admin_home_bloc.dart';
import 'package:prince_academy/features/admin/presentation/bloc/admin_home/admin_home_event.dart';
import 'package:prince_academy/features/admin/presentation/bloc/admin_home/admin_home_state.dart';
import 'package:prince_academy/features/admin/presentation/helpers/admin_session_form_helper.dart';
import 'package:prince_academy/features/admin/presentation/helpers/session_conflict_detector.dart';
import 'package:prince_academy/features/admin/presentation/pages/admin_profile.dart';
import 'package:prince_academy/features/admin/presentation/pages/edit_coach_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/edit_session_page.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_autocomplete_field.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_dashed_upload.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_dropdown_field.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_searchable_dropdown_field.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_form_styles.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_header.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_section_card.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_smooth_scroll.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_tab_layout.dart';
import 'package:prince_academy/features/admin/presentation/widgets/branch_management_dialog.dart';
import 'package:prince_academy/features/admin/presentation/widgets/class_type_filter_dropdown.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_card.dart';
import 'package:prince_academy/features/admin/presentation/widgets/session_card.dart';
import 'package:prince_academy/features/admin/presentation/widgets/session_conflict_dialog.dart';
import 'package:prince_academy/features/admin/presentation/widgets/session_draft_row.dart';
import 'package:prince_academy/features/admin/presentation/widgets/session_frequency_selector.dart';
import 'package:prince_academy/features/admin/presentation/widgets/specialty_chip.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_home/admin_empty_state.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

class AdminAddInfoPage extends StatefulWidget {
  const AdminAddInfoPage({super.key});

  @override
  State<AdminAddInfoPage> createState() => _AdminAddInfoPageState();
}

class _AdminAddInfoPageState extends State<AdminAddInfoPage> {
  static const _coachSpecialties = [
    'Muay Thai',
    'BJJ',
    'Wrestling',
    'Boxing',
    'MMA',
    'Strength & Conditioning',
  ];

  final _tabLayoutKey = GlobalKey<AdminTabLayoutState>();

  // Coach Form Controllers
  final _coachNameController = TextEditingController();
  late final FocusNode _coachNameFocusNode;
  String _selectedCoachSpecialty = 'Muay Thai';
  String? _selectedCoachImagePath;

  static const _weekDays = SessionDraft.weekDays;
  static const _classTypes = SessionDraft.classTypes;

  final _sessionFormKey = GlobalKey<FormState>();

  // Session Form State
  String? _selectedSessionCoachId;
  String? _selectedBranchId;
  List<Branch> _branches = [];
  bool _isLoadingBranches = false;
  String _selectedTimeSlot = SessionDraft.defaultTimeSlot;
  final _priceController = TextEditingController();
  int _sessionsPerWeek = 1;
  List<SessionSlot> _sessionSlots = [SessionSlot.initial()];
  String? _coachError;
  String? _branchError;
  String? _timeSlotError;
  String? _priceError;

  // Coaches list filter
  String _coachFilter = 'All Coaches';
  String _sessionFilter = 'All Classes';
  bool _hasAppliedInitialSessionDefaults = false;
  bool _sessionFormTouched = false;

  @override
  void initState() {
    super.initState();
    _coachNameFocusNode = FocusNode();
    _fetchBranches();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncCoachSelection());
  }

  void _syncCoachSelection() {
    if (!mounted) return;
    final admin = context.read<AdminHomeBloc>().state;
    final coaches = admin.coaches;
    if (_selectedSessionCoachId == null && coaches.isNotEmpty) {
      setState(() => _selectedSessionCoachId = coaches.first.id);
    }
    _maybeApplyInitialSessionDefaults(admin);
  }

  void _maybeApplyInitialSessionDefaults(AdminHomeState admin) {
    if (_hasAppliedInitialSessionDefaults || _sessionFormTouched) return;
    if (admin.isLoadingCoaches || admin.isLoadingSessions || _isLoadingBranches) {
      return;
    }

    final snapshot = AdminSessionFormHelper.resolveInitial(
      coaches: admin.coaches,
      branches: _branches,
      sessions: admin.sessions,
      lastDraft: admin.lastSessionDraft,
      selectedCoachId: _selectedSessionCoachId,
      selectedBranchId: _selectedBranchId,
      timeSlot: _selectedTimeSlot,
      priceText: _priceController.text,
      sessionsPerWeek: _sessionsPerWeek,
      slots: _sessionSlots,
    );

    _applySessionSnapshot(snapshot);
    _hasAppliedInitialSessionDefaults = true;
  }

  void _applySessionSnapshot(AdminSessionFormSnapshot snapshot) {
    final normalizedSlots =
        SessionDraft.resizeSlots(snapshot.slots, snapshot.sessionsPerWeek);
    setState(() {
      _selectedSessionCoachId = snapshot.coachId;
      _selectedBranchId = snapshot.branchId;
      _selectedTimeSlot = snapshot.timeSlot;
      _sessionsPerWeek = snapshot.sessionsPerWeek;
      _sessionSlots = normalizedSlots;
      _priceController.text = snapshot.priceText;
      _coachError = null;
      _branchError = null;
      _timeSlotError = null;
      _priceError = null;
    });
  }

  void _onSessionCoachChanged(String? coachId, AdminHomeState admin) {
    if (coachId == null) return;
    final snapshot = AdminSessionFormHelper.forCoachChange(
      coachId: coachId,
      coaches: admin.coaches,
      sessions: admin.sessions,
      current: AdminSessionFormSnapshot(
        coachId: _selectedSessionCoachId,
        branchId: _selectedBranchId,
        timeSlot: _selectedTimeSlot,
        priceText: _priceController.text,
        sessionsPerWeek: _sessionsPerWeek,
        slots: _sessionSlots,
      ),
      lastDraft: admin.lastSessionDraft,
      singleBranchId: _branches.length == 1 ? _branches.first.id : null,
    );

    setState(() {
      _sessionFormTouched = true;
      _coachError = null;
    });
    _applySessionSnapshot(snapshot);
  }

  void _duplicateSessionGroup(CoachWithSessions group) {
    if (group.schedules.isEmpty) return;
    final draft = SessionDraftMapper.fromCoachSession(group.schedules.first);
    _applySessionSnapshot(AdminSessionFormSnapshot.fromDraft(draft));
    setState(() => _sessionFormTouched = true);
    _tabLayoutKey.currentState?.animateToTab(1);
    _showSnackBar('Session duplicated into the form', EColorConstants.primaryColor);
  }

  Future<void> _fetchBranches() async {
    setState(() => _isLoadingBranches = true);
    try {
      final branches = await sl<BranchRepository>().getAllBranches();
      if (mounted) {
        setState(() {
          _branches = branches;
          if (_selectedBranchId == null && branches.isNotEmpty) {
            _selectedBranchId = branches.first.id;
          }
        });
        _maybeApplyInitialSessionDefaults(context.read<AdminHomeBloc>().state);
      }
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

  Future<void> _showAddBranchDialog() async {
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => const BranchManagementDialog(),
    );

    await _fetchBranches();
    context.read<AdminHomeBloc>().add(const RefreshSessions());
  }

  Future<void> _pickCoachImage() async {
    debugPrint('pickCoachImage start');
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        debugPrint('pickCoachImage selected: ${image.path}');
        setState(() {
          _selectedCoachImagePath = image.path;
        });
      }
    } on MissingPluginException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Image picker not available. Please rebuild the app.'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to pick image: $e'),
        ));
      }
    }
  }

  Future<void> _handleAddCoach() async {
    final name = _coachNameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Please enter a coach name', Colors.orange);
      return;
    }

    context.read<AdminHomeBloc>().add(
          AddCoachSubmitted(
            name: name,
            specialty: _selectedCoachSpecialty,
            imagePath: _selectedCoachImagePath,
          ),
        );
  }

  bool _validateSessionForm() {
    var isValid = true;
    String? coachError;
    String? branchError;
    String? timeSlotError;
    String? priceError;

    if (_selectedSessionCoachId == null) {
      coachError = 'Please select a coach';
      isValid = false;
    }

    if (_selectedBranchId == null) {
      branchError = 'Please select a branch';
      isValid = false;
    }

    if (_selectedTimeSlot.isEmpty) {
      timeSlotError = 'Please select a time slot';
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
      _timeSlotError = timeSlotError;
      _priceError = priceError;
    });

    return isValid && (_sessionFormKey.currentState?.validate() ?? false);
  }

  Future<void> _handleSaveSession({bool addAnother = false}) async {
    if (context.read<AdminHomeBloc>().state.coaches.isEmpty) {
      _showSnackBar(
        'No coaches available. Please add a coach first.',
        Colors.orange,
      );
      return;
    }

    if (!_validateSessionForm()) return;

    for (int i = 0; i < _sessionSlots.length; i++) {
      final slot = _sessionSlots[i];
      if (slot.day.isEmpty) {
        _showSnackBar('Session ${i + 1}: please select a day.', Colors.orange);
        return;
      }
      if (slot.classType.isEmpty) {
        _showSnackBar(
          'Session ${i + 1}: please select a class type.',
          Colors.orange,
        );
        return;
      }
    }

    final draft = AdminSessionFormSnapshot(
      coachId: _selectedSessionCoachId,
      branchId: _selectedBranchId,
      timeSlot: _selectedTimeSlot,
      priceText: _priceController.text,
      sessionsPerWeek: _sessionsPerWeek,
      slots: _sessionSlots,
    ).toDraft();

    // Prefer already-loaded sessions (same data shown in Saved Sessions cards).
    final localConflict = SessionConflictDetector.find(
      draft: draft,
      existingSessions: context.read<AdminHomeBloc>().state.sessions,
    );

    SessionConflictInfo? conflict = localConflict;

    // Fall back to a fresh Supabase check if local list has no match.
    if (conflict == null) {
      try {
        conflict = await sl<CoachRepository>().findSessionConflict(draft);
      } catch (e) {
        if (mounted) {
          _showSnackBar(
            'Could not verify schedule conflicts: $e',
            Colors.redAccent,
          );
        }
        return;
      }
    }

    if (!mounted) return;

    if (conflict != null) {
      final createAnyway = await SessionConflictDialog.show(
        context,
        coachName: conflict.coachName,
      );
      if (!createAnyway) return;
    }

    if (!mounted) return;

    context.read<AdminHomeBloc>().add(
          SaveSessionSubmitted(draft, addAnother: addAnother),
        );
    FocusScope.of(context).unfocus();
  }

  void _onSessionSaved(AdminHomeState admin) {
    final snapshot = AdminSessionFormHelper.afterSuccessfulSave(
      savedDraft: admin.lastSessionDraft ?? SessionDraft.initial(),
      keepValues: admin.keepSessionFormAfterSave,
    );
    _applySessionSnapshot(snapshot);
    if (!admin.keepSessionFormAfterSave) {
      _sessionFormTouched = false;
      _hasAppliedInitialSessionDefaults = false;
      _maybeApplyInitialSessionDefaults(admin);
    }
  }

  void _onSessionsPerWeekChanged(int count) {
    setState(() {
      _sessionFormTouched = true;
      _sessionsPerWeek = count;
      _sessionSlots = SessionDraft.resizeSlots(_sessionSlots, count);
    });
  }

  void _updateSessionSlot(int index, SessionSlot slot) {
    setState(() {
      _sessionFormTouched = true;
      _sessionSlots[index] = slot;
    });
  }

  void _showDeleteSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleDeleteCoach(CoachModel coach) async {
    context.read<AdminHomeBloc>().add(DeleteCoachSubmitted(coach.id));
  }

  Future<void> _handleDeleteSessionSchedule(CoachWithSessions group) async {
    context.read<AdminHomeBloc>().add(
          DeleteSessionScheduleSubmitted(
            group.schedules.map((s) => s.id).toList(),
          ),
        );
  }

  void _navigateToEditCoach(CoachModel coach) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditCoachPage(coach: coach),
      ),
    );
    if (result == true) {
      context.read<AdminHomeBloc>().add(const RefreshCoaches(force: true));
      context.read<AdminHomeBloc>().add(const RefreshSessions());
    }
  }

  void _navigateToEditSession(CoachSessionModel session) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditSessionPage(session: session),
      ),
    );
    if (result == true) {
      context.read<AdminHomeBloc>().add(const RefreshSessions());
    }
  }



  List<CoachWithSessions> _groupedFilteredSessions(AdminHomeState admin) {
    final grouped = CoachWithSessions.group(_filteredSessions(admin));

    final photoByCoachId = <String, String>{
      for (final coach in admin.coaches)
        if (CoachPhotoHelper.normalize(coach.photoUrl) != null)
          coach.id: CoachPhotoHelper.normalize(coach.photoUrl)!,
    };

    return grouped.map((entry) {
      final resolvedPhoto =
          photoByCoachId[entry.coachId] ??
          CoachPhotoHelper.normalize(entry.photoUrl);
      if (resolvedPhoto == null || resolvedPhoto == entry.photoUrl) {
        return entry;
      }
      return CoachWithSessions(
        coachId: entry.coachId,
        branchId: entry.branchId,
        branchName: entry.branchName,
        name: entry.name,
        photoUrl: resolvedPhoto,
        schedules: entry.schedules,
      );
    }).toList();
  }

  void _precacheCoachPhotos(BuildContext context, AdminHomeState admin) {
    final urls = <String>{
      for (final coach in admin.coaches)
        if (CoachPhotoHelper.normalize(coach.photoUrl) != null)
          CoachPhotoHelper.normalize(coach.photoUrl)!,
      for (final session in admin.sessions)
        if (CoachPhotoHelper.normalize(session.coachPhotoUrl) != null)
          CoachPhotoHelper.normalize(session.coachPhotoUrl)!,
    };

    for (final url in urls) {
      if (CoachPhotoHelper.isLocalPath(url)) continue;
      precacheImage(AppImageCache.provider(url), context);
    }
  }

  String? _coachBranchLabel(CoachModel coach, AdminHomeState admin) {
    final branchNames = admin.sessions
        .where((session) => session.coachId == coach.id)
        .map((session) => session.branchName)
        .where((name) => name != null && name.trim().isNotEmpty)
        .map((name) => name!.trim())
        .toSet();

    if (branchNames.isEmpty) return coach.branchName;
    if (branchNames.length > 1) return 'Multiple Branches';
    return branchNames.first;
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
        ),
      );
    }
  }

  @override
  void dispose() {
    _coachNameController.dispose();
    _coachNameFocusNode.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // ---------- Build Methods ----------

  @override
  Widget build(BuildContext context) {
    final dark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return BlocConsumer<AdminHomeBloc, AdminHomeState>(
      listenWhen: (prev, next) =>
          prev.message != next.message ||
          prev.coaches != next.coaches ||
          prev.sessions != next.sessions,
      listener: (context, state) {
        _precacheCoachPhotos(context, state);

        final message = state.message;
        if (message == null) return;

        if (state.messageType == AdminHomeMessageType.success) {
          if (message.contains('Coach added')) {
            _coachNameController.clear();
            setState(() => _selectedCoachImagePath = null);
            FocusScope.of(context).unfocus();
            _syncCoachSelection();
          } else if (message.contains('Session saved')) {
            _onSessionSaved(state);
          }
          _showSnackBar(message, Colors.green);
        } else if (state.messageType == AdminHomeMessageType.delete) {
          _showDeleteSnackBar(message);
        } else if (state.messageType == AdminHomeMessageType.error) {
          _showSnackBar(message, Colors.redAccent);
        }

        context.read<AdminHomeBloc>().add(const ClearAdminHomeMessage());
      },
      builder: (context, admin) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _maybeApplyInitialSessionDefaults(admin);
        });
        return SafeArea(
          child: Column(
            children: [
              AdminHeader(
                onAvatarTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminProfilePage(),
                    ),
                  );
                },
              ),
              Expanded(
                child: ScrollConfiguration(
                  behavior: const AdminSmoothScrollBehavior(),
                  child: AdminTabLayout(
                    key: _tabLayoutKey,
                    labels: const ['Add Coach', 'Sessions'],
                    children: [
                      _buildAddCoachTab(dark, admin),
                      _buildSessionsTab(dark, admin),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// -----------------------------------------------------------------
  /// TAB 1: ADD COACH
  /// -----------------------------------------------------------------
  Widget _buildAddCoachTab(bool dark, AdminHomeState admin) {
    final filteredCoaches = _coachFilter == 'All Coaches'
        ? admin.coaches
        : admin.coaches.where((c) => c.specialty == _coachFilter).toList();

    final filterOptions = <String>[
      'All Coaches',
      ...admin.coaches.map((c) => c.specialty).toSet(),
    ];

    return AdminSmoothScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAddCoachFormCard(
            isAddingCoach: admin.isAddingCoach,
            existingCoachNames: admin.coaches.map((coach) => coach.name).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Coaches',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: EColorConstants.authTextDarkBrown,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              SizedBox(
                width: 130,
                child: ClassTypeFilterDropdown(
                  value: filterOptions.contains(_coachFilter)
                      ? _coachFilter
                      : 'All Coaches',
                  options: filterOptions,
                  labelBuilder: (option) => option == 'All Coaches'
                      ? option
                      : SpecialtyChip.displayLabel(option),
                  onChanged: (value) {
                    setState(() => _coachFilter = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (admin.isLoadingCoaches)
            const CoachListShimmer(itemCount: 3)
          else if (filteredCoaches.isEmpty)
            AdminEmptyState(
              icon: Iconsax.people,
              message: admin.coaches.isEmpty
                  ? 'No coaches added yet.\nCreate your first coach above.'
                  : 'No coaches match this filter.',
            )
          else
            ...filteredCoaches.map((coach) {
              final coachSessionCount =
                  admin.sessions.where((s) => s.coachId == coach.id).length;
              return CoachListCard(
                coachId: coach.id,
                name: coach.name,
                specialty: coach.specialty,
                sessionCount: coachSessionCount,
                imagePath: coach.photoUrl,
                branchName: _coachBranchLabel(coach, admin),
                onEdit: () => _navigateToEditCoach(coach),
                onDelete: () => _handleDeleteCoach(coach),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAddCoachFormCard({
    required bool isAddingCoach,
    required List<String> existingCoachNames,
  }) {
    return AdminSectionCard(
      borderRadius: 28,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AdminFormStyles.sessionPanelFill,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.user,
                    size: 20,
                    color: EColorConstants.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Coach',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: EColorConstants.authTextDarkBrown,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        'Create profile to get started',
                        style: TextStyle(
                          fontSize: 12,
                          color: EColorConstants.authPlaceholderGray,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AdminDashedUpload(
              fullWidth: true,
              imagePath: _selectedCoachImagePath,
              onTap: _pickCoachImage,
            ),
            const SizedBox(height: 20),
            _buildCompactFieldLabel('Coach Name'),
            const SizedBox(height: 8),
            _buildCoachNameField(existingCoachNames),
            const SizedBox(height: 16),
            _buildCompactFieldLabel('Specialty'),
            const SizedBox(height: 8),
            AdminSearchableDropdownField<String>(
              value: _selectedCoachSpecialty,
              items: _coachSpecialties,
              itemLabel: (specialty) => specialty,
              prefixIcon: Iconsax.category,
              hintText: 'Select specialty',
              fillColor: AdminFormStyles.sessionPanelFill,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCoachSpecialty = value);
                }
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isAddingCoach ? null : _handleAddCoach,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EColorConstants.primaryColor,
                  disabledBackgroundColor:
                      EColorConstants.authPlaceholderGray,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isAddingCoach
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '+ Add Coach',
                        style: TextStyle(
                          fontSize: 15,
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
    );
  }

  List<CoachSessionModel> _filteredSessions(AdminHomeState admin) {
    if (_sessionFilter == 'All Classes') return admin.sessions;
    return admin.sessions
        .where(
          (s) => s.sessionType.toLowerCase() == _sessionFilter.toLowerCase(),
        )
        .toList();
  }

  Widget _buildCoachNameField(List<String> existingCoachNames) {
    return RawAutocomplete<String>(
      textEditingController: _coachNameController,
      focusNode: _coachNameFocusNode,
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return const Iterable<String>.empty();
        return existingCoachNames.where(
          (name) => name.toLowerCase().contains(query),
        );
      },
      onSelected: (selection) => _coachNameController.text = selection,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(
            fontSize: 13,
            fontFamily: 'Poppins',
            color: EColorConstants.authTextDarkBrown,
          ),
          decoration: _compactInputDecoration(
            hint: 'e.g. John Doe',
            prefixIcon: Iconsax.user,
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final items = options.toList();
        if (items.isEmpty) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160, minWidth: 200),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                itemBuilder: (context, index) {
                  final name = items[index];
                  return InkWell(
                    onTap: () => onSelected(name),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Text(
                        name,
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
    );
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
      fillColor: AdminFormStyles.sessionPanelFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: EColorConstants.primaryColor,
          width: 1.5,
        ),
      ),
    );
  }

  /// -----------------------------------------------------------------
  /// TAB 2: SESSIONS
  /// -----------------------------------------------------------------
  Widget _buildSessionsTab(bool dark, AdminHomeState admin) {
    final groupedSessions = _groupedFilteredSessions(admin);

    return AdminSmoothScrollView(
      refreshColor: EColorConstants.primaryColor,
      onRefresh: () async {
        context.read<AdminHomeBloc>().add(const RefreshCoaches(force: true));
        context.read<AdminHomeBloc>().add(const RefreshSessions());
        await Future<void>.delayed(const Duration(milliseconds: 400));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAddSessionForm(dark, admin),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.brown.shade100),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AdminFormStyles.sessionPanelFill,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Iconsax.folder_2,
                      size: 18,
                      color: EColorConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Saved Sessions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: EColorConstants.authTextDarkBrown,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  if (!admin.isLoadingSessions)
                    SizedBox(
                      width: 130,
                      child: ClassTypeFilterDropdown(
                        value: _sessionFilter,
                        onChanged: (value) {
                          setState(() => _sessionFilter = value);
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (admin.sessionsError != null)
              _buildSessionsErrorState(admin.sessionsError!)
            else if (admin.isLoadingSessions)
              _buildSessionsLoadingState()
            else if (admin.sessions.isEmpty)
              const AdminEmptyState(
                icon: Iconsax.calendar_remove,
                message:
                    'No sessions added yet.\nUse the form above to create a session.',
              )
            else if (groupedSessions.isEmpty)
              AdminEmptyState(
                icon: Iconsax.filter_search,
                message: 'No sessions match "$_sessionFilter".',
              )
            else
              ...groupedSessions.map((group) {
                return GroupedCoachSessionCard(
                  coachWithSessions: group,
                  onEdit: (session) => _navigateToEditSession(session),
                  onDelete: () => _handleDeleteSessionSchedule(group),
                  onDuplicate: () => _duplicateSessionGroup(group),
                );
              }),
        ],
      ),
    );
  }

  Widget _buildSessionsLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: EColorConstants.authCardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EColorConstants.authFieldBorder),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: EColorConstants.primaryColor),
          SizedBox(height: 14),
          Text(
            'Loading sessions from Supabase...',
            style: TextStyle(
              fontSize: 13,
              color: EColorConstants.authPlaceholderGray,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsErrorState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Iconsax.warning_2, color: Colors.red.shade400, size: 36),
          const SizedBox(height: 10),
          Text(
            'Could not load sessions',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.red.shade700,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {
              context.read<AdminHomeBloc>().add(const RefreshSessions());
            },
            icon: const Icon(Iconsax.refresh, size: 16),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade300),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddSessionForm(bool dark, AdminHomeState admin) {
    final hasCoaches = admin.coaches.isNotEmpty;
    final isSavingSession = admin.isSavingSession;

    CoachModel? selectedCoach;
    for (final coach in admin.coaches) {
      if (coach.id == _selectedSessionCoachId) {
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

    return Container(
      decoration: AdminFormStyles.formCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AdminFormStyles.sessionPanelFill,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.clipboard_text,
                    size: 22,
                    color: EColorConstants.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Session',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: EColorConstants.authTextDarkBrown,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Schedule a new training block',
                        style: TextStyle(
                          fontSize: 12,
                          color: EColorConstants.authPlaceholderGray,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Form(
              key: _sessionFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!hasCoaches)
                    Container(
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
                          Icon(Iconsax.info_circle,
                              size: 18, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Add a coach first before scheduling sessions.',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildFieldLabel('Select Coach'),
                  const SizedBox(height: 8),
                  AdminSearchableDropdownField<CoachModel>(
                    value: hasCoaches ? selectedCoach : null,
                    items: admin.coaches,
                    itemLabel: (coach) => coach.name,
                    searchText: (coach) => '${coach.name} ${coach.specialty}',
                    errorText: _coachError,
                    enabled: hasCoaches,
                    hintText: 'Select coach',
                    selectedBuilder: (coach) => SessionCoachDropdownTile(
                      name: coach.name,
                      photoUrl: coach.photoUrl,
                    ),
                    itemBuilder: (coach) => SessionCoachDropdownTile(
                      name: coach.name,
                      photoUrl: coach.photoUrl,
                    ),
                    onChanged: hasCoaches
                        ? (coach) => _onSessionCoachChanged(coach?.id, admin)
                        : (_) {},
                  ),
                  const SizedBox(height: 16),
                  AdminFormStyles.fieldLabel('Branch'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: _isLoadingBranches
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              )
                            : AdminSearchableDropdownField<Branch>(
                                value: selectedBranch,
                                items: _branches,
                                itemLabel: (branch) => branch.name,
                                prefixIcon: Icons.location_city_outlined,
                                errorText: _branchError,
                                enabled: hasCoaches && _branches.isNotEmpty,
                                hintText: 'Select Branch',
                                onChanged: hasCoaches && _branches.isNotEmpty
                                    ? (branch) {
                                        setState(() {
                                          _sessionFormTouched = true;
                                          _selectedBranchId = branch?.id;
                                          _branchError = null;
                                        });
                                      }
                                    : (_) {},
                              ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: Material(
                          color: AdminFormStyles.sessionPanelFill,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: hasCoaches ? _showAddBranchDialog : null,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE8DDD0),
                                ),
                              ),
                              child: const Icon(
                                Icons.add_business_outlined,
                                size: 22,
                                color: EColorConstants.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_branches.isEmpty && !_isLoadingBranches) ...[
                    const SizedBox(height: 8),
                    Text(
                      'No branches yet. Tap + to add one.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  AdminDropdownField<String>(
                    label: 'Time Slot',
                    value: _selectedTimeSlot,
                    items: SessionDraft.presetTimeSlots,
                    itemLabel: (item) => item,
                    prefixIcon: Iconsax.clock,
                    enabled: hasCoaches,
                    searchable: true,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sessionFormTouched = true;
                          _selectedTimeSlot = value;
                          _timeSlotError = null;
                        });
                      }
                    },
                  ),
                  if (_timeSlotError != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _timeSlotError!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  AdminAutocompleteField(
                    label: 'Price Per Session (EGP)',
                    hint: 'Enter price',
                    controller: _priceController,
                    options: recentPriceOptions,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      final parsed = double.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Enter a valid price greater than 0';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      setState(() {
                        _sessionFormTouched = true;
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
                  const SizedBox(height: 16),
                  SessionsPerWeekDropdown(
                    selectedCount: _sessionsPerWeek,
                    enabled: hasCoaches,
                    onChanged: _onSessionsPerWeekChanged,
                  ),
                  const SizedBox(height: 18),
                  SessionDetailsPanel(
                    slots: _sessionSlots,
                    weekDays: _weekDays,
                    classTypes: _classTypes,
                    enabled: hasCoaches,
                    onSlotChanged: (index, slot) => _updateSessionSlot(index, slot),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (!isSavingSession && hasCoaches)
                          ? () => _handleSaveSession()
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EColorConstants.primaryColor,
                        disabledBackgroundColor:
                            EColorConstants.authPlaceholderGray,
                        elevation: 0,
                        shadowColor: EColorConstants.primaryColor.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: isSavingSession
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Create Session',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: (!isSavingSession && hasCoaches)
                          ? () => _handleSaveSession(addAnother: true)
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: EColorConstants.primaryColor,
                        disabledForegroundColor:
                            EColorConstants.authPlaceholderGray,
                        side: const BorderSide(
                          color: EColorConstants.primaryColor,
                          width: 1.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Save & Add Another',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return AdminFormStyles.fieldLabel(text);
  }
}

