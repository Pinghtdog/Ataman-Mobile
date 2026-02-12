import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/services/philhealth_service.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injector.dart';
import '../../../auth/data/models/user_model.dart';

class PhilHealthStatusModal extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onUpdatePressed;

  const PhilHealthStatusModal({
    super.key,
    required this.user,
    this.onUpdatePressed,
  });

  @override
  Widget build(BuildContext context) {
    final philHealthService = getIt<PhilHealthService>();
    final isVerified = user.philhealthId != null && philHealthService.validatePIN(user.philhealthId!);
    final status = philHealthService.checkEligibilityStatus(user);

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
              Text("PhilHealth Status", style: AppTextStyles.h2),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isVerified ? Colors.blue.withOpacity(0.05) : Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isVerified ? Colors.blue.withOpacity(0.2) : Colors.orange.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  isVerified ? Icons.verified_user_rounded : Icons.gpp_maybe_rounded,
                  color: isVerified ? Colors.blue : Colors.orange,
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isVerified ? Colors.blue[800] : Colors.orange[800],
                        ),
                      ),
                      Text(
                        isVerified 
                          ? "Your identity is linked to PhilHealth ID: ${user.philhealthId}"
                          : "Please update your PhilHealth ID in 'Edit Profile' to unlock full benefits.",
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          Text("Naga City Benefits Included:", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          _buildBenefitItem(Icons.local_hospital_rounded, "PhilHealth Konsulta (Yakap)", "Free checkups and labs at Naga CHOs."),
          _buildBenefitItem(Icons.medication_rounded, "Free Medicines", "Claim prescribed maintenance meds at accredited pharmacies."),
          _buildBenefitItem(Icons.emergency_rounded, "Inpatient Coverage", "Up to ₱30,000 coverage at BMC and Naga General Hospital."),
          
          const SizedBox(height: 32),
          if (!isVerified)
            AtamanButton(
              text: "Update PhilHealth ID",
              onPressed: () {
                Navigator.pop(context);
                if (onUpdatePressed != null) onUpdatePressed!();
              },
            )
          else
            AtamanButton(
              text: "Done",
              color: Colors.grey[200],
              textColor: Colors.black,
              onPressed: () => Navigator.pop(context),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
