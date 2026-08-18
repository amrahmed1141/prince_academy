import 'dart:io';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';

/// Compact tap-to-pick coach photo for the create-coach form.
class CreatePhotoAvatar extends StatelessWidget {
  const CreatePhotoAvatar({
    super.key,
    this.imagePath,
    required this.onTap,
    this.size = 72,
  });

  final String? imagePath;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    return Semantics(
      button: true,
      label: hasImage ? 'Change coach photo' : 'Add coach photo',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: size + 8,
          height: size + 8,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF3EDE4),
                  border: Border.all(
                    color: EColorConstants.authFieldBorder,
                    width: 1.5,
                  ),
                  image: hasImage
                      ? DecorationImage(
                          image: FileImage(File(imagePath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: hasImage
                    ? null
                    : const Icon(
                        Iconsax.user,
                        size: 28,
                        color: EColorConstants.primaryColor,
                      ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: EColorConstants.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Iconsax.camera,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
