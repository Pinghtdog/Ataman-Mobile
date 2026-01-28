import 'package:ataman/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

class ConfidentialAndSafeCard extends StatelessWidget {
  const ConfidentialAndSafeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(AppStrings.confidentialAndSafe, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 4),
                Text(AppStrings.yourRecordsAreEncrypted, style: TextStyle(color: Colors.white70)),
                Text(AppStrings.noJudgmentJustCare, style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
