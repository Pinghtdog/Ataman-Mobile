import 'package:flutter/material.dart';
import '../constants/constants.dart';

class AtamanHeader extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool isSimple;

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
      padding: padding ?? const EdgeInsets.fromLTRB(
        AppSizes.p24,
        20,
        AppSizes.p24,
        40,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: isSimple 
          ? null 
          : const BorderRadius.vertical(
              bottom: Radius.elliptical(200, 30),
            ),
      ),
      child: child,
    );
  }
}
