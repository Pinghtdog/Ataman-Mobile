import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../medical_records/data/models/prescription_model.dart';

class PrescriptionDetailsModal extends StatelessWidget {
  final Prescription prescription;

  const PrescriptionDetailsModal({super.key, required this.prescription});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLarge)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Prescription Details",
                style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p24),
          
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppSizes.p16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: prescription.id,
                version: QrVersions.auto,
                size: 200.0,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.primary,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.p24),
          
          _buildInfoRow("Medication", prescription.medicationName, isBold: true),
          _buildInfoRow("Dosage", prescription.dosage),
          _buildInfoRow("Doctor", prescription.doctorName),
          _buildInfoRow("Valid Until", DateFormat('MMM dd, yyyy').format(prescription.validUntil)),
          
          if (prescription.instructions != null && prescription.instructions!.isNotEmpty) ...[
            const SizedBox(height: AppSizes.p16),
            Text(
              "Instructions",
              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSizes.p4),
            Text(
              prescription.instructions!,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
          
          const SizedBox(height: AppSizes.p32),
          AtamanButton(
            text: "Download PDF",
            onPressed: () {
              // TODO: Implement PDF Download
            },
          ),
          const SizedBox(height: AppSizes.p16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
