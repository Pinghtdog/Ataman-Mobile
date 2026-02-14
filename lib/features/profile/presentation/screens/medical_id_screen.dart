import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/services/pdf_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../triage/data/models/triage_model.dart';
import '../../../triage/logic/triage_cubit.dart';
import '../../../../injector.dart';
import '../../../triage/domain/repositories/i_triage_repository.dart';

class MedicalIdScreen extends StatelessWidget {
  final UserModel user;

  const MedicalIdScreen({super.key, required this.user});

  Future<void> _generatePdf(BuildContext context) async {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Fetching latest medical data...")),
    );

    try {
      final history = await getIt<ITriageRepository>().getHistory();
      Map<String, dynamic>? triageData;

      if (history.isNotEmpty) {
        final latest = history.first;
        triageData = {
          'priority': latest.urgency.name.toUpperCase(),
          'complaint': latest.rawSymptoms,
          'recommendation': latest.recommendedAction.replaceAll('_', ' '),
        };
      }

      await PdfService.previewMedicalIdForm(user, triageResult: triageData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error generating PDF: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Standardized QR Data for Web Portal Sync
    final String qrData = jsonEncode({
      "type": "PATIENT_ID",
      "data": user.id,
      "generated_at": DateTime.now().toIso8601String(),
    });

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Digital Medical ID",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // The "Medical Card"
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSizes.p32),
                    const AtamanAvatar(radius: 50),
                    const SizedBox(height: AppSizes.p16),
                    Text(
                      user.fullName.toUpperCase(),
                      style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "Naga City Health ID: ${user.id.substring(0, 8).toUpperCase()}",
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: AppSizes.p24),
                    
                    // The QR Code (Synced with PDF)
                    Container(
                      padding: const EdgeInsets.all(AppSizes.p16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: QrImageView(
                        data: qrData, // Synced Standardized Data
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
                    
                    const SizedBox(height: 24),
                    
                    // Quick-Scan Medical Info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniInfo("BLOOD", user.bloodType ?? "N/A"),
                          _buildVerticalDivider(),
                          _buildMiniInfo("GENDER", user.gender ?? "N/A"),
                          _buildVerticalDivider(),
                          _buildMiniInfo("BRGY", user.barangay ?? "N/A"),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppSizes.p32),
                    
                    // Emergency Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSizes.p16),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(AppSizes.radiusLarge),
                          bottomRight: Radius.circular(AppSizes.radiusLarge),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "IN CASE OF EMERGENCY",
                            style: TextStyle(
                              color: Colors.white, 
                              fontSize: 10, 
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${user.emergencyContactName ?? 'No Contact'} • ${user.emergencyContactPhone ?? ''}",
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 14, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.p32),
              
              // Custom Medical ID Action
              AtamanButton(
                text: "Generate Medical Record",
                isOutlined: true,
                color: Colors.white,
                icon: Icons.assignment_ind_outlined,
                onPressed: () => _generatePdf(context),
              ),
              
              const SizedBox(height: AppSizes.p20),
              const Text(
                "Present this QR code or the generated PDF\nto any Naga City Health facility for instant retrieval.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: AppSizes.p40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniInfo(String label, String value) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: Colors.grey[300]);
  }
}
