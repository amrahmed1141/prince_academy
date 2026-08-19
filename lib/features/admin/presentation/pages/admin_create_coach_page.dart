import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/presentation/bloc/admin_home/admin_home_bloc.dart';
import 'package:prince_academy/features/admin/presentation/bloc/admin_home/admin_home_event.dart';
import 'package:prince_academy/features/admin/presentation/bloc/admin_home/admin_home_state.dart';
import 'package:prince_academy/features/admin/presentation/pages/tracking/all_coaches_page.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_form_styles.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_smooth_scroll.dart';
import 'package:prince_academy/features/admin/presentation/widgets/create_choice_chips.dart';
import 'package:prince_academy/features/admin/presentation/widgets/create_photo_avatar.dart';

class AdminCreateCoachPage extends StatefulWidget {
  const AdminCreateCoachPage({super.key});

  static Future<void> open(BuildContext context) {
    final bloc = context.read<AdminHomeBloc>();
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const AdminCreateCoachPage(),
        ),
      ),
    );
  }

  @override
  State<AdminCreateCoachPage> createState() => _AdminCreateCoachPageState();
}

class _AdminCreateCoachPageState extends State<AdminCreateCoachPage> {
  static const _defaultSpecialties = [
    'Muay Thai',
    'BJJ',
    'Wrestling',
    'Boxing',
    'MMA',
    'Strength & Conditioning',
  ];

  final _nameController = TextEditingController();
  final _customSpecialtyController = TextEditingController();
  final Set<String> _selectedSpecialties = {'Muay Thai'};
  final List<String> _customSpecialties = [];
  String? _imagePath;
  String? _duplicateWarning;

  @override
  void dispose() {
    _nameController.dispose();
    _customSpecialtyController.dispose();
    super.dispose();
  }

  List<String> get _allSpecialties => [
        ..._defaultSpecialties,
        ..._customSpecialties,
      ];

  void _onNameChanged(String value, List<String> existingNames) {
    final query = value.trim().toLowerCase();
    String? warning;
    if (query.isNotEmpty) {
      for (final name in existingNames) {
        if (name.toLowerCase() == query) {
          warning = '$name already exists';
          break;
        }
      }
    }
    if (warning != _duplicateWarning) {
      setState(() => _duplicateWarning = warning);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _imagePath = image.path);
      }
    } on MissingPluginException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image picker not available. Please rebuild the app.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _toggleSpecialty(String specialty) {
    setState(() {
      if (_selectedSpecialties.contains(specialty)) {
        if (_selectedSpecialties.length > 1) {
          _selectedSpecialties.remove(specialty);
        }
      } else {
        _selectedSpecialties.add(specialty);
      }
    });
  }

  Future<void> _addCustomSpecialty() async {
    _customSpecialtyController.clear();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Add Specialty',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
            color: EColorConstants.authTextDarkBrown,
          ),
        ),
        content: TextField(
          controller: _customSpecialtyController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            color: EColorConstants.authTextDarkBrown,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. Kickboxing',
            hintStyle: const TextStyle(
              fontSize: 13,
              color: EColorConstants.authPlaceholderGray,
              fontFamily: 'Poppins',
            ),
            filled: true,
            fillColor: EColorConstants.authFieldBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: EColorConstants.primaryColor,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          TextButton(
            onPressed: () {
              final text = _customSpecialtyController.text.trim();
              if (text.isNotEmpty) Navigator.pop(ctx, text);
            },
            child: const Text(
              'Add',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final lower = result.toLowerCase();
      final alreadyExists =
          _allSpecialties.any((s) => s.toLowerCase() == lower);
      if (!alreadyExists) {
        setState(() {
          _customSpecialties.add(result);
          _selectedSpecialties.add(result);
        });
      } else if (!_selectedSpecialties.contains(result)) {
        final existing =
            _allSpecialties.firstWhere((s) => s.toLowerCase() == lower);
        setState(() => _selectedSpecialties.add(existing));
      }
    }
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a coach name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    context.read<AdminHomeBloc>().add(
          AddCoachSubmitted(
            name: name,
            specialty: _selectedSpecialties.join(', '),
            imagePath: _imagePath,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminHomeBloc, AdminHomeState>(
      listenWhen: (prev, next) => prev.message != next.message,
      listener: (context, state) {
        final message = state.message;
        if (message == null) return;

        if (state.messageType == AdminHomeMessageType.success &&
            message.contains('Coach added')) {
          _nameController.clear();
          setState(() {
            _imagePath = null;
            _duplicateWarning = null;
            _selectedSpecialties
              ..clear()
              ..add('Muay Thai');
            _customSpecialties.clear();
          });
          FocusScope.of(context).unfocus();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Coach added'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'View all',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AllCoachesPage(),
                    ),
                  );
                },
              ),
            ),
          );
        } else if (state.messageType == AdminHomeMessageType.error &&
            message.contains('Failed to add coach')) {
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
        final existingNames =
            admin.coaches.map((coach) => coach.name).toList();

        return Scaffold(
          backgroundColor: EColorConstants.authFieldBackground,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: const BackButton(
              color: EColorConstants.authTextDarkBrown,
            ),
            title: const Text(
              'New coach',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: EColorConstants.authTextDarkBrown,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          body: AdminSmoothScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                // Centered photo avatar
                Center(
                  child: Column(
                    children: [
                      CreatePhotoAvatar(
                        imagePath: _imagePath,
                        onTap: _pickImage,
                        size: 100,
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickImage,
                        child: const Text(
                          'Change Photo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: EColorConstants.primaryColor,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Form card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: AdminFormStyles.formCardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Full Name',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: EColorConstants.authTextDarkBrown,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        onChanged: (value) =>
                            _onNameChanged(value, existingNames),
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                          color: EColorConstants.authTextDarkBrown,
                        ),
                        decoration: AdminFormStyles.fieldDecoration(
                          hintText: 'e.g. Jane Doe',
                        ),
                      ),
                      if (_duplicateWarning != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _duplicateWarning!,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      const Text(
                        'Areas of Expertise',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: EColorConstants.authTextDarkBrown,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final specialty in _allSpecialties)
                            _SpecialtyToggleChip(
                              label: specialtyChipLabel(specialty),
                              selected:
                                  _selectedSpecialties.contains(specialty),
                              onTap: () => _toggleSpecialty(specialty),
                            ),
                          _AddCustomChip(onTap: _addCustomSpecialty),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: admin.isAddingCoach ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EColorConstants.primaryColor,
                    disabledBackgroundColor:
                        EColorConstants.authPlaceholderGray,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: admin.isAddingCoach
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Add coach',
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

class _SpecialtyToggleChip extends StatelessWidget {
  const _SpecialtyToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? EColorConstants.primaryColor : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? EColorConstants.primaryColor
                  : const Color(0xFFE0E0E0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : EColorConstants.authTextDarkBrown,
                  fontFamily: 'Poppins',
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                const Icon(Icons.close, size: 14, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCustomChip extends StatelessWidget {
  const _AddCustomChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 16, color: EColorConstants.primaryColor),
              SizedBox(width: 4),
              Text(
                'Custom',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: EColorConstants.authTextDarkBrown,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
