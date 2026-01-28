import 'package:ataman/core/constants/app_strings.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class NextAvailableGPCard extends StatelessWidget {
  const NextAvailableGPCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DottedBorder(
      borderType: BorderType.RRect,
      radius: const Radius.circular(16),
      color: theme.primaryColor,
      strokeWidth: 1,
      dashPattern: const [4, 4],
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.primaryColor.withAlpha(26),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.person_pin, color: theme.primaryColor, size: 40),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.nextAvailableGP, style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(AppStrings.estWaitTime, style: TextStyle(color: theme.primaryColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
