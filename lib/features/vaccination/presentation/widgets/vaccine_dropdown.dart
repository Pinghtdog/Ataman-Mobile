import 'package:ataman/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

class VaccineDropdown extends StatelessWidget {
  const VaccineDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        initialValue: AppStrings.influenzaFluVaccine,
        items: [AppStrings.influenzaFluVaccine, AppStrings.pneumococcal23, AppStrings.antiRabies]
            .map((label) => DropdownMenuItem(
                  child: Text(label),
                  value: label,
                ))
            .toList(),
        onChanged: (value) {},
      ),
    );
  }
}
