import 'package:flutter/material.dart';
import '../../constants/constants.dart';

class EmergencyHelpCard extends StatelessWidget {
  final VoidCallback onTap;

  const EmergencyHelpCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.p20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF5350), Color(0xFFD32F2F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD32F2F).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.p12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emergency_rounded, color: Colors.white, size: AppSizes.iconLarge),
            ),
            const SizedBox(width: AppSizes.p16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Emergency Help?",
                    style: AppTextStyles.h3.copyWith(color: Colors.white),
                  ),
                  Text(
                    "Get immediate assistance",
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: AppSizes.iconSmall, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
