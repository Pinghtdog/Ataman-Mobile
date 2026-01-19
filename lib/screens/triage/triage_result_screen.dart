import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/constants.dart';
import '../../data/models/triage_model.dart';
import '../../logic/triage/triage_cubit.dart';
import '../ataman_base_screen.dart';

class TriageResultScreen extends StatelessWidget {
  final TriageResult result;

  const TriageResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Triage Result"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            context.read<TriageCubit>().reset();
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.p24),
              decoration: BoxDecoration(
                color: result.urgencyColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.p24),
                border: Border.all(color: result.urgencyColor.withOpacity(0.3), width: 2),
              ),
              child: Column(
                children: [
                  Icon(
                    _getUrgencyIcon(result.urgency),
                    size: 80,
                    color: result.urgencyColor,
                  ),
                  const SizedBox(height: AppSizes.p16),
                  Text(
                    result.urgency.name.toUpperCase(),
                    style: AppTextStyles.h1.copyWith(color: result.urgencyColor),
                  ),
                  const SizedBox(height: AppSizes.p8),
                  Text(
                    result.actionText,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.p32),
            _buildDetailSection(
              "Your Symptoms Summary",
              result.rawSymptoms,
              Icons.description_outlined,
            ),
            const SizedBox(height: AppSizes.p16),
            _buildDetailSection(
              "Recommended Specialty",
              result.specialty,
              Icons.medical_services_outlined,
            ),
            if (result.reason != null) ...[
              const SizedBox(height: AppSizes.p16),
              _buildDetailSection(
                "Clinical Reasoning",
                result.reason!,
                Icons.info_outline_rounded,
              ),
            ],
            const SizedBox(height: AppSizes.p48),
            _buildActionButton(context),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                context.read<TriageCubit>().reset();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text("Go Back to Home"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppSizes.p16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSizes.p16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(content, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    String buttonText = "Book Appointment";
    if (result.urgency == TriageUrgency.emergency) {
      buttonText = "Call Emergency Services";
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () async {
          if (result.urgency == TriageUrgency.emergency) {
            final Uri launchUri = Uri(scheme: 'tel', path: '911');
            if (await canLaunchUrl(launchUri)) {
              await launchUrl(launchUri);
            }
          } else {
            // Navigate to Booking tab (Index 1) and reset Triage
            context.read<TriageCubit>().reset();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AtamanBaseScreen()),
              (route) => false,
            );
            // tab1
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: result.urgencyColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.p12),
          ),
        ),
        child: Text(
          buttonText,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  IconData _getUrgencyIcon(TriageUrgency urgency) {
    switch (urgency) {
      case TriageUrgency.emergency:
        return Icons.report_problem_rounded;
      case TriageUrgency.urgent:
        return Icons.error_outline_rounded;
      case TriageUrgency.nonUrgent:
        return Icons.check_circle_outline_rounded;
    }
  }
}
