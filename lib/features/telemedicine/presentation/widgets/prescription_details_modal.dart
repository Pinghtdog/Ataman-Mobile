import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/services/pdf_service.dart';
import '../../../medical_records/data/models/prescription_model.dart';

class PrescriptionDetailsModal extends StatefulWidget {
  final Prescription prescription;

  const PrescriptionDetailsModal({super.key, required this.prescription});

  @override
  State<PrescriptionDetailsModal> createState() => _PrescriptionDetailsModalState();
}

class _PrescriptionDetailsModalState extends State<PrescriptionDetailsModal> {
  bool _isDownloading = false;
  late final String _qrData;

  @override
  void initState() {
    super.initState();
    // Generate QR Data ONCE in initState to keep it stable
    _qrData = jsonEncode({
      "type": "PRESCRIPTION_ID",
      "data": widget.prescription.id,
      "generated_at": DateTime.now().toIso8601String(),
    });
  }

  Future<void> _handleDownload() async {
    setState(() => _isDownloading = true);
    try {
      await PdfService.generatePrescriptionPdf(widget.prescription);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to generate PDF: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

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
                data: _qrData, // Using the stable QR data
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
          
          _buildInfoRow("Medication", widget.prescription.medicationName, isBold: true),
          _buildInfoRow("Dosage", widget.prescription.dosage),
          _buildInfoRow("Doctor", widget.prescription.doctorName),
          _buildInfoRow("Valid Until", DateFormat('MMM dd, yyyy').format(widget.prescription.validUntil)),
          
          if (widget.prescription.instructions != null && widget.prescription.instructions!.isNotEmpty) ...[
            const SizedBox(height: AppSizes.p16),
            Text(
              "Instructions",
              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSizes.p4),
            Text(
              widget.prescription.instructions!,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
          
          const SizedBox(height: AppSizes.p32),
          AtamanButton(
            text: _isDownloading ? "Generating PDF..." : "Download PDF",
            onPressed: _isDownloading ? null : _handleDownload,
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
