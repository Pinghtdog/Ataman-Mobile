import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/constants.dart';
import '../ataman_button.dart';

class CheckEmailDialog extends StatelessWidget {
  final String email;
  final VoidCallback onContinue;

  const CheckEmailDialog({
    super.key,
    required this.email,
    required this.onContinue,
  });

  Future<void> _openGmail() async {
    Uri? url;
    if (Platform.isAndroid) {
      url = Uri.parse("googlegmail:///");
    } else if (Platform.isIOS) {
      url = Uri.parse("googlegmail:///");
    }

    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      final Uri emailUri = Uri(
        scheme: 'mailto',
      );
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
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
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_unread_rounded,
              color: AppColors.primary,
              size: 64,
            ),
          ),
          const SizedBox(height: AppSizes.p24),
          const Text(
            "Check Your Email",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.p16),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              children: [
                const TextSpan(text: "We've sent a confirmation link to\n"),
                TextSpan(
                  text: email,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const TextSpan(text: ".\n\nPlease check your inbox and click the link to activate your account."),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.p32),
          AtamanButton(
            text: "Open Gmail",
            onPressed: () async {
              await _openGmail();
              if (context.mounted) {
                Navigator.of(context).pop();
                onContinue();
              }
            },
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onContinue();
            },
            child: const Text("I'll do it later", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
