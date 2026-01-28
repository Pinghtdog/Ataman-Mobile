import 'package:ataman/core/constants/app_strings.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class PatientSelection extends StatelessWidget {
  const PatientSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          _buildPatientCard(context, AppStrings.myself, isSelected: true),
          const SizedBox(width: 12),
          _buildPatientCard(context, AppStrings.miguelSon),
          const SizedBox(width: 12),
          _buildAddPatientCard(),
        ],
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, String name, {bool isSelected = false}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? theme.primaryColor.withAlpha(26) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? theme.primaryColor : Colors.grey[300]!),
      ),
      child: Column(
        children: [
          CircleAvatar(backgroundColor: isSelected ? theme.primaryColor : Colors.grey[300]),
          const SizedBox(height: 8),
          Text(name),
        ],
      ),
    );
  }

  Widget _buildAddPatientCard() {
    return DottedBorder(
      borderType: BorderType.RRect,
      radius: const Radius.circular(12),
      color: Colors.grey[400]!,
      strokeWidth: 1,
      dashPattern: const [4, 4],
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.add, color: Colors.grey),
      ),
    );
  }
}
