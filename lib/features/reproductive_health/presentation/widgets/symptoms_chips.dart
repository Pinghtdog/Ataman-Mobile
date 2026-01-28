import 'package:ataman/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

class SymptomsChips extends StatefulWidget {
  const SymptomsChips({super.key});

  @override
  State<SymptomsChips> createState() => _SymptomsChipsState();
}

class _SymptomsChipsState extends State<SymptomsChips> {
  final List<String> _symptoms = [AppStrings.fever, AppStrings.cough, AppStrings.headache, AppStrings.soreThroat, AppStrings.other];
  final Set<String> _selectedSymptoms = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: _symptoms.map((symptom) {
        final isSelected = _selectedSymptoms.contains(symptom);
        return ChoiceChip(
          label: Text(symptom),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedSymptoms.add(symptom);
              } else {
                _selectedSymptoms.remove(symptom);
              }
            });
          },
          selectedColor: theme.primaryColor,
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
        );
      }).toList(),
    );
  }
}
