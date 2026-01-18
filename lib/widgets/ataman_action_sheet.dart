import 'package:flutter/material.dart';
import '../constants/constants.dart';

class AtamanActionOption {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  AtamanActionOption({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });
}

class AtamanActionSheet extends StatelessWidget {
  final String title;
  final List<AtamanActionOption> options;

  const AtamanActionSheet({
    super.key,
    required this.title,
    required this.options,
  });

  static void show(BuildContext context, {
    required String title, 
    required List<AtamanActionOption> options,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AtamanActionSheet(title: title, options: options),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.p24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLarge)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSizes.p12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSizes.p24),
          Text(
            title,
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: AppSizes.p16),
          ...options.map((option) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: option.isDestructive 
                    ? AppColors.danger.withOpacity(0.1) 
                    : AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                option.icon, 
                color: option.isDestructive ? AppColors.danger : AppColors.primary,
                size: 20,
              ),
            ),
            title: Text(
              option.title,
              style: AppTextStyles.bodyLarge.copyWith(
                color: option.isDestructive ? AppColors.danger : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              option.onTap();
            },
          )),
        ],
      ),
    );
  }
}
