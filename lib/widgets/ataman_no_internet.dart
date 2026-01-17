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
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                color: Colors.blue.shade700,
                size: 80,
              ),
            ),
            const SizedBox(height: AppSizes.p32),
            const Text(
              "No Connection",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.p16),
            const Text(
              "It looks like you're offline. Please check your internet connection and try again.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
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
