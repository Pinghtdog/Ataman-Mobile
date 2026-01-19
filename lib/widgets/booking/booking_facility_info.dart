import 'package:flutter/material.dart';
import '../../constants/constants.dart';
import '../../data/models/facility_model.dart';

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
              _buildStatusChip(facility.hasDoctor ? "Dr. On-Site" : "Midwife Only", Colors.teal),
            ],
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
