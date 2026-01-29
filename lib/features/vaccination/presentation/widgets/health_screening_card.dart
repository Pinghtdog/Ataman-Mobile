import 'package:ataman/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

class HealthScreeningCard extends StatelessWidget {
  final bool hasFever;
  final ValueChanged<bool> onChanged;

  const HealthScreeningCard({
    super.key,
    required this.hasFever,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8.0),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              AppStrings.doYouHaveFever,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Row(
              children: [
                _buildChoiceChip(AppStrings.yes, hasFever, () => onChanged(true)),
                const SizedBox(width: 8),
                _buildChoiceChip(AppStrings.no, !hasFever, () => onChanged(false)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
