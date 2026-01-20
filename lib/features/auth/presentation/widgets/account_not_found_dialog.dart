import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';

class AccountNotFoundDialog extends StatelessWidget {
  final VoidCallback onCreateAccount;
  final VoidCallback onRetry;
  final bool isEmail;

  const AccountNotFoundDialog({
    super.key,
    required this.onCreateAccount,
    required this.onRetry,
    this.isEmail = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.p24),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: Offset(0.0, 10.0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search_rounded,
                color: Colors.orange,
                size: 64,
              ),
            ),
            const SizedBox(height: AppSizes.p24),
            const Text(
              "Account Not Found",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.p16),
            Text(
              isEmail 
                ? "We couldn't find an account matching that email address. Please check your spelling or create a new account."
                : "We couldn't find an account matching that phone number.",
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.p32),
            AtamanButton(
              text: "Create New Account",
              onPressed: () {
                Navigator.of(context).pop();
                onCreateAccount();
              },
            ),
            const SizedBox(height: AppSizes.p8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text("Try Again", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
