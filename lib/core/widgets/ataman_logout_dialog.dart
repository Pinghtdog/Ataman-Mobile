import 'package:flutter/material.dart';
import '../constants/constants.dart';
import 'ataman_button.dart';

class AtamanLogoutDialog extends StatelessWidget {
  final VoidCallback onLogout;

  const AtamanLogoutDialog({
    super.key,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        "Logout",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: const Text(
        "Are you sure you want to log out of your account?",
        style: TextStyle(color: AppColors.textSecondary),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: AtamanButton(
                text: "Cancel",
                isOutlined: true,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AtamanButton(
                text: "Logout",
                color: Colors.red,
                onPressed: () {
                  Navigator.pop(context);
                  onLogout();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
