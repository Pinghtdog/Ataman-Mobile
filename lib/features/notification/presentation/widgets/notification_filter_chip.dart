import 'package:flutter/material.dart';

class NotificationFilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool hasDot;
  final VoidCallback onTap;

  const NotificationFilterChip({
    super.key,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.hasDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF333333) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: isActive ? null : Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (hasDot) ...[
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: Color(0xFFD32F2F), shape: BoxShape.circle),
              )
            ]
          ],
        ),
      ),
    );
  }
}
