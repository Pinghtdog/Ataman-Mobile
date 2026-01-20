import 'package:flutter/material.dart';
import '../constants/constants.dart';

class AtamanSimpleHeader extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const AtamanSimpleHeader({
    super.key,
    required this.child,
    this.height = 115,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: padding ?? const EdgeInsets.only(top: 60, left: AppSizes.p24, right: AppSizes.p24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
      ),
      child: child,
    );
  }
}
