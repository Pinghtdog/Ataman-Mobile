import 'package:ataman/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

class AdditionalDetailsInput extends StatelessWidget {
  const AdditionalDetailsInput({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: 5,
      decoration: InputDecoration(
        hintText: AppStrings.additionalDetailsHint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
