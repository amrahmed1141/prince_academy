import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/data/models/session_draft.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_header.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_tab_layout.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_dashed_upload.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_section_card.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_smooth_scroll.dart';
import 'package:prince_academy/features/admin/presentation/widgets/specialty_chip.dart';
import 'package:prince_academy/features/admin/presentation/widgets/class_type_filter_dropdown.dart';
import 'package:prince_academy/features/admin/presentation/widgets/session_draft_row.dart';
import 'package:prince_academy/features/admin/presentation/widgets/session_frequency_selector.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_card.dart';
import 'package:prince_academy/features/admin/presentation/widgets/custom_bottom_navigation.dart';
import 'package:prince_academy/features/admin/presentation/pages/admin_profile.dart';
import 'package:prince_academy/features/admin/presentation/widgets/session_card.dart';
import 'package:prince_academy/features/admin/data/models/coach_model.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';
import 'package:prince_academy/core/di/injection.dart';

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

  Future<void> _addSession({
    required String coachId,
    required int sessionsPerWeek,
    required String sessionType,
    DateTime? sessionDate,
  }) async {
    await sl<CoachRepository>().addCoachSession(
      coachId: coachId,
      sessionsPerWeek: sessionsPerWeek,
      sessionType: sessionType,
      sessionDate: sessionDate,
    );
    await _fetchSessions();
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
                onAddSession: _addSession,
                isLoadingCoaches: _isLoadingCoaches,
                isLoadingSessions: _isLoadingSessions,
                sessionsError: _sessionsError,
              ),
              const _CameraPage(),
            ],
          ),
          GlassBottomNavigation(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
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
  final Future<void> Function({
    required String coachId,
    required int sessionsPerWeek,
    required String sessionType,
    DateTime? sessionDate,
  }) onAddSession;
  final bool isLoadingCoaches;
  final bool isLoadingSessions;
  final String? sessionsError;

  const _AddInfoPage({
    required this.coaches,
    required this.sessions,
    required this.onRefreshCoaches,
    required this.onRefreshSessions,
    required this.onAddSession,
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

  static const _sessionClassTypes = [
    'Striking',
    'Grappling',
    'Conditioning',
    'Sparring',
    'Drills',
  ];

  static const _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final _tabLayoutKey = GlobalKey<AdminTabLayoutState>();

  // Coach Form Controllers
  final _coachNameController = TextEditingController();
  late final FocusNode _coachNameFocusNode;
  String _selectedCoachSpecialty = 'Muay Thai';
  String? _selectedCoachImagePath;
  bool _isAddingCoach = false;

  // Session Form State
  int _sessionsPerWeek = 1;
  List<SessionDraft> _sessionDrafts = SessionDraft.listForCount(1);
  String? _selectedSessionCoachId;
  bool _isAddingSession = false;

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

  DateTime _getNextWeekdayDate(String dayOfWeekName) {
    final now = DateTime.now();
    final dayMap = <String, int>{
      'mon': DateTime.monday,
      'tue': DateTime.tuesday,
      'wed': DateTime.wednesday,
      'thu': DateTime.thursday,
      'fri': DateTime.friday,
      'sat': DateTime.saturday,
      'sun': DateTime.sunday,
    };
    final key = dayOfWeekName.toLowerCase().substring(0, 3);
    final targetWeekday = dayMap[key] ?? now.weekday;
    int daysToAdd = targetWeekday - now.weekday;
    if (daysToAdd <= 0) {
      daysToAdd += 7;
    }
    return DateTime(now.year, now.month, now.day + daysToAdd, 18, 0);
  }

  Future<void> _handleAddSessions() async {
    if (widget.coaches.isEmpty) {
      _showSnackBar(
        'No coaches available. Please add a coach first.',
        Colors.orange,
      );
      return;
    }

    if (_selectedSessionCoachId == null) {
      _showSnackBar('Please select a coach.', Colors.orange);
      return;
    }

    if (_sessionDrafts.length != _sessionsPerWeek) {
      _showSnackBar('Session rows are out of sync. Please reselect frequency.', Colors.orange);
      return;
    }

    final selectedDays = <String>{};
    for (int i = 0; i < _sessionDrafts.length; i++) {
      final draft = _sessionDrafts[i];
      if (draft.day.isEmpty) {
        _showSnackBar('Session ${i + 1}: please select a day.', Colors.orange);
        return;
      }
      if (draft.classType.isEmpty) {
        _showSnackBar('Session ${i + 1}: please select a class type.', Colors.orange);
        return;
      }
      if (selectedDays.contains(draft.day)) {
        _showSnackBar('Duplicate day: ${draft.day} is selected more than once.', Colors.orange);
        return;
      }
      selectedDays.add(draft.day);
    }

    final selectedCoachExists =
        widget.coaches.any((c) => c.id == _selectedSessionCoachId);

    if (!selectedCoachExists) {
      _showSnackBar(
        'Selected coach is no longer available. Please refresh.',
        Colors.orange,
      );
      return;
    }

    setState(() {
      _isAddingSession = true;
    });

    try {
      for (final draft in _sessionDrafts) {
        final sessionDate = _getNextWeekdayDate(draft.day);
        await widget.onAddSession(
          coachId: _selectedSessionCoachId!,
          sessionsPerWeek: _sessionsPerWeek,
          sessionType: draft.classType,
          sessionDate: sessionDate,
        );
      }

      _showSnackBar(
        _sessionDrafts.length == 1
            ? 'Session added successfully!'
            : '${_sessionDrafts.length} sessions added successfully!',
        Colors.green,
      );

      if (mounted) {
        setState(() {
          _sessionsPerWeek = 1;
          _sessionDrafts = SessionDraft.listForCount(1);
        });
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      _showSnackBar('Failed to add sessions: $e', Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() {
          _isAddingSession = false;
        });
      }
    }
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

  void _onSessionsPerWeekChanged(int count) {
    setState(() {
      _sessionsPerWeek = count;
      _sessionDrafts = SessionDraft.resize(_sessionDrafts, count);
    });
  }

  void _updateSessionDraft(int index, SessionDraft draft) {
    setState(() {
      _sessionDrafts[index] = draft;
    });
  }

  @override
  void dispose() {
    _coachNameController.dispose();
    _coachNameFocusNode.dispose();
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
          const SizedBox(height: 12),
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
                name: coach.name,
                specialty: coach.specialty,
                sessionCount: coachSessionCount,
                imagePath: coach.photoUrl,
                onMenuTap: () {
                  _showCoachMenu(context, coach);
                },
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

  void _showCoachMenu(BuildContext context, CoachModel coach) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: EColorConstants.authCardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Iconsax.calendar, color: EColorConstants.primaryColor),
                title: const Text('Manage Sessions', style: TextStyle(fontFamily: 'Poppins')),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedSessionCoachId = coach.id);
                  _tabLayoutKey.currentState?.animateToTab(1);
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.refresh, color: EColorConstants.primaryColor),
                title: const Text('Refresh Coaches', style: TextStyle(fontFamily: 'Poppins')),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onRefreshCoaches();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// -----------------------------------------------------------------
  /// TAB 2: SESSIONS
  /// -----------------------------------------------------------------
  Widget _buildSessionsTab(bool dark) {
    final filteredSessions = _filteredSessions();

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
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: EColorConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Iconsax.folder_2,
                    size: 16,
                    color: EColorConstants.primaryColor,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Saved Sessions',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: EColorConstants.authTextDarkBrown,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                if (!widget.isLoadingSessions)
                  Flexible(
                    child: ClassTypeFilterDropdown(
                      value: _sessionFilter,
                      onChanged: (value) {
                        setState(() => _sessionFilter = value);
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
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
            else if (filteredSessions.isEmpty)
              _buildEmptyState(
                icon: Iconsax.filter_search,
                message: 'No sessions match "$_sessionFilter".',
              )
            else
              ...filteredSessions.map((session) {
                return SavedSessionCard(
                  coachName: session.coachName ?? 'Unknown Coach',
                  coachPhotoUrl: session.coachPhotoUrl,
                  session: session,
                  onMenuTap: () => _showSessionMenu(session),
                );
              }),
        ],
      ),
    );
  }

  void _showSessionMenu(CoachSessionModel session) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: EColorConstants.authCardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconsax.refresh, color: EColorConstants.primaryColor),
              title: const Text('Refresh Sessions', style: TextStyle(fontFamily: 'Poppins')),
              onTap: () {
                Navigator.pop(ctx);
                widget.onRefreshSessions();
              },
            ),
          ],
        ),
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
                  decoration: const BoxDecoration(
                    color: EColorConstants.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.clipboard_text,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create New Session',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: EColorConstants.authTextDarkBrown,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        'Build a training session schedule',
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                  decoration: _sessionFieldDecoration(),
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
                          if (value != null) {
                            setState(() => _selectedSessionCoachId = value);
                          }
                        }
                      : null,
                ),
                const SizedBox(height: 16),
                _buildFieldLabel('Sessions Per Week'),
                const SizedBox(height: 10),
                SessionFrequencySelector(
                  selectedCount: _sessionsPerWeek,
                  enabled: hasCoaches,
                  onChanged: _onSessionsPerWeekChanged,
                ),
                if (_sessionDrafts.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildFieldLabel('Session Details'),
                  const SizedBox(height: 8),
                  ...List.generate(_sessionDrafts.length, (index) {
                    return SessionDraftRow(
                      index: index,
                      draft: _sessionDrafts[index],
                      weekDays: _weekDays,
                      classTypes: _sessionClassTypes,
                      enabled: hasCoaches,
                      onChanged: (draft) => _updateSessionDraft(index, draft),
                    );
                  }),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: (!_isAddingSession && hasCoaches)
                        ? _handleAddSessions
                        : null,
                    icon: _isAddingSession
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
                      _isAddingSession ? 'Saving...' : '+ Add Session',
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
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

  InputDecoration _sessionFieldDecoration({IconData? prefixIcon}) {
    return InputDecoration(
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 18, color: EColorConstants.authPlaceholderGray)
          : null,
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

class _CameraPage extends StatelessWidget {
  const _CameraPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Camera / Scanner Page',
        style: TextStyle(fontFamily: 'Poppins'),
      ),
    );
  }
}
