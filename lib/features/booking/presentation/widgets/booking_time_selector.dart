import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

class BookingTimeSelector extends StatelessWidget {
  final String selectedTime;
  final Function(String) onTimeSelected;
  final List<String> occupiedSlots; // Slots that are already full

  const BookingTimeSelector({
    super.key,
    required this.selectedTime,
    required this.onTimeSelected,
    this.occupiedSlots = const [],
  });

  @override
  Widget build(BuildContext context) {
    // Generate slots from 8:00 AM to 5:00 PM
    final List<String> slots = _generateTimeSlots();

    return Wrap(
      spacing: 10,
      runSpacing: 12,
      children: slots.map((time) {
        final isSelected = selectedTime == time;
        final bool isFull = occupiedSlots.contains(time);

        return GestureDetector(
          onTap: isFull ? null : () => onTimeSelected(time),
          child: Container(
            width: (MediaQuery.of(context).size.width - 68) / 3, // 3 columns
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.primary 
                  : (isFull ? Colors.grey.shade100 : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? AppColors.primary 
                    : (isFull ? Colors.grey.shade200 : Colors.grey.shade200),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isSelected 
                        ? Colors.white 
                        : (isFull ? Colors.grey.shade400 : AppColors.textPrimary),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                if (isFull)
                  const Text(
                    "FULL",
                    style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<String> _generateTimeSlots() {
    List<String> slots = [];
    // 8 AM to 12 PM
    for (int i = 8; i < 12; i++) {
      slots.add("${i.toString().padLeft(2, '0')}:00 AM");
      slots.add("${i.toString().padLeft(2, '0')}:30 AM");
    }
    // 12 PM
    slots.add("12:00 PM");
    slots.add("12:30 PM");
    // 1 PM to 5 PM
    for (int i = 1; i < 5; i++) {
      slots.add("${i.toString().padLeft(2, '0')}:00 PM");
      slots.add("${i.toString().padLeft(2, '0')}:30 PM");
    }
    return slots;
  }
}
