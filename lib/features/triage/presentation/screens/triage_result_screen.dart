import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/constants.dart';
import '../../data/models/triage_model.dart';
import '../../logic/triage_cubit.dart';
import '../../../home/presentation/screens/ataman_base_screen.dart';

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
            if (result.summaryForProvider != null) ...[
              _buildDetailSection(
                "Summary",
                result.summaryForProvider!,
                Icons.summarize_outlined,
              ),
              const SizedBox(height: AppSizes.p16),
            ],
            _buildDetailSection(
              "Recommended Level",
              result.requiredCapability.replaceAll('_', ' '),
              Icons.account_balance_outlined,
            ),
            const SizedBox(height: AppSizes.p16),
            _buildDetailSection(
              "Specialty",
              result.specialty,
              Icons.medical_services_outlined,
            ),
            if (result.soapNote != null) ...[
              const SizedBox(height: AppSizes.p24),
              const Divider(),
              const SizedBox(height: AppSizes.p16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Provider Note (SOAP)", style: AppTextStyles.h3),
              ),
              const SizedBox(height: AppSizes.p16),
              _buildSoapSection("Subjective", result.soapNote!.subjective),
              _buildSoapSection("Objective", result.soapNote!.objective),
              _buildSoapSection("Assessment", result.soapNote!.assessment),
              _buildSoapSection("Plan", result.soapNote!.plan),
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

  Widget _buildSoapSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
          Text(content, style: AppTextStyles.bodyMedium),
        ],
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
    String buttonText = "Proceed to Action";
    if (result.urgency == TriageUrgency.emergency) {
      buttonText = "Call Emergency Services";
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () async {
          if (result.recommendedAction == 'AMBULANCE_DISPATCH' || result.urgency == TriageUrgency.emergency) {
            final Uri launchUri = Uri(scheme: 'tel', path: '911'); // Or Naga's local emergency number
            if (await canLaunchUrl(launchUri)) {
              await launchUrl(launchUri);
            }
          } else {
            // Handle other actions: TELEMEDICINE, BHC_APPOINTMENT, HOSPITAL_ER
            // For now, redirect to appropriate tab or screen
            context.read<TriageCubit>().reset();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AtamanBaseScreen()),
              (route) => false,
            );
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
      case TriageUrgency.routine:
        return Icons.check_circle_outline_rounded;
    }
  }
}
