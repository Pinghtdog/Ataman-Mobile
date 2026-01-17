import 'package:flutter/material.dart';
import '../constants/constants.dart';
import 'ataman_button.dart';

class AtamanMaintenance extends StatelessWidget {
  final VoidCallback? onRefresh;

  const AtamanMaintenance({
    super.key,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.construction_rounded,
                  color: Colors.orange.shade700,
                  size: 80,
                ),
              ),
              const SizedBox(height: AppSizes.p32),
              const Text(
                "Maintenance",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.p16),
              const Text(
                "We're currently improving our services. We'll be back online shortly. Thank you for your patience!",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              if (onRefresh != null) ...[
                const SizedBox(height: AppSizes.p48),
                AtamanButton(
                  text: "Check Again",
                  onPressed: onRefresh!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
