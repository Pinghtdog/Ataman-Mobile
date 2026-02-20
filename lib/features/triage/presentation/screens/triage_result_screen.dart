import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/pdf_service.dart';
import '../../../../core/services/philhealth_service.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injector.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../../booking/presentation/screens/booking_details_screen.dart';
import '../../../facility/data/repositories/facility_repository.dart';
import '../../../facility/data/models/facility_model.dart';
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
  PhilHealthBenefit? _matchedBenefit;
  List<Map<String, String>>? _matchedFacilities;
  Map<String, dynamic>? _eligibility;

  @override
  void initState() {
    super.initState();
    _runPhilHealthCheck();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.showSimulatedNotification(
        title: "Triage Analysis Ready",
        body: "${widget.result.urgency.name.toUpperCase()}: ${widget.result.reason ?? 'Assessment complete'}",
      );
    });
  }

  void _runPhilHealthCheck() {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      final philHealthService = getIt<PhilHealthService>();
      
      final match = philHealthService.matchBenefitToCondition(
        widget.result.summaryForProvider ?? widget.result.rawSymptoms
      );
      
      final eligibilityStatus = philHealthService.checkEligibilityStatus(authState.profile!);
      
      setState(() {
        if (match != null) {
          _matchedBenefit = match['benefit'] as PhilHealthBenefit;
          _matchedFacilities = match['facilities'] as List<Map<String, String>>;
        }
        
        _eligibility = {
          'isEligible': eligibilityStatus == "Active Member",
          'status': eligibilityStatus,
          'reason': eligibilityStatus == "Active Member" 
              ? "Membership verified via PhilHealth ID." 
              : "Verification of membership is required for full benefits.",
        };
      });
    }
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
            if (_matchedBenefit != null) ...[
              const SizedBox(height: AppSizes.p24),
              _buildPhilHealthCard(),
            ],
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

  Widget _buildPhilHealthCard() {
    if (_matchedBenefit == null || _eligibility == null) return const SizedBox.shrink();

    final isEligible = _eligibility!['isEligible'] as bool;

    return Container(
      padding: const EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.primary.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
              const SizedBox(width: 12),
              const Text("PhilHealth Coverage", style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _matchedBenefit!.name,
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          Text(
            "Potential Coverage: ${_matchedBenefit!.amount}",
            style: AppTextStyles.h2.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(_matchedBenefit!.requirements, style: AppTextStyles.bodySmall),
          
          if (_matchedFacilities != null && _matchedFacilities!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              "Accredited in Naga: ${_matchedFacilities!.map((f) => f['name']).join(', ')}",
              style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic, color: AppColors.primary),
            ),
          ],

          const Divider(height: 32, thickness: 1),
          Row(
            children: [
              Icon(isEligible ? Icons.verified_user : Icons.warning_amber_rounded, color: isEligible ? Colors.green : Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text("Eligibility: ${_eligibility!['status']}", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
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
            widget.result.reason ?? "Assessment Complete",
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
        _buildDetailTile(
          "Action Required", 
          widget.result.recommendedAction.replaceAll('_', ' '),
          Icons.pending_actions_rounded
        ),
        const SizedBox(height: AppSizes.p16),
        _buildDetailTile(
          "Facility Level", 
          widget.result.requiredCapability.replaceAll('_', ' ').toLowerCase(),
          Icons.account_balance_outlined
        ),
        const SizedBox(height: AppSizes.p16),
        _buildDetailTile("Likely Specialty", widget.result.specialty, Icons.medical_services_outlined),
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
              Text("AI Assessment Summary", style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 16),
          _buildSoapField("Subjective Symptoms", widget.result.soapNote!.subjective),
          _buildSoapField("Assessment", widget.result.soapNote!.assessment),
          _buildSoapField("Proposed Plan", widget.result.soapNote!.plan),
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
    String buttonText = "Find Facility";
    
    switch (widget.result.recommendedAction) {
      case 'AMBULANCE_DISPATCH':
        buttonText = "Call 911 Immediately";
        break;
      case 'HOSPITAL_ER':
        buttonText = "Locate Nearest ER";
        break;
      case 'TELEMEDICINE':
        buttonText = "Start Telemedicine Now";
        break;
      case 'BHC_APPOINTMENT':
        buttonText = "Book BHC Appointment";
        break;
    }

    return AtamanButton(
      text: _isProcessing ? "Processing..." : buttonText,
      color: widget.result.urgencyColor,
      onPressed: _isProcessing ? null : () => _handleProceed(context),
    );
  }

  Future<void> _handleProceed(BuildContext context) async {
    if (widget.result.recommendedAction == 'AMBULANCE_DISPATCH') {
      final Uri url = Uri.parse("tel:911");
      if (await canLaunchUrl(url)) await launchUrl(url);
      return;
    }

    if (widget.result.recommendedAction == 'TELEMEDICINE') {
       Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AtamanBaseScreen(initialIndex: 2)),
        (route) => false,
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      Facility? recommendedFacility = await getIt<FacilityRepository>().findRecommendedFacility(widget.result.requiredCapability);
      
      if (!mounted) return;

      if (recommendedFacility != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BookingDetailsScreen(
              facility: recommendedFacility!,
              triageResult: widget.result,
            ),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AtamanBaseScreen(initialIndex: 1, triageResult: widget.result),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _exitTriage(BuildContext context) {
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
