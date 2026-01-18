import 'package:flutter/material.dart';
import '../../constants/constants.dart';
import '../../data/models/facility_model.dart';
import 'facility_card.dart';

class FacilityListView extends StatelessWidget {
  final List<Facility> facilities;
  final Function(Facility) onFacilityTap;

  const FacilityListView({
    super.key,
    required this.facilities,
    required this.onFacilityTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p20, 
        vertical: AppSizes.p12,
      ),
      itemCount: facilities.length + 1,
      itemBuilder: (context, index) {
        if (index == facilities.length) {
          return const SizedBox(height: AppSizes.p48 * 2);
        }
        final facility = facilities[index];
        return FacilityCard(
          facility: facility,
          onTap: () => onFacilityTap(facility),
        );
      },
    );
  }
}
