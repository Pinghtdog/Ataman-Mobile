import 'package:flutter/material.dart';
import 'package:ataman/core/constants/app_strings.dart';

class FilterChips extends StatelessWidget {
  const FilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildFilterChip(label: AppStrings.all, isSelected: true),
        _buildFilterChip(label: AppStrings.kids),
        _buildFilterChip(label: AppStrings.adults),
        _buildFilterChip(label: AppStrings.seniors),
      ],
    );
  }

  Widget _buildFilterChip({required String label, bool isSelected = false}) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {},
      backgroundColor: isSelected ? Colors.black : Colors.grey[200],
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
    );
  }
}
