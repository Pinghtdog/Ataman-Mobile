import 'package:flutter/material.dart';
import '../constants/constants.dart';

//used on home screen
class AtamanServiceGrid extends StatelessWidget {
  final List<Map<String, dynamic>> services;
  final Function(int) onServiceTap;

  const AtamanServiceGrid({
    super.key,
    required this.services,
    required this.onServiceTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSizes.p20,
        mainAxisSpacing: AppSizes.p20,
        childAspectRatio: 1.3,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return InkWell(
          onTap: () => onServiceTap(index),
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  service['icon'] as IconData,
                  color: service['color'] as Color,
                  size: AppSizes.iconXLarge,
                ),
                const SizedBox(height: AppSizes.p12),
                Text(
                  service['title'] as String,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
