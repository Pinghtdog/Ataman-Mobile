import 'package:flutter/material.dart';
import 'package:ataman/core/constants/app_strings.dart';

enum VaccineCategory { all, kids, adults, seniors }

class FilterChips extends StatelessWidget {
  final VaccineCategory selectedCategory;
  final ValueChanged<VaccineCategory> onCategoryChanged;

  const FilterChips({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: AppStrings.all,
            category: VaccineCategory.all,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: AppStrings.kids,
            category: VaccineCategory.kids,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: AppStrings.adults,
            category: VaccineCategory.adults,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: AppStrings.seniors,
            category: VaccineCategory.seniors,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VaccineCategory category,
  }) {
    final isSelected = selectedCategory == category;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onCategoryChanged(category);
        }
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.black,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
