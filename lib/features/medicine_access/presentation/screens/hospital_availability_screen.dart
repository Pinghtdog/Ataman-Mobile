import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../widgets/hospital_availability_card.dart';
import '../widgets/hospital_availability_header.dart';

class HospitalAvailabilityScreen extends StatelessWidget {
  final String medicineName;

  const HospitalAvailabilityScreen({
    super.key,
    required this.medicineName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          HospitalAvailabilityHeader(medicineName: medicineName),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.p16),
              children: const [
                HospitalAvailabilityCard(
                  hospitalName: 'Chong Hua Hospital',
                  distance: '1.2 km away',
                  inStock: true,
                  price: 5.00,
                ),
                HospitalAvailabilityCard(
                  hospitalName: 'Vicente Sotto Memorial Medical Center',
                  distance: '3.0 km away',
                  inStock: true,
                  price: 4.75,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
