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
      runSpacing: 12,
      children: services.map((service) {
        final isSelected = selectedService?.id == service.id;
        final bool isAvailable = service.isAvailable;

        return Opacity(
          opacity: isAvailable ? 1.0 : 0.5,
          child: RawChip(
            isEnabled: isAvailable,
            showCheckmark: false,
            selected: isSelected,
            onSelected: (selected) {
              if (selected && isAvailable) onServiceSelected(service);
            },
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
              ),
            ),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  service.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (!isAvailable) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.power_off, color: AppColors.danger, size: 14),
                ]
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
