import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

class VaccinationTimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? date;
  final String? location;
  final bool isCompleted;
  final bool isDue;

  const VaccinationTimelineItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.date,
    this.location,
    this.isCompleted = false,
    this.isDue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimelineIndicator(),
          const SizedBox(width: 16),
          Expanded(child: _buildContent(context)),
        ],
      ),
    );
  }

  Widget _buildTimelineIndicator() {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isDue ? Colors.white : (isCompleted ? AppColors.success : Colors.purple),
            shape: BoxShape.circle,
            border: isDue ? Border.all(color: Colors.grey.shade400, width: 2) : null,
          ),
          child: isDue 
            ? const Center(child: Icon(Icons.circle, size: 8, color: Colors.grey))
            : null,
        ),
        Container(
          width: 2,
          height: 80,
          color: Colors.grey.shade200,
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: isDue ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.p16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.p16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                '$date • $location',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary.withOpacity(0.7)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
