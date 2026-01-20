import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

class BookingTimeSelector extends StatelessWidget {
  final String selectedTime;
  final Function(String) onTimeSelected;

  const BookingTimeSelector({
    super.key,
    required this.selectedTime,
    required this.onTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> times = ["09:00 AM", "09:30 AM", "10:00 AM"];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: times.map((time) {
        final isSelected = selectedTime == time;
        return GestureDetector(
          onTap: () => onTimeSelected(time),
          child: Container(
            width: 100,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200, width: 2),
            ),
            child: Center(
              child: Text(
                time, 
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
