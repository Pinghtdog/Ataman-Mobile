import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/ataman_button.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../injector.dart';
import '../../../booking/presentation/screens/booking_details_screen.dart';
import '../../../facility/data/repositories/facility_repository.dart';
import '../../data/models/triage_model.dart';
import '../../logic/triage_cubit.dart';
import '../../../home/presentation/screens/ataman_base_screen.dart';

class TriageResultScreen extends StatefulWidget {
  final TriageResult result;

  const TriageResultScreen({super.key, required this.result});

  @override
  State<TriageResultScreen> createState() => _TriageResultScreenState();
}

class _TriageResultScreenState extends State<TriageResultScreen> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.showSimulatedNotification(
        title: "Triage Analysis Ready",
        body: "Status: ${widget.result.urgency.name.toUpperCase()} - ${widget.result.actionText}",
      );
    });
  }

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
            if (widget.result.soapNote != null) ...[
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
        color: widget.result.urgencyColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: widget.result.urgencyColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(_getUrgencyIcon(), size: 80, color: widget.result.urgencyColor),
          const SizedBox(height: AppSizes.p16),
          Text(
            widget.result.urgency.name.toUpperCase(),
            style: AppTextStyles.h1.copyWith(color: widget.result.urgencyColor),
          ),
          const SizedBox(height: AppSizes.p8),
          Text(
            widget.result.actionText,
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
        if (widget.result.summaryForProvider != null) ...[
          _buildDetailTile("Summary", widget.result.summaryForProvider!, Icons.summarize_outlined),
          const SizedBox(height: AppSizes.p16),
        ],
        _buildDetailTile(
          "Recommended Facility", 
          widget.result.requiredCapability.replaceAll('_', ' '), 
          Icons.account_balance_outlined
        ),
        const SizedBox(height: AppSizes.p16),
        _buildDetailTile("Likely Specialty", widget.result.specialty, Icons.medical_services_outlined),
        if (widget.result.aiConfidence > 0) ...[
          const SizedBox(height: AppSizes.p16),
          _buildDetailTile(
            "AI Confidence", 
            "${(widget.result.aiConfidence * 100).toInt()}%", 
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
          _buildSoapField("Subjective", widget.result.soapNote!.subjective),
          _buildSoapField("Objective", widget.result.soapNote!.objective),
          _buildSoapField("Assessment", widget.result.soapNote!.assessment),
          _buildSoapField("Plan", widget.result.soapNote!.plan),
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
    if (widget.result.urgency == TriageUrgency.emergency) {
      buttonText = "Call Emergency Services (911)";
    } else if (widget.result.recommendedAction == 'TELEMEDICINE') {
      buttonText = "Start Telemedicine";
    }

    return AtamanButton(
      text: _isProcessing ? "Finding Facility..." : buttonText,
      color: widget.result.urgencyColor,
      onPressed: _isProcessing ? null : () => _handleProceed(context),
    );
  }

  Future<void> _handleProceed(BuildContext context) async {
    if (widget.result.recommendedAction == 'AMBULANCE_DISPATCH' || widget.result.urgency == TriageUrgency.emergency) {
      final Uri url = Uri.parse("tel:911");
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } else if (widget.result.recommendedAction == 'TELEMEDICINE') {
      _exitTriage(context);
    } else {
      setState(() => _isProcessing = true);
      
      try {
        final facility = await getIt<FacilityRepository>().findRecommendedFacility(widget.result.requiredCapability);
        
        if (!mounted) return;

        final cubit = context.read<TriageCubit?>();
        if (cubit != null && !cubit.isClosed) {
          cubit.reset();
        }

        if (facility != null) {
          // DIRECT NAVIGATION TO BOOKING DETAILS
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => BookingDetailsScreen(
                facility: facility,
                triageResult: widget.result,
              ),
            ),
            (route) => false,
          );
        } else {
          // Fallback to facility list if no specific match
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => AtamanBaseScreen(
                initialIndex: 1, 
                triageResult: widget.result,
              ),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error finding facility: $e")),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  void _exitTriage(BuildContext context) {
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
    switch (widget.result.urgency) {
      case TriageUrgency.emergency: return Icons.report_problem_rounded;
      case TriageUrgency.urgent: return Icons.error_outline_rounded;
      case TriageUrgency.routine: return Icons.check_circle_outline_rounded;
    }
  }
}
