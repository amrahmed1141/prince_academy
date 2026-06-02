import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_header.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_tab_selector.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_text_field.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_card.dart';
import 'package:prince_academy/features/admin/presentation/widgets/custom_bottom_navigation.dart';
import 'package:prince_academy/features/admin/presentation/widgets/session_card.dart';
import 'package:prince_academy/features/admin/presentation/pages/admin_profile.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  // Local state for coaches and sessions (Mock data)
  final List<Map<String, String>> _coaches = [
    {
      'name': 'Alex Johnson',
      'specialty': 'Muay Thai',
      'experience': '8 years',
      'sessions': '24',
      'rating': '4.9',
    },
    {
      'name': 'Maria Garcia',
      'specialty': 'BJJ',
      'experience': '6 years',
      'sessions': '18',
      'rating': '4.8',
    },
    {
      'name': 'John Smith',
      'specialty': 'Boxing',
      'experience': '10 years',
      'sessions': '32',
      'rating': '5.0',
    },
  ];

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

  void _addCoach(Map<String, String> coach) {
    setState(() {
      _coaches.insert(0, coach);
    });
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
                onAddCoach: _addCoach,
                onAddSession: _addSession,
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
  final List<Map<String, String>> coaches;
  final List<Map<String, String>> sessions;
  final Function(Map<String, String>) onAddCoach;
  final Function(Map<String, String>) onAddSession;

  const _AddInfoPage({
    required this.coaches,
    required this.sessions,
    required this.onAddCoach,
    required this.onAddSession,
  });

  @override
  State<_AddInfoPage> createState() => _AddInfoPageState();
}

