import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/image_string.dart';
import 'package:prince_academy/core/constants/sizes.dart';

class SocialButton extends StatefulWidget {
  const SocialButton({super.key});

  @override
  State<SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<SocialButton> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(100)),
          child: IconButton(
              onPressed: () {},
              icon: const Image(
                  width: EFontSizeConstants.iconMd,
                  height: EFontSizeConstants.iconMd,
                  image: AssetImage(EImages.googleLogo))),
        ),
        const SizedBox(
          width: 20,
        ),
        Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(100)),
          child: IconButton(
              onPressed: () {},
              icon: const Image(
                  width: EFontSizeConstants.iconMd,
                  height: EFontSizeConstants.iconMd,
                  image: AssetImage(EImages.facebookLogo))),
        ),
      ],
    );
  }
}
