import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

class HospitalAvailabilityHeader extends StatelessWidget {
  final String medicineName;

  const HospitalAvailabilityHeader({
    super.key,
    required this.medicineName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSizes.p16,
        bottom: AppSizes.p24,
        left: AppSizes.p16,
        right: AppSizes.p16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppSizes.p24),
          bottomRight: Radius.circular(AppSizes.p24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Hospital Availability',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: AppSizes.p16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: AppSizes.p12,
              horizontal: AppSizes.p16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.p12),
            ),
            child: Text(
              'Selected Medicine: $medicineName',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
