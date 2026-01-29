import 'package:flutter/material.dart';
import '../constants/constants.dart';

/// A standard label for form fields or sections.
class AtamanLabel extends StatelessWidget {
  final String text;
  const AtamanLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p8, left: AppSizes.p4),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// A versatile badge for showing status (success, warning, danger, info).
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
    return AtamanBadge(text: text, color: AppColors.success, icon: icon);
  }

  factory AtamanBadge.warning({required String text, IconData? icon}) {
    return AtamanBadge(text: text, color: AppColors.warning, icon: icon);
  }

  factory AtamanBadge.danger({required String text, IconData? icon}) {
    return AtamanBadge(text: text, color: AppColors.danger, icon: icon);
  }

  factory AtamanBadge.info({required String text, IconData? icon}) {
    return AtamanBadge(text: text, color: AppColors.info, icon: icon);
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

/// Flexible App Header that supports both simple (rectangular) and custom (elliptical) designs.
class AtamanHeader extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool isSimple; // If true, removes the elliptical bottom curve

  const AtamanHeader({
    super.key,
    required this.child,
    this.height,
    this.padding,
    this.isSimple = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: padding ?? const EdgeInsets.fromLTRB(AppSizes.p24, 60, AppSizes.p24, 40),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: isSimple 
            ? null 
            : const BorderRadius.vertical(bottom: Radius.elliptical(200, 30)),
      ),
      child: child,
    );
  }
}
