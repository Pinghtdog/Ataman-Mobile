import 'package:flutter/material.dart';
import '../constants/constants.dart';

class AtamanBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const AtamanBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  factory AtamanBadge.success({required String text, IconData? icon}) {
    return AtamanBadge(
      text: text,
      color: AppColors.success,
      icon: icon,
    );
  }

  factory AtamanBadge.warning({required String text, IconData? icon}) {
    return AtamanBadge(
      text: text,
      color: AppColors.warning,
      icon: icon,
    );
  }

  factory AtamanBadge.danger({required String text, IconData? icon}) {
    return AtamanBadge(
      text: text,
      color: AppColors.danger,
      icon: icon,
    );
  }

  factory AtamanBadge.info({required String text, IconData? icon}) {
    return AtamanBadge(
      text: text,
      color: AppColors.info,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: AppSizes.p4),
          ],
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
