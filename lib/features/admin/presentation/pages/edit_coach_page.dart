import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/features/admin/data/models/coach_model.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/admin/presentation/widgets/specialty_chip.dart';

class EditCoachPage extends StatefulWidget {
  final CoachModel coach;

  const EditCoachPage({
    super.key,
    required this.coach,
  });

  @override
  State<EditCoachPage> createState() => _EditCoachPageState();
}

class _EditCoachPageState extends State<EditCoachPage> {
  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;
  late String _selectedSpecialty;
  String? _localImagePath;
  bool _isSaving = false;

  static const _coachSpecialties = [
    'Muay Thai',
    'BJJ',
    'Wrestling',
    'Boxing',
    'MMA',
    'Strength & Conditioning',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.coach.name);
    _nameFocusNode = FocusNode();
    _selectedSpecialty = widget.coach.specialty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _localImagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleSaveChanges() async {
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

    setState(() {
      _isSaving = true;
    });

    try {
      String? finalPhotoUrl = widget.coach.photoUrl;

      // Upload new photo if selected
      if (_localImagePath != null) {
        final file = File(_localImagePath!);
        final fileName = _localImagePath!.split('/').last;
        finalPhotoUrl = await sl<CoachRepository>().uploadCoachPhoto(file, fileName);

        // Delete old photo if it exists to save space (non-blocking)
        if (widget.coach.photoUrl != null && widget.coach.photoUrl!.isNotEmpty) {
          sl<CoachRepository>().deleteCoachPhoto(widget.coach.photoUrl!).catchError((e) {
            debugPrint('Failed to delete old photo: $e');
          });
        }
      }

      // Update database row
      await sl<CoachRepository>().updateCoach(
        coachId: widget.coach.id,
        name: name,
        specialty: _selectedSpecialty,
        photoUrl: finalPhotoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coach updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update coach: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColorConstants.authFieldBackground,
      appBar: AppBar(
        title: const Text(
          'Edit Coach',
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
        child: Column(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: EColorConstants.primaryColor,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _localImagePath != null
                        ? ClipOval(
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: Image.file(
                                File(_localImagePath!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        : CoachAvatar(
                            name: widget.coach.name,
                            photoUrl: widget.coach.photoUrl,
                            radius: 50,
                          ),
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: EColorConstants.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.camera,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Iconsax.image, size: 16, color: EColorConstants.primaryColor),
              label: const Text(
                'Change Photo',
                style: TextStyle(
                  color: EColorConstants.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const SizedBox(height: 24),
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
                    'Coach Name',
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
                    focusNode: _nameFocusNode,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      color: EColorConstants.authTextDarkBrown,
                    ),
                    decoration: _inputDecoration(
                      hint: 'Enter coach name',
                      prefixIcon: Iconsax.user,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Specialty',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: EColorConstants.authTextDarkBrown,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedSpecialty,
                    isExpanded: true,
                    decoration: _inputDecoration(
                      hint: 'Select specialty',
                      prefixIcon: Iconsax.category,
                    ),
                    selectedItemBuilder: (context) {
                      return _coachSpecialties.map((specialty) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            SpecialtyChip.displayLabel(specialty),
                            style: const TextStyle(
                              fontSize: 14,
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
                          style: const TextStyle(fontFamily: 'Poppins'),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedSpecialty = value;
                        });
                      }
                    },
                  ),
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
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 13,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
}
