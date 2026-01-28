import 'package:ataman/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

class HealthScreeningCard extends StatelessWidget {
  const HealthScreeningCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(AppStrings.doYouHaveFever),
            Row(
              children: [
                _buildChoiceChip(AppStrings.yes, false),
                const SizedBox(width: 8),
                _buildChoiceChip(AppStrings.no, true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {},
      backgroundColor: isSelected ? Colors.teal : Colors.grey[200],
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      shape: const StadiumBorder(),
    );
  }
}
