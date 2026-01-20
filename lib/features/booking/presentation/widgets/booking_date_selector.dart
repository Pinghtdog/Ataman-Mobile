import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';

class BookingDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const BookingDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<DateTime> dates = List.generate(3, (i) => DateTime.now().add(Duration(days: i)));
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: dates.map((date) {
        final isSelected = DateFormat('dd').format(selectedDate) == DateFormat('dd').format(date);
        return GestureDetector(
          onTap: () => onDateSelected(date),
          child: Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('MMM').format(date).toUpperCase(), 
                  style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey, fontSize: 12),
                ),
                Text(
                  DateFormat('dd').format(date), 
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary, 
                    fontSize: 24, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
