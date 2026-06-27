import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/data/models/session_draft.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_header.dart';
import 'package:prince_academy/features/admin/presentation/widgets/custom_bottom_navigation.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_tab_layout.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_dashed_upload.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_section_card.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_smooth_scroll.dart';
import 'package:prince_academy/features/admin/presentation/widgets/specialty_chip.dart';
import 'package:prince_academy/features/admin/presentation/widgets/class_type_filter_dropdown.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_dropdown_field.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_text_field.dart';
import 'package:prince_academy/features/admin/presentation/widgets/session_draft_row.dart';
import 'package:prince_academy/features/admin/presentation/widgets/session_frequency_selector.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_card.dart';
import 'package:prince_academy/features/admin/presentation/pages/qr_scanner_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/tracking/tracking_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/admin_profile.dart';
import 'package:prince_academy/features/admin/presentation/widgets/session_card.dart';
import 'package:prince_academy/features/admin/data/models/coach_model.dart';
import 'package:prince_academy/features/admin/data/models/coach_with_sessions.dart';
import 'package:prince_academy/features/admin/data/models/branch_model.dart';
import 'package:prince_academy/features/admin/data/repositories/branch_repository.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_form_styles.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/features/admin/presentation/pages/edit_coach_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/edit_session_page.dart';
import 'package:prince_academy/features/admin/presentation/widgets/branch_management_dialog.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  List<CoachModel> _coaches = [];
  bool _isLoadingCoaches = false;

  List<CoachSessionModel> _sessions = [];
  bool _isLoadingSessions = false;
  String? _sessionsError;

  @override
  void initState() {
    super.initState();
    _fetchCoaches();
    _fetchSessions();
  }

  Future<void> _fetchCoaches() async {
    setState(() => _isLoadingCoaches = true);
    try {
      final coachesList = await sl<CoachRepository>().fetchCoaches();
      if (!mounted) return;
      debugPrint('fetchCoaches complete: ${coachesList.length} coaches');
      setState(() {
        _coaches = coachesList;
      });
    } catch (e) {
      debugPrint('fetchCoaches error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load coaches: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCoaches = false;
        });
      }
    }
  }

  Future<void> _fetchSessions() async {
    setState(() {
      _isLoadingSessions = true;
      _sessionsError = null;
    });
    try {
      final sessionsList =
          await sl<CoachRepository>().getAllSessionsWithCoach();
      if (!mounted) return;
      setState(() {
        _sessions = sessionsList;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sessionsError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSessions = false;
        });
      }
    }
  }

  Future<void> _saveSession(SessionDraft draft) async {
    await sl<CoachRepository>().upsertSession(draft);
    await _fetchSessions();
  }

  Future<void> _deleteCoach(String coachId) async {
    await sl<CoachRepository>().deleteCoach(coachId);
    if (!mounted) return;
    setState(() {
      _coaches.removeWhere((coach) => coach.id == coachId);
      _sessions.removeWhere((session) => session.coachId == coachId);
    });
  }

  Future<void> _deleteSessionsByCoachId(String coachId) async {
    await sl<CoachRepository>().deleteSessionsByCoachId(coachId);
    if (!mounted) return;
    setState(() {
      _sessions.removeWhere((session) => session.coachId == coachId);
    });
  }

  void _openQrScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const QrScannerPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColorConstants.authFieldBackground,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              _AddInfoPage(
                coaches: _coaches,
                sessions: _sessions,
                onRefreshCoaches: _fetchCoaches,
                onRefreshSessions: _fetchSessions,
                onSaveSession: _saveSession,
                onDeleteCoach: _deleteCoach,
                onDeleteSessionsByCoachId: _deleteSessionsByCoachId,
                isLoadingCoaches: _isLoadingCoaches,
                isLoadingSessions: _isLoadingSessions,
                sessionsError: _sessionsError,
              ),
              const TrackingPage(),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: AdminGlassNavBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              onQrPressed: _openQrScanner,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddInfoPage extends StatefulWidget {
  final List<CoachModel> coaches;
  final List<CoachSessionModel> sessions;
  final VoidCallback onRefreshCoaches;
  final VoidCallback onRefreshSessions;
  final Future<void> Function(SessionDraft draft) onSaveSession;
  final Future<void> Function(String coachId) onDeleteCoach;
  final Future<void> Function(String coachId) onDeleteSessionsByCoachId;
  final bool isLoadingCoaches;
  final bool isLoadingSessions;
  final String? sessionsError;

  const _AddInfoPage({
    required this.coaches,
    required this.sessions,
    required this.onRefreshCoaches,
    required this.onRefreshSessions,
    required this.onSaveSession,
    required this.onDeleteCoach,
    required this.onDeleteSessionsByCoachId,
    required this.isLoadingCoaches,
    required this.isLoadingSessions,
    this.sessionsError,
  });

  @override
  State<_AddInfoPage> createState() => _AddInfoPageState();
}

