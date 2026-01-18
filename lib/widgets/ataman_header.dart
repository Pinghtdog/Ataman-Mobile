import 'package:flutter/material.dart';
import '../constants/constants.dart';

class AtamanHeader extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const AtamanHeader({
    super.key,
    required this.child,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: padding ?? const EdgeInsets.only(
        top: 60, 
        left: AppSizes.p24, 
        right: AppSizes.p24, 
        bottom: 40,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.elliptical(200, 30),
        ),
      ),
      child: child,
    );
  }
}
