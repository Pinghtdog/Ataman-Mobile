import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injector.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../data/models/referral_model.dart';
import '../../data/repositories/referral_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key});

  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen> {
  late Stream<List<Referral>> _referralStream;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthCubit>().state;
    if (user is Authenticated) {
      _referralStream = getIt<ReferralRepository>().watchMyReferrals(user.user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AtamanHeader(
            isSimple: true,
            height: 120,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    "Hospital Referrals",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Referral>>(
              stream: _referralStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final referrals = snapshot.data ?? [];
                if (referrals.isEmpty) {
                  return const AtamanEmptyState(
                    title: "No Active Referrals",
                    message: "When a doctor refers you to another facility, it will appear here.",
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.p20),
                  itemCount: referrals.length,
                  itemBuilder: (context, index) {
                    return _buildReferralCard(referrals[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCard(Referral referral) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(referral.referenceNumber, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                _buildStatusBadge(referral.status),
              ],
            ),
            const SizedBox(height: 16),
            _buildRouteInfo(referral),
            const Divider(height: 32),
            Text("Chief Complaint", style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Text(referral.chiefComplaint, style: AppTextStyles.bodyMedium),
            if (referral.diagnosisImpression != null) ...[
              const SizedBox(height: 12),
              Text("Initial Impression", style: AppTextStyles.caption),
              const SizedBox(height: 4),
              Text(referral.diagnosisImpression!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfo(Referral referral) {
    return Row(
      children: [
        Column(
          children: [
            const Icon(Icons.radio_button_checked, size: 16, color: Colors.grey),
            Container(width: 2, height: 20, color: Colors.grey.shade200),
            const Icon(Icons.location_on, size: 16, color: AppColors.primary),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(referral.originFacilityName, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 16),
              Text(referral.destinationFacilityName, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(ReferralStatus status) {
    Color color = Colors.orange;
    if (status == ReferralStatus.ACCEPTED) color = Colors.green;
    if (status == ReferralStatus.REJECTED) color = Colors.red;
    
    return AtamanBadge(text: status.name, color: color);
  }
}
