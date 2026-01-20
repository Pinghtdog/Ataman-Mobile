import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../widgets/ataman_button.dart';

class AtamanErrorState extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final String? buttonText;
  final VoidCallback? onAction;

  const AtamanErrorState({
    super.key,
    this.title = "Something went wrong",
    this.message = "We encountered an unexpected error. Please try again.",
    this.icon,
    this.buttonText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline_rounded,
              color: Colors.grey.shade400,
              size: 80,
            ),
            const SizedBox(height: AppSizes.p24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.p12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (buttonText != null && onAction != null) ...[
              const SizedBox(height: AppSizes.p32),
              AtamanButton(
                text: buttonText!,
                onPressed: onAction!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
