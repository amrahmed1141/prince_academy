import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_header.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_tab_selector.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_text_field.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_card.dart';
import 'package:prince_academy/features/admin/presentation/widgets/custom_bottom_navigation.dart';
import 'package:prince_academy/features/admin/presentation/pages/admin_profile.dart';
import 'package:prince_academy/features/admin/data/models/coach_model.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/core/di/injection.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  // Local state for coaches fetched from Supabase
  List<CoachModel> _coaches = [];
  bool _isLoadingCoaches = false;

  // Local state for sessions (Mock data remains intact)
  final List<Map<String, String>> _sessions = [
    {
      'title': 'Morning Striking',
      'type': 'Striking',
      'coach': 'Alex Johnson',
      'date': 'June 3, 2026',
      'duration': '60 min',
      'spots': '4 spots left',
    },
    {
      'title': 'BJJ Fundamentals',
      'type': 'Grappling',
      'coach': 'Maria Garcia',
      'date': 'June 4, 2026',
      'duration': '90 min',
      'spots': '6 spots left',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchCoaches();
  }

  Future<void> _fetchCoaches() async {
    debugPrint('fetchCoaches start');
    setState(() {
      _isLoadingCoaches = true;
    });
    try {
      final coachesList = await sl<CoachRepository>().fetchCoaches();
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

  void _addSession(Map<String, String> session) {
    setState(() {
      _sessions.insert(0, session);
    });
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
                onAddSession: _addSession,
                isLoadingCoaches: _isLoadingCoaches,
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

class _DynamicSessionRow {
  String? selectedDay;
  String selectedType = 'Striking';
}

class _AddInfoPage extends StatefulWidget {
  final List<CoachModel> coaches;
  final List<Map<String, String>> sessions;
  final VoidCallback onRefreshCoaches;
  final Function(Map<String, String>) onAddSession;
  final bool isLoadingCoaches;

  const _AddInfoPage({
    required this.coaches,
    required this.sessions,
    required this.onRefreshCoaches,
    required this.onAddSession,
    required this.isLoadingCoaches,
  });

  @override
  State<_AddInfoPage> createState() => _AddInfoPageState();
}

class _AddInfoPageState extends State<_AddInfoPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Coach Form Controllers
  final _coachNameController = TextEditingController();
  late final FocusNode _coachNameFocusNode;
  int _formBuildCount = 0;
  String _selectedCoachSpecialty = 'Muay Thai';
  String? _selectedCoachImagePath;
  bool _isAddingCoach = false;

  // Session Form State
  int? _sessionsPerWeek;
  String _selectedSessionCoach = '';
  final List<_DynamicSessionRow> _dynamicRows = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        debugPrint('TabController index changed: ${_tabController.index}');
        setState(() {});
      }
    });
    _coachNameFocusNode = FocusNode()
      ..addListener(() {
        debugPrint('Coach name focus changed: ${_coachNameFocusNode.hasFocus}');
      });
    if (widget.coaches.isNotEmpty) {
      _selectedSessionCoach = widget.coaches.first.name;
    }
  }

  @override
  void didUpdateWidget(covariant _AddInfoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedSessionCoach.isEmpty && widget.coaches.isNotEmpty) {
      setState(() {
        _selectedSessionCoach = widget.coaches.first.name;
      });
    }
  }

  void _onSessionsPerWeekChanged(int? value) {
    setState(() {
      _sessionsPerWeek = value;
      if (value == null) {
        _dynamicRows.clear();
        return;
      }
      while (_dynamicRows.length < value) {
        _dynamicRows.add(_DynamicSessionRow());
      }
      while (_dynamicRows.length > value) {
        _dynamicRows.removeLast();
      }
    });
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

  void _handleAddSessions() {
    if (_sessionsPerWeek == null) {
      _showSnackBar('Please select sessions per week.', Colors.orange);
      return;
    }

    if (_dynamicRows.isEmpty) {
      _showSnackBar('Please configure the session rows.', Colors.orange);
      return;
    }

    final selectedDays = <String>{};

    for (int i = 0; i < _dynamicRows.length; i++) {
      final row = _dynamicRows[i];
      final day = row.selectedDay;

      if (day == null || day.isEmpty) {
        _showSnackBar('Day ${i + 1}: please select a day.', Colors.orange);
        return;
      }

      if (selectedDays.contains(day)) {
        _showSnackBar(
            'Duplicate day: $day is selected more than once.', Colors.orange);
        return;
      }
      selectedDays.add(day);
    }

    final selectedCoachModel = widget.coaches.firstWhere(
      (c) => c.name == _selectedSessionCoach,
      orElse: () => widget.coaches.first,
    );

    for (var row in _dynamicRows) {
      widget.onAddSession({
        'title': '${row.selectedType} – ${row.selectedDay}',
        'type': row.selectedType,
        'coach': selectedCoachModel.name,
        'coach_id': selectedCoachModel.id,
        'day_of_week': row.selectedDay!,
        'duration': '',
        'spots': '10 spots left',
      });
    }

    debugPrint(
        'handleAddSessions added ${_dynamicRows.length} sessions for coach=$_selectedSessionCoach');
    _showSnackBar('Sessions added successfully!', Colors.green);

    setState(() {
      _sessionsPerWeek = null;
      _dynamicRows.clear();
    });
    FocusScope.of(context).unfocus();
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
    _tabController.dispose();
    _coachNameController.dispose();
    _coachNameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        'AddInfoPage build #${++_formBuildCount} tab=${_tabController.index} sessionsPerWeek=$_sessionsPerWeek dynamicRows=${_dynamicRows.length} coaches=${widget.coaches.length}');
    return Column(
      children: [
        AdminHeader(
          onAvatarTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminProfilePage()),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AdminTabSelector(
            labels: const ['Coaches', 'Sessions'],
            icons: const [Iconsax.user, Iconsax.calendar],
            selectedIndex: _tabController.index,
            onChanged: (index) => _tabController.animateTo(index),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _CoachesListTab(
                nameController: _coachNameController,
                selectedSpecialty: _selectedCoachSpecialty,
                onSpecialtyChanged: (v) =>
                    setState(() => _selectedCoachSpecialty = v),
                selectedImagePath: _selectedCoachImagePath,
                onPickImage: _pickCoachImage,
                coaches: widget.coaches,
                onAdd: _handleAddCoach,
                isAdding: _isAddingCoach,
                isLoadingCoaches: widget.isLoadingCoaches,
                focusNode: _coachNameFocusNode,
              ),
              _SessionsListTab(
                sessionsPerWeek: _sessionsPerWeek,
                onSessionsPerWeekChanged: _onSessionsPerWeekChanged,
                dynamicRows: _dynamicRows,
                selectedCoach: _selectedSessionCoach,
                coaches: widget.coaches,
                onCoachChanged: (v) =>
                    setState(() => _selectedSessionCoach = v),
                sessions: widget.sessions,
                onAdd: _handleAddSessions,
                onDayChanged: (idx, day) {
                  setState(() {
                    _dynamicRows[idx].selectedDay = day;
                  });
                },
                onTypeChangedForRow: (idx, type) {
                  setState(() {
                    _dynamicRows[idx].selectedType = type;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionsListTab extends StatelessWidget {
  final int? sessionsPerWeek;
  final ValueChanged<int?> onSessionsPerWeekChanged;
  final List<_DynamicSessionRow> dynamicRows;
  final String selectedCoach;
  final List<CoachModel> coaches;
  final ValueChanged<String> onCoachChanged;
  final List<Map<String, String>> sessions;
  final VoidCallback onAdd;
  final Function(int, String) onDayChanged;
  final Function(int, String) onTypeChangedForRow;

  const _SessionsListTab({
    required this.sessionsPerWeek,
    required this.onSessionsPerWeekChanged,
    required this.dynamicRows,
    required this.selectedCoach,
    required this.coaches,
    required this.onCoachChanged,
    required this.sessions,
    required this.onAdd,
    required this.onDayChanged,
    required this.onTypeChangedForRow,
  });

  static const _types = ['Striking', 'Grappling', 'Conditioning', 'Boxing'];
  static const _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  List<Widget> _buildGroupedSessionsByCoach(
      List<Map<String, String>> sessions) {
    // Group sessions by coach
    final Map<String, List<Map<String, String>>> groupedByCoach = {};

    for (final session in sessions) {
      final coach = session['coach'] ?? 'Unknown';
      if (!groupedByCoach.containsKey(coach)) {
        groupedByCoach[coach] = [];
      }
      groupedByCoach[coach]!.add(session);
    }

    // Build widgets for each coach group
    return groupedByCoach.entries.map((entry) {
      final coach = entry.key;
      final coachSessions = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _CoachSessionGroup(
          coachName: coach,
          sessions: coachSessions,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        'SessionsListTab build sessions=${sessions.length} rows=${dynamicRows.length} coach=$selectedCoach');
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'ADD SESSION'),
          const SizedBox(height: 10),
          _FormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel(label: 'Sessions per Week'),
                const SizedBox(height: 8),
                _CustomDropdown(
                  value: sessionsPerWeek?.toString() ?? '',
                  items: const ['1', '2', '3', '4'],
                  onChanged: (v) => onSessionsPerWeekChanged(
                    v != null ? int.tryParse(v) : null,
                  ),
                ),
                if (dynamicRows.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(
                    color: EColorConstants.authFieldBorder,
                    height: 1,
                  ),
                  const SizedBox(height: 20),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dynamicRows.length,
                    itemBuilder: (context, index) {
                      final row = dynamicRows[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: EColorConstants.authFieldBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: EColorConstants.authFieldBorder,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DAY ${index + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: EColorConstants.primaryColor,
                                fontFamily: 'Poppins',
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const _FieldLabel(label: 'Day'),
                            const SizedBox(height: 6),
                            _CustomDropdown(
                              value: row.selectedDay ?? '',
                              items: _days,
                              onChanged: (val) => onDayChanged(index, val!),
                            ),
                            const SizedBox(height: 12),
                            const _FieldLabel(label: 'Type'),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _types.map((t) {
                                  final selected = row.selectedType == t;
                                  return _ChipItem(
                                    label: t,
                                    selected: selected,
                                    onTap: () => onTypeChangedForRow(index, t),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 16),
                const _FieldLabel(label: 'Coach'),
                const SizedBox(height: 8),
                _CustomDropdown(
                  value: selectedCoach,
                  items: coaches.map((c) => c.name).toList(),
                  onChanged: (v) => onCoachChanged(v!),
                ),
                const SizedBox(height: 20),
                _ActionButton(label: '+ Add Session', onTap: onAdd),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: 'SESSIONS (${sessions.length})'),
          const SizedBox(height: 12),
          if (sessions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No sessions added yet',
                  style: TextStyle(
                    color: EColorConstants.authPlaceholderGray,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            )
          else
            ..._buildGroupedSessionsByCoach(sessions),
        ],
      ),
    );
  }
}

class _CoachesListTab extends StatelessWidget {
  final TextEditingController nameController;
  final String selectedSpecialty;
  final ValueChanged<String> onSpecialtyChanged;
  final String? selectedImagePath;
  final VoidCallback onPickImage;
  final List<CoachModel> coaches;
  final VoidCallback onAdd;
  final bool isAdding;
  final bool isLoadingCoaches;
  final FocusNode? focusNode;

  const _CoachesListTab({
    required this.nameController,
    required this.selectedSpecialty,
    required this.onSpecialtyChanged,
    required this.selectedImagePath,
    required this.onPickImage,
    required this.coaches,
    required this.onAdd,
    required this.isAdding,
    required this.isLoadingCoaches,
    this.focusNode,
  });

  static const _specialties = ['Muay Thai', 'BJJ', 'MMA', 'Boxing'];

  @override
  Widget build(BuildContext context) {
    debugPrint(
        'CoachesListTab build coaches=${coaches.length} isLoading=$isLoadingCoaches isAdding=$isAdding');
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'ADD COACH'),
          const SizedBox(height: 10),
          _FormCard(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: isAdding ? null : onPickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: EColorConstants.authFieldBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: EColorConstants.authFieldBorder,
                                width: 2),
                            image: selectedImagePath != null
                                ? DecorationImage(
                                    image: FileImage(File(selectedImagePath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: selectedImagePath == null
                              ? const Icon(Iconsax.user,
                                  size: 40,
                                  color: EColorConstants.authPlaceholderGray)
                              : null,
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: EColorConstants.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Iconsax.camera,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AdminTextField(
                  label: 'Full Name',
                  hint: 'Enter coach full name',
                  controller: nameController,
                  focusNode: focusNode,
                ),
                const SizedBox(height: 16),
                const _FieldLabel(label: 'Specialty'),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _specialties.map((s) {
                      final selected = selectedSpecialty == s;
                      return _ChipItem(
                        label: s,
                        selected: selected,
                        onTap: isAdding ? () {} : () => onSpecialtyChanged(s),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                _ActionButton(
                  label: '+ Add Coach',
                  onTap: isAdding ? null : onAdd,
                  isLoading: isAdding,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: 'COACHES (${coaches.length})'),
          const SizedBox(height: 12),
          if (isLoadingCoaches && coaches.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(
                  color: EColorConstants.primaryColor,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: coaches.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final coach = coaches[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CoachCard(
                    name: coach.name,
                    specialty: coach.specialty,
                    sessionCount: '0',
                    rating: '5.0',
                    imagePath: coach.photoUrl,
                  ),
                );
              },
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
    return Column(
      children: [
        AdminHeader(
          onAvatarTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminProfilePage()),
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Iconsax.camera,
                    size: 36,
                    color: EColorConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Camera tools will appear here.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: EColorConstants.authPlaceholderGray,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Reusable micro-widgets for the admin panel
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: EColorConstants.authTextDarkBrown,
        fontFamily: 'Poppins',
        letterSpacing: 1.2,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: EColorConstants.authTextDarkBrown,
        fontFamily: 'Poppins',
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;
  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ChipItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChipItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? EColorConstants.primaryColor
                : EColorConstants.authFieldBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? EColorConstants.primaryColor
                  : EColorConstants.authFieldBorder,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color:
                  selected ? Colors.white : EColorConstants.authTextDarkBrown,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const _ActionButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: EColorConstants.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
      ),
    );
  }
}

class _CustomDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _CustomDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('CustomDropdown build value="$value" items=${items.length}');
    final safeValue = value.isNotEmpty && items.contains(value) ? value : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: EColorConstants.authFieldBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EColorConstants.authFieldBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          onTap: () => debugPrint('Dropdown opened with value="$value"'),
          icon: const Icon(Iconsax.arrow_down_1,
              size: 20, color: EColorConstants.authPlaceholderGray),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: EColorConstants.authTextDarkBrown,
            fontFamily: 'Poppins',
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _CoachSessionGroup extends StatelessWidget {
  final String coachName;
  final List<Map<String, String>> sessions;

  const _CoachSessionGroup({
    required this.coachName,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    // Extract unique days and types from sessions
    final Set<String> uniqueDays = {};
    final Map<String, Set<String>> dayToTypes = {};

    for (final session in sessions) {
      final day = session['day_of_week'] ?? session['date'] ?? 'Unknown';
      final type = session['type'] ?? 'Unknown';

      uniqueDays.add(day);
      if (!dayToTypes.containsKey(day)) {
        dayToTypes[day] = {};
      }
      dayToTypes[day]!.add(type);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coach name header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: EColorConstants.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Iconsax.user, size: 18, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coachName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: EColorConstants.authTextDarkBrown,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      '${sessions.length} ${sessions.length == 1 ? 'session' : 'sessions'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: EColorConstants.authPlaceholderGray,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: EColorConstants.authFieldBorder, height: 1),
          const SizedBox(height: 16),
          // Days and types display
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: dayToTypes.entries.map((entry) {
              final day = entry.key;
              final types = entry.value.toList();

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: EColorConstants.authFieldBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EColorConstants.authFieldBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      day,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: EColorConstants.authTextDarkBrown,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: types.map((type) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                EColorConstants.primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            type,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: EColorConstants.primaryColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
