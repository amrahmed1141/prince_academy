import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/l10n/app_strings.dart';
import 'package:prince_academy/core/widgets/directional_icon.dart';
import 'package:prince_academy/features/auth/data/models/app_user.dart';
import 'package:prince_academy/features/auth/domain/repositories/auth_repo.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_event.dart';

class AdminEditNamePage extends StatefulWidget {
  const AdminEditNamePage({super.key, required this.user});

  final UserModel user;

  @override
  State<AdminEditNamePage> createState() => _AdminEditNamePageState();
}

class _AdminEditNamePageState extends State<AdminEditNamePage> {
  late final TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = context.s;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.pleaseEnterName)),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await sl<AuthRepo>().updateProfile(
        fullName: name,
        phone: widget.user.phone ?? '',
      );

      if (!mounted) return;
      context.read<AuthBloc>().add(const AuthRefreshProfile());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.nameUpdated)),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.couldNotUpdateName}: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return Scaffold(
      backgroundColor: EColorConstants.authFieldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            DirectionalIcons.back(context),
            color: EColorConstants.authTextDarkBrown,
            textDirection: TextDirection.ltr,
          ),
        ),
        title: Text(
          s.editProfile,
          style: const TextStyle(
            color: EColorConstants.authTextDarkBrown,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _isSaving ? null : _save(),
            decoration: InputDecoration(
              labelText: s.fullName,
              prefixIcon: const Icon(Iconsax.user),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: EColorConstants.primaryColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: EColorConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      s.save,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
