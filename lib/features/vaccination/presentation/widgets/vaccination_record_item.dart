import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';

class VaccinationRecordItem extends StatelessWidget {
  final String vaccineName;
  final DateTime? dateGiven;
  final DateTime? nextDose;
  final String status;

  const VaccinationRecordItem({
    super.key,
    required this.vaccineName,
    this.dateGiven,
    this.nextDose,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/dd/yyyy');
    final bool isCompleted = status.toUpperCase() == 'COMPLETED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              vaccineName,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                dateGiven != null ? dateFormat.format(dateGiven!) : '-',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                isCompleted 
                    ? 'Completed' 
                    : (nextDose != null ? dateFormat.format(nextDose!) : 'None'),
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isCompleted 
                      ? AppColors.primary 
                      : (nextDose != null ? const Color(0xFFFF8C00) : AppColors.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
