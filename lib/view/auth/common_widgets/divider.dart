import 'package:flutter/material.dart';
import 'package:prince_academy/utils/constants/text.dart';
import 'package:prince_academy/utils/helpers/helper_function.dart';

class CustomDivider extends StatelessWidget {
  const CustomDivider({super.key, required int indent});

  @override
  Widget build(BuildContext context) {
    final dark = EHelperFunction.isDarkMode(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          height: 100,
        ),
        Flexible(
          child: Divider(
            thickness: 0.5,
            color: dark ? Colors.white.withOpacity(0.5) : Colors.grey,
            indent: 60,
            endIndent: 5,
          ),
        ),
        Text(
          ETexts.signinWithLabel,
          style: Theme.of(context).textTheme.labelMedium,
        ),
       const Flexible(
          child:  Divider(
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
