import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../facility/data/models/facility_service_model.dart';

class BookingServiceSelector extends StatelessWidget {
  final List<FacilityService> services;
  final FacilityService? selectedService;
  final Function(FacilityService) onServiceSelected;

  const BookingServiceSelector({
    super.key,
    required this.services,
    required this.selectedService,
    required this.onServiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: services.map((service) {
        final isSelected = selectedService?.id == service.id;
        return ChoiceChip(
          label: Text(service.name),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) onServiceSelected(service);
          },
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppColors.primary : Colors.grey.shade200,
            ),
          ),
        );
      }).toList(),
    );
  }
}
