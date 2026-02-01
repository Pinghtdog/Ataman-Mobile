import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/ataman_button.dart';
import '../../data/models/triage_model.dart';
import '../../logic/triage_cubit.dart';
import '../../../home/presentation/screens/ataman_base_screen.dart';

class TriageResultScreen extends StatelessWidget {
  final TriageResult result;

  const TriageResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Triage Assessment"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _exitTriage(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          children: [
            _buildUrgencyHeader(),
            const SizedBox(height: AppSizes.p32),
            _buildDetails(),
            if (result.soapNote != null) ...[
              const SizedBox(height: AppSizes.p24),
              _buildSoapNote(),
            ],
            const SizedBox(height: AppSizes.p48),
            _buildActionButton(context),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _exitTriage(context),
              child: const Text("Return to Home"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgencyHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p24),
      decoration: BoxDecoration(
        color: result.urgencyColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: result.urgencyColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(_getUrgencyIcon(), size: 80, color: result.urgencyColor),
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
    );
  }

  Widget _buildDetails() {
    return Column(
      children: [
        if (result.summaryForProvider != null) ...[
          _buildDetailTile("Summary", result.summaryForProvider!, Icons.summarize_outlined),
          const SizedBox(height: AppSizes.p16),
        ],
        _buildDetailTile(
          "Recommended Facility", 
          result.requiredCapability.replaceAll('_', ' '), 
          Icons.account_balance_outlined
        ),
        const SizedBox(height: AppSizes.p16),
        _buildDetailTile("Likely Specialty", result.specialty, Icons.medical_services_outlined),
        if (result.aiConfidence > 0) ...[
          const SizedBox(height: AppSizes.p16),
          _buildDetailTile(
            "AI Confidence", 
            "\${(result.aiConfidence * 100).toInt()}%", 
            Icons.verified_user_outlined
          ),
        ],
      ],
    );
  }

  Widget _buildSoapNote() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text("Provider SOAP Note", style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 16),
          _buildSoapField("Subjective", result.soapNote!.subjective),
          _buildSoapField("Objective", result.soapNote!.objective),
          _buildSoapField("Assessment", result.soapNote!.assessment),
          _buildSoapField("Plan", result.soapNote!.plan),
        ],
      ),
    );
  }

  Widget _buildSoapField(String label, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
          Text(content, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildDetailTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary.withOpacity(0.7)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    String buttonText = "Proceed to Booking";
    if (result.urgency == TriageUrgency.emergency) {
      buttonText = "Call Emergency Services (911)";
    } else if (result.recommendedAction == 'TELEMEDICINE') {
      buttonText = "Start Telemedicine";
    }

    return AtamanButton(
      text: buttonText,
      color: result.urgencyColor,
      onPressed: () => _handleProceed(context),
    );
  }

  Future<void> _handleProceed(BuildContext context) async {
    if (result.recommendedAction == 'AMBULANCE_DISPATCH' || result.urgency == TriageUrgency.emergency) {
      final Uri url = Uri.parse("tel:911");
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } else if (result.recommendedAction == 'TELEMEDICINE') {
      _exitTriage(context);
    } else {
      // Safely check if the cubit is available before calling reset
      final cubit = context.read<TriageCubit?>();
      if (cubit != null && !cubit.isClosed) {
        cubit.reset();
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => AtamanBaseScreen(
            initialIndex: 1, 
            triageResult: result,
          ),
        ),
        (route) => false,
      );
    }
  }

  void _exitTriage(BuildContext context) {
    // Safely check if the cubit is available before calling reset
    final cubit = context.read<TriageCubit?>();
    if (cubit != null && !cubit.isClosed) {
      cubit.reset();
    }
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AtamanBaseScreen()),
      (route) => false,
    );
  }

  IconData _getUrgencyIcon() {
    switch (result.urgency) {
      case TriageUrgency.emergency: return Icons.report_problem_rounded;
      case TriageUrgency.urgent: return Icons.error_outline_rounded;
      case TriageUrgency.routine: return Icons.check_circle_outline_rounded;
    }
  }
}
