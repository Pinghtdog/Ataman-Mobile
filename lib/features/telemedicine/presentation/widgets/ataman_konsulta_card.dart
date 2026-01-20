import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

class AtamanKonsultaCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String nextAvailable;
  final VoidCallback onJoinTap;

  const AtamanKonsultaCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.nextAvailable,
    required this.onJoinTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.h3.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppSizes.p4),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.video_camera_front_rounded, color: Colors.white, size: AppSizes.iconXLarge),
            ],
          ),
          const SizedBox(height: AppSizes.p24),
          Container(
            padding: const EdgeInsets.all(AppSizes.p12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_filled_rounded, color: Colors.white, size: AppSizes.iconSmall),
                const SizedBox(width: AppSizes.p8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
                      children: [
                        const TextSpan(text: "Next Available: "),
                        TextSpan(
                          text: nextAvailable,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onJoinTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
                    elevation: 0,
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLarge)),
                  ),
                  child: const Text("JOIN", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