class _AddInfoPageState extends State<_AddInfoPage> {
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
  bool _isAddingCoach = false;

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
  bool _isSavingSession = false;
  String? _coachError;
  String? _branchError;
  String? _timeSlotError;
  String? _priceError;

  // Coaches list filter
  String _coachFilter = 'All Coaches';
  String _sessionFilter = 'All Classes';

  @override
  void initState() {
    super.initState();
    _coachNameFocusNode = FocusNode();
    if (widget.coaches.isNotEmpty) {
      _selectedSessionCoachId = widget.coaches.first.id;
    }
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    setState(() => _isLoadingBranches = true);
    try {
      final branches = await sl<BranchRepository>().getAllBranches();
      if (!mounted) return;
      setState(() {
        _branches = branches;
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

  Future<void> _showAddBranchDialog() async {
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => const BranchManagementDialog(),
    );

    await _fetchBranches();
    widget.onRefreshSessions();
  }

  @override
  void didUpdateWidget(covariant _AddInfoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedSessionCoachId == null && widget.coaches.isNotEmpty) {
      setState(() {
        _selectedSessionCoachId = widget.coaches.first.id;
      });
    }
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
    debugPrint('handleAddCoach start');
    final name = _coachNameController.text.trim();
    debugPrint(
        'handleAddCoach name=$name specialty=$_selectedCoachSpecialty image=$_selectedCoachImagePath');
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a coach name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isAddingCoach = true;
    });

    try {
      String? photoUrl;
      if (_selectedCoachImagePath != null) {
        final file = File(_selectedCoachImagePath!);
        final fileName = _selectedCoachImagePath!.split('/').last;
        debugPrint('uploadCoachPhoto file=$fileName');
        photoUrl = await sl<CoachRepository>().uploadCoachPhoto(file, fileName);
      }

      debugPrint('addCoach request start');
      await sl<CoachRepository>().addCoach(
        name: name,
        specialty: _selectedCoachSpecialty,
        photoUrl: photoUrl,
      );
      debugPrint('addCoach request complete');

      _coachNameController.clear();
      setState(() {
        _selectedCoachImagePath = null;
      });

      widget.onRefreshCoaches();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coach added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add coach: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingCoach = false;
        });
      }
    }
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

  Future<void> _handleSaveSession() async {
    if (widget.coaches.isEmpty) {
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

    final price = double.parse(_priceController.text.trim());
    final draft = SessionDraft(
      coachId: _selectedSessionCoachId,
      branchId: _selectedBranchId,
      timeSlot: _selectedTimeSlot,
      pricePerSession: price,
      sessionsPerWeek: _sessionsPerWeek,
      sessions: List.from(_sessionSlots),
    );

    setState(() => _isSavingSession = true);

    try {
      await widget.onSaveSession(draft);
      _showSnackBar('Session saved successfully!', Colors.green);

      if (mounted) {
        setState(() {
          _selectedTimeSlot = SessionDraft.defaultTimeSlot;
          _sessionsPerWeek = 1;
          _sessionSlots = [SessionSlot.initial()];
          _priceController.clear();
          _coachError = null;
          _timeSlotError = null;
          _priceError = null;
        });
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      _showSnackBar('Failed to save session: $e', Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() => _isSavingSession = false);
      }
    }
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
    try {
      await widget.onDeleteCoach(coach.id);
      _showDeleteSnackBar('"${coach.name}" and their sessions deleted');
    } catch (e) {
      _showSnackBar('Failed to delete coach: $e', Colors.redAccent);
      widget.onRefreshCoaches();
      widget.onRefreshSessions();
    }
  }

  Future<void> _handleDeleteSessionSchedule(CoachWithSessions group) async {
    try {
      for (final session in group.schedules) {
        await sl<CoachRepository>().deleteSession(session.id);
      }
      final message = group.hasMultipleSchedules
          ? 'All sessions for "${group.name}" deleted'
          : '"${group.name}" deleted successfully';
      _showDeleteSnackBar(message);
      widget.onRefreshSessions();
    } catch (e) {
      _showSnackBar('Failed to delete session schedule: $e', Colors.redAccent);
      widget.onRefreshSessions();
    }
  }

  void _navigateToEditCoach(CoachModel coach) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditCoachPage(coach: coach),
      ),
    );
    if (result == true) {
      widget.onRefreshCoaches();
      widget.onRefreshSessions();
    }
  }

  void _navigateToEditSession(CoachSessionModel session) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditSessionPage(session: session),
      ),
    );
    if (result == true) {
      widget.onRefreshSessions();
    }
  }



  List<CoachWithSessions> _groupedFilteredSessions() {
    return CoachWithSessions.group(_filteredSessions());
  }

  String? _coachBranchLabel(CoachModel coach) {
    final branchNames = widget.sessions
        .where((session) => session.coachId == coach.id)
        .map((session) => session.branchName)
        .where((name) => name != null && name!.trim().isNotEmpty)
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
                  _buildAddCoachTab(dark),
                  _buildSessionsTab(dark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// -----------------------------------------------------------------
  /// TAB 1: ADD COACH
  /// -----------------------------------------------------------------
  Widget _buildAddCoachTab(bool dark) {
    final filteredCoaches = _coachFilter == 'All Coaches'
        ? widget.coaches
        : widget.coaches.where((c) => c.specialty == _coachFilter).toList();

    final filterOptions = <String>[
      'All Coaches',
      ...widget.coaches.map((c) => c.specialty).toSet(),
    ];

    return AdminSmoothScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAddCoachFormCard(),
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
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: EColorConstants.authCardWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: EColorConstants.authFieldBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isDense: true,
                      isExpanded: true,
                      value: filterOptions.contains(_coachFilter)
                          ? _coachFilter
                          : 'All Coaches',
                      icon: const Icon(
                        Iconsax.arrow_down_1,
                        size: 14,
                        color: EColorConstants.authPlaceholderGray,
                      ),
                      selectedItemBuilder: (context) {
                        return filterOptions.map((option) {
                          final label = option == 'All Coaches'
                              ? option
                              : SpecialtyChip.displayLabel(option);
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: EColorConstants.authTextDarkBrown,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          );
                        }).toList();
                      },
                      items: filterOptions.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(
                            option,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: EColorConstants.authTextDarkBrown,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _coachFilter = value);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (widget.isLoadingCoaches)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(
                  color: EColorConstants.primaryColor,
                ),
              ),
            )
          else if (filteredCoaches.isEmpty)
            _buildEmptyState(
              icon: Iconsax.people,
              message: widget.coaches.isEmpty
                  ? 'No coaches added yet.\nCreate your first coach above.'
                  : 'No coaches match this filter.',
            )
          else
            ...filteredCoaches.map((coach) {
              final coachSessionCount =
                  widget.sessions.where((s) => s.coachId == coach.id).length;
              return CoachListCard(
                coachId: coach.id,
                name: coach.name,
                specialty: coach.specialty,
                sessionCount: coachSessionCount,
                imagePath: coach.photoUrl,
                branchName: _coachBranchLabel(coach),
                onEdit: () => _navigateToEditCoach(coach),
                onDelete: () => _handleDeleteCoach(coach),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAddCoachFormCard() {
    return AdminSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: EColorConstants.primaryColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.profile_add,
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
                        'Create coach profile to get started',
                        style: TextStyle(
                          fontSize: 11,
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminDashedUpload(
                  imagePath: _selectedCoachImagePath,
                  onTap: _pickCoachImage,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCompactFieldLabel('Coach Name'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _coachNameController,
                        focusNode: _coachNameFocusNode,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'Poppins',
                          color: EColorConstants.authTextDarkBrown,
                        ),
                        decoration: _compactInputDecoration(
                          hint: 'e.g. John Doe',
                          prefixIcon: Iconsax.user,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCompactFieldLabel('Specialty'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedCoachSpecialty,
                        isExpanded: true,
                        decoration: _compactInputDecoration(
                          hint: 'Select specialty',
                          prefixIcon: Iconsax.category,
                        ),
                        selectedItemBuilder: (context) {
                          return _coachSpecialties.map((specialty) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                SpecialtyChip.displayLabel(specialty),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                  color: EColorConstants.authTextDarkBrown,
                                ),
                              ),
                            );
                          }).toList();
                        },
                        items: _coachSpecialties.map((specialty) {
                          return DropdownMenuItem(
                            value: specialty,
                            child: Text(
                              specialty,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontFamily: 'Poppins'),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedCoachSpecialty = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isAddingCoach ? null : _handleAddCoach,
                icon: _isAddingCoach
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Iconsax.add, color: Colors.white, size: 20),
                label: Text(
                  _isAddingCoach ? 'Adding...' : '+ Add Coach',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EColorConstants.primaryColor,
                  disabledBackgroundColor:
                      EColorConstants.authPlaceholderGray,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<CoachSessionModel> _filteredSessions() {
    if (_sessionFilter == 'All Classes') return widget.sessions;
    return widget.sessions
        .where(
          (s) => s.sessionType.toLowerCase() == _sessionFilter.toLowerCase(),
        )
        .toList();
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

  /// -----------------------------------------------------------------
  /// TAB 2: SESSIONS
  /// -----------------------------------------------------------------
  Widget _buildSessionsTab(bool dark) {
    final groupedSessions = _groupedFilteredSessions();

    return AdminSmoothScrollView(
      refreshColor: EColorConstants.primaryColor,
      onRefresh: () async {
        widget.onRefreshCoaches();
        widget.onRefreshSessions();
        await Future<void>.delayed(const Duration(milliseconds: 400));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAddSessionForm(dark),
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
                  if (!widget.isLoadingSessions)
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
            if (widget.sessionsError != null)
              _buildSessionsErrorState(widget.sessionsError!)
            else if (widget.isLoadingSessions)
              _buildSessionsLoadingState()
            else if (widget.sessions.isEmpty)
              _buildEmptyState(
                icon: Iconsax.calendar_remove,
                message:
                    'No sessions added yet.\nUse the form above to create a session.',
              )
            else if (groupedSessions.isEmpty)
              _buildEmptyState(
                icon: Iconsax.filter_search,
                message: 'No sessions match "$_sessionFilter".',
              )
            else
              ...groupedSessions.map((group) {
                return GroupedCoachSessionCard(
                  coachWithSessions: group,
                  onEdit: (session) => _navigateToEditSession(session),
                  onDelete: () => _handleDeleteSessionSchedule(group),
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
            onPressed: widget.onRefreshSessions,
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

  Widget _buildAddSessionForm(bool dark) {
    final hasCoaches = widget.coaches.isNotEmpty;

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
                  DropdownButtonFormField<String>(
                    value: hasCoaches ? _selectedSessionCoachId : null,
                    isExpanded: true,
                    decoration: AdminFormStyles.fieldDecoration(
                      errorText: _coachError,
                    ),
                    selectedItemBuilder: (context) {
                      return widget.coaches.map((coach) {
                        return SessionCoachDropdownTile(
                          name: coach.name,
                          photoUrl: coach.photoUrl,
                        );
                      }).toList();
                    },
                    items: widget.coaches.map((coach) {
                      return DropdownMenuItem(
                        value: coach.id,
                        child: SessionCoachDropdownTile(
                          name: coach.name,
                          photoUrl: coach.photoUrl,
                        ),
                      );
                    }).toList(),
                    onChanged: hasCoaches
                        ? (value) {
                            setState(() {
                              _selectedSessionCoachId = value;
                              _coachError = null;
                            });
                          }
                        : null,
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
                            : DropdownButtonFormField<String>(
                                value: _branches.any((b) => b.id == _selectedBranchId)
                                    ? _selectedBranchId
                                    : null,
                                isExpanded: true,
                                hint: const Text(
                                  'Select Branch',
                                  style: TextStyle(fontFamily: 'Poppins'),
                                ),
                                decoration: AdminFormStyles.fieldDecoration(
                                  prefixIcon: Icons.location_city_outlined,
                                  errorText: _branchError,
                                ),
                                items: _branches
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
                                onChanged: hasCoaches && _branches.isNotEmpty
                                    ? (value) {
                                        setState(() {
                                          _selectedBranchId = value;
                                          _branchError = null;
                                        });
                                      }
                                    : null,
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
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
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
                  AdminTextField(
                    label: 'Price Per Session (EGP)',
                    hint: 'Enter price',
                    controller: _priceController,
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
                      if (_priceError != null) {
                        setState(() => _priceError = null);
                      }
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
                      onPressed: (!_isSavingSession && hasCoaches)
                          ? _handleSaveSession
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
                      child: _isSavingSession
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

  /// Empty state widget
  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: EColorConstants.authFieldBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EColorConstants.authFieldBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: EColorConstants.authPlaceholderGray),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: EColorConstants.authPlaceholderGray,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

}
