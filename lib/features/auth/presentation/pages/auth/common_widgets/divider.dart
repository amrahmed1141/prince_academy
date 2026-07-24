import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/text.dart';

class CustomDivider extends StatelessWidget {
  const CustomDivider({super.key, required int indent});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          height: 100,
        ),
        Flexible(
          child: Divider(
            thickness: 0.5,
            color: Colors.grey,
            indent: 60,
            endIndent: 5,
          ),
        ),
        Text(
          ETexts.signinWithLabel,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const Flexible(
          child: Divider(
            thickness: 0.5,
            color: Colors.grey,
            indent: 5,
            endIndent: 60,
          ),
        ),
      ],
    );
  }
}
