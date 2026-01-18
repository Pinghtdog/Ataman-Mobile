import 'package:flutter/material.dart';
import '../constants/constants.dart';

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
