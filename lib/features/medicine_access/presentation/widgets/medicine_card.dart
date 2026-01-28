import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

class MedicineCard extends StatelessWidget {
  final String name;
  final String description;
  final bool inStock;
  final IconData icon;
  final VoidCallback? onTap;

  const MedicineCard({
    super.key,
    required this.name,
    required this.description,
    required this.inStock,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.p16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.p12),
              decoration: BoxDecoration(
                color: const Color(0xFF6A1B9A).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFF6A1B9A),
                size: 32,
              ),
            ),
            const SizedBox(height: AppSizes.p12),
            Text(
              name,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.p12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p8,
                vertical: AppSizes.p4,
              ),
              decoration: BoxDecoration(
                color: inStock
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.p12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    inStock ? Icons.check_circle : Icons.cancel,
                    size: 14,
                    color: inStock ? AppColors.success : AppColors.danger,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    inStock ? 'In Stock' : 'Out of Stock',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: inStock ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
