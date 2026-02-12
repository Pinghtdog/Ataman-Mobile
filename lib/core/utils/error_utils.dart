import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

//not yet utilized
class ErrorUtils {
  /// Maps raw technical errors to user-friendly messages for Naga residents
  static String mapError(dynamic error) {
    final String e = error.toString().toLowerCase();

    if (e.contains('socketexception') || e.contains('failed host lookup') || e.contains('network')) {
      return "Unable to connect to Ataman servers. Please check your internet connection.";
    }
    if (e.contains('invalid login credentials')) {
      return "Incorrect email or password. Please try again.";
    }
    if (e.contains('user already exists') || e.contains('already registered')) {
      return "This email is already registered. Try logging in instead.";
    }
    if (e.contains('weak password')) {
      return "Password is too weak. Please use a stronger password.";
    }
    if (e.contains('jwt expired') || e.contains('session expired')) {
      return "Your session has expired. Please log in again.";
    }
    if (e.contains('philhealth') && e.contains('verification')) {
      return "We couldn't verify your PhilHealth ID. Please double-check the 12-digit PIN.";
    }

    return "Something went wrong. Our team is looking into it.";
  }

  /// Shows a professional error snackbar
  static void showAtamanError(BuildContext context, dynamic error) {
    final message = mapError(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