class _AddInfoPageState extends State<_AddInfoPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Coach Form Controllers
  final _coachNameController = TextEditingController();
  final _coachSpecialtyController = TextEditingController();
  final _coachExperienceController = TextEditingController();
  String _selectedCoachSpecialty = 'Muay Thai';

  // Session Form Controllers
  final _sessionTitleController = TextEditingController();
  String _selectedSessionType = 'Striking';
  final _sessionDateController = TextEditingController();
  final _sessionDurationController = TextEditingController();
  String _selectedSessionCoach = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    if (widget.coaches.isNotEmpty) {
      _selectedSessionCoach = widget.coaches.first['name']!;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _coachNameController.dispose();
    _coachSpecialtyController.dispose();
    _coachExperienceController.dispose();
    _sessionTitleController.dispose();
    _sessionDateController.dispose();
    _sessionDurationController.dispose();
    super.dispose();
  }

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
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AdminTabSelector(
            labels: const ['Coaches', 'Sessions'],
            icons: const [Iconsax.user, Iconsax.calendar],
            initialIndex: _tabController.index,
            onChanged: (index) => _tabController.animateTo(index),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _CoachesListTab(
                nameController: _coachNameController,
                specialtyController: _coachSpecialtyController,
                experienceController: _coachExperienceController,
                selectedSpecialty: _selectedCoachSpecialty,
                onSpecialtyChanged: (v) => setState(() => _selectedCoachSpecialty = v),
                coaches: widget.coaches,
                onAdd: () {
                  if (_coachNameController.text.isNotEmpty) {
                    widget.onAddCoach({
                      'name': _coachNameController.text,
                      'specialty': _selectedCoachSpecialty,
                      'experience': _coachExperienceController.text.isEmpty ? '0 years' : _coachExperienceController.text,
                      'sessions': '0',
                      'rating': '5.0',
                    });
                    _coachNameController.clear();
                    _coachExperienceController.clear();
                    FocusScope.of(context).unfocus();
                  }
                },
              ),
              _SessionsListTab(
                titleController: _sessionTitleController,
                selectedType: _selectedSessionType,
                onTypeChanged: (v) => setState(() => _selectedSessionType = v),
                dateController: _sessionDateController,
                durationController: _sessionDurationController,
                selectedCoach: _selectedSessionCoach,
                coaches: widget.coaches,
                onCoachChanged: (v) => setState(() => _selectedSessionCoach = v),
                sessions: widget.sessions,
                onAdd: () {
                  if (_sessionTitleController.text.isNotEmpty) {
                    widget.onAddSession({
                      'title': _sessionTitleController.text,
                      'type': _selectedSessionType,
                      'coach': _selectedSessionCoach,
                      'date': _sessionDateController.text.isEmpty ? 'Today' : _sessionDateController.text,
                      'duration': _sessionDurationController.text.isEmpty ? '60 min' : _sessionDurationController.text,
                      'spots': '10 spots left',
                    });
                    _sessionTitleController.clear();
                    _sessionDateController.clear();
                    _sessionDurationController.clear();
                    FocusScope.of(context).unfocus();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CoachesListTab extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController specialtyController;
  final TextEditingController experienceController;
  final String selectedSpecialty;
  final ValueChanged<String> onSpecialtyChanged;
  final List<Map<String, String>> coaches;
  final VoidCallback onAdd;

  const _CoachesListTab({
    required this.nameController,
    required this.specialtyController,
    required this.experienceController,
    required this.selectedSpecialty,
    required this.onSpecialtyChanged,
    required this.coaches,
    required this.onAdd,
  });

  static const _specialties = ['Muay Thai', 'BJJ', 'MMA', 'Boxing'];

  @override
  Widget build(BuildContext context) {
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
                AdminTextField(
                  label: 'Full Name',
                  hint: 'Enter coach full name',
                  controller: nameController,
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
                        onTap: () => onSpecialtyChanged(s),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                AdminTextField(
                  label: 'Experience',
                  hint: 'e.g. 5 years',
                  controller: experienceController,
                ),
                const SizedBox(height: 20),
                _ActionButton(label: '+ Add Coach', onTap: onAdd),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: 'COACHES (${coaches.length})'),
          const SizedBox(height: 12),
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
                  name: coach['name']!,
                  specialty: coach['specialty']!,
                  experience: coach['experience']!,
                  sessionCount: coach['sessions']!,
                  rating: coach['rating'],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SessionsListTab extends StatelessWidget {
  final TextEditingController titleController;
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final TextEditingController dateController;
  final TextEditingController durationController;
  final String selectedCoach;
  final List<Map<String, String>> coaches;
  final ValueChanged<String> onCoachChanged;
  final List<Map<String, String>> sessions;
  final VoidCallback onAdd;

  const _SessionsListTab({
    required this.titleController,
    required this.selectedType,
    required this.onTypeChanged,
    required this.dateController,
    required this.durationController,
    required this.selectedCoach,
    required this.coaches,
    required this.onCoachChanged,
    required this.sessions,
    required this.onAdd,
  });

  static const _types = ['Striking', 'Grappling', 'Conditioning', 'Sparring'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'ADD SESSION'),
          const SizedBox(height: 10),
          _FormCard(
            child: Column(
              children: [
                AdminTextField(
                  label: 'Session Title',
                  hint: 'e.g. Morning Striking',
                  controller: titleController,
                ),
                const SizedBox(height: 16),
                const _FieldLabel(label: 'Type'),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _types.map((t) {
                      final selected = selectedType == t;
                      return _ChipItem(
                        label: t,
                        selected: selected,
                        onTap: () => onTypeChanged(t),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AdminTextField(
                        label: 'Date',
                        hint: 'Select date',
                        controller: dateController,
                        suffix: const Icon(Iconsax.calendar, size: 18, color: EColorConstants.authPlaceholderGray),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AdminTextField(
                        label: 'Duration',
                        hint: 'e.g. 60 min',
                        controller: durationController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _FieldLabel(label: 'Coach'),
                const SizedBox(height: 8),
                _CustomDropdown(
                  value: selectedCoach,
                  items: coaches.map((c) => c['name']!).toList(),
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
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sessions.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SessionCard(
                  title: session['title']!,
                  type: session['type']!,
                  coach: session['coach']!,
                  date: session['date']!,
                  duration: session['duration']!,
                  spots: session['spots']!,
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
            color: selected ? EColorConstants.primaryColor : EColorConstants.authFieldBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? EColorConstants.primaryColor : EColorConstants.authFieldBorder,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : EColorConstants.authTextDarkBrown,
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
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: EColorConstants.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: EColorConstants.authFieldBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EColorConstants.authFieldBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? (items.isNotEmpty ? items.first : null) : value,
          isExpanded: true,
          icon: const Icon(Iconsax.arrow_down_1, size: 20, color: EColorConstants.authPlaceholderGray),
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
