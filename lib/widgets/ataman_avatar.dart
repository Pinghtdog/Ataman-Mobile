import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class AtamanAvatar extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double radius;
  final bool isActive;

  const AtamanAvatar({
    super.key,
    this.imageUrl,
    this.initials = "A",
    this.radius = 24.0,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primaryLight,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null
              ? Text(
            initials,
            style: AppTextStyles.h3.copyWith(color: AppColors.primary),
          )
              : null,
        ),
        if (isActive)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              height: radius * 0.6,
              width: radius * 0.6,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}