import 'package:ataman/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

class ScheduleSelector extends StatelessWidget {
  const ScheduleSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Expanded(
            child: _buildScheduleDetail(AppStrings.date, "Tomorrow, Oct 25"),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildScheduleDetail(AppStrings.time, "8:00 AM"),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleDetail(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
