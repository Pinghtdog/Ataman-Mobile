import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../facility/data/models/facility_model.dart';

class BookingFacilityInfo extends StatelessWidget {
  final Facility facility;

  const BookingFacilityInfo({super.key, required this.facility});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(facility.name, style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text("${facility.distance} • ${facility.address}", style: AppTextStyles.bodySmall),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusChip("Queue: ${facility.queueCount}", Colors.green),
              const SizedBox(width: 8),
              _buildStatusChip(facility.hasDoctor ? "Dr. On-Site" : "Staff Only", Colors.teal),
            ],
          ),
          if (facility.services.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            const Text("Specialized Services Status",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: facility.services.map((service) =>
                _buildServiceStatus(service.name, service.isAvailable)
              ).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceStatus(String name, bool isAvailable) {
    final color = isAvailable ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check_circle_rounded : Icons.pause_circle_filled_rounded,
            size: 14,
            color: color
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              color: isAvailable ? AppColors.textPrimary : Colors.grey.shade600,
              fontSize: 12,
              fontWeight: isAvailable ? FontWeight.w600 : FontWeight.normal
            )
          ),
          const SizedBox(width: 4),
          Text(
            isAvailable ? "Online" : "Offline",
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold
            )
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
