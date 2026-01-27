import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

class FamilyMemberCard extends StatelessWidget {
  final String name;
  final String relationship;
  final int age;
  final Color avatarColor;
  final Color iconColor;
  final VoidCallback onViewId;

  const FamilyMemberCard({
    super.key,
    required this.name,
    required this.relationship,
    required this.age,
    required this.avatarColor,
    required this.iconColor,
    required this.onViewId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: avatarColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_rounded, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  "$relationship • $age yrs",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onViewId,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.08),
              foregroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("View ID", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
