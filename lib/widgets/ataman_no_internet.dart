import 'package:flutter/material.dart';
import '../constants/constants.dart';
import 'ataman_button.dart';

class AtamanNoInternet extends StatelessWidget {
  final VoidCallback onRetry;

  const AtamanNoInternet({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.primary,
                size: 80,
              ),
            ),
            const SizedBox(height: AppSizes.p32),
            Text(
              "No Connection",
              style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSizes.p16),
            const Text(
              "It looks like you're offline. Please check your internet connection and try again.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSizes.p48),
            AtamanButton(
              text: "Retry Connection",
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
