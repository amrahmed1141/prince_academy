import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
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
  static const _coachSpecialties = [
    'Muay Thai',
    'BJJ',
    'Wrestling',
    'Boxing',
    'MMA',
    'Strength & Conditioning',
  ];

  final _nameController = TextEditingController();
  String _selectedSpecialty = 'Muay Thai';
  String? _imagePath;
  String? _duplicateWarning;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

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
            specialty: _selectedSpecialty,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CreatePhotoAvatar(
                      imagePath: _imagePath,
                      onTap: _pickImage,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            onChanged: (value) =>
                                _onNameChanged(value, existingNames),
                            textCapitalization: TextCapitalization.words,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              color: EColorConstants.authTextDarkBrown,
                            ),
                            decoration: AdminFormStyles.fieldDecoration(
                              hintText: 'Coach name',
                              prefixIcon: Iconsax.user,
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
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AdminFormStyles.fieldLabel('Specialty'),
                const SizedBox(height: 8),
                CreateChoiceChipWrap<String>(
                  items: _coachSpecialties,
                  selected: _selectedSpecialty,
                  onSelected: (value) {
                    setState(() => _selectedSpecialty = value);
                  },
                  labelOf: specialtyChipLabel,
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
