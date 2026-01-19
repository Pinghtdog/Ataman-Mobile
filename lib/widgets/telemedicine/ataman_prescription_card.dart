import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/constants.dart';
import '../../data/models/prescription_model.dart';

class AtamanPrescriptionCard extends StatelessWidget {
  final Prescription prescription;
  final VoidCallback? onTap;

  const AtamanPrescriptionCard({
    super.key,
    required this.prescription,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.p12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.medication_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: AppSizes.p16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${prescription.medicationName} ${prescription.dosage}",
                        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${prescription.doctorName} • Valid until ${DateFormat('MMM dd').format(prescription.validUntil)}",
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
