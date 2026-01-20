import 'package:flutter/material.dart';
import '../constants/constants.dart';

class UiUtils {
  static void showError(BuildContext context, String message) {
    _showSnackBar(context, message, AppColors.danger, Icons.error_outline_rounded);
  }

  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(context, message, AppColors.success, Icons.check_circle_outline_rounded);
  }

  static void showInfo(BuildContext context, String message) {
    _showSnackBar(context, message, AppColors.info, Icons.info_outline_rounded);
  }

  static void _showSnackBar(BuildContext context, String message, Color bgColor, IconData icon) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: AppSizes.p12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSizes.p16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        elevation: 4,
      ),
    );
  }

  static void hideKeyboard(BuildContext context) {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }
}