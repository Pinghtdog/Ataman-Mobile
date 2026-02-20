import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';

class BookingTimeSelector extends StatelessWidget {
  final String selectedTime;
  final Function(String) onTimeSelected;
  final List<String> occupiedSlots;
  final DateTime selectedDate; // Added to check for past times on current day

  const BookingTimeSelector({
    super.key,
    required this.selectedTime,
    required this.onTimeSelected,
    required this.selectedDate,
    this.occupiedSlots = const [],
  });

  @override
  Widget build(BuildContext context) {
    final List<String> slots = _generateTimeSlots();
    final now = DateTime.now();
    final bool isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    return Wrap(
      spacing: 10,
      runSpacing: 12,
      children: slots.map((time) {
        final isSelected = selectedTime == time;
        final bool isFull = occupiedSlots.contains(time);
        
        // Check if time has passed for today
        bool isPast = false;
        if (isToday) {
          final slotTime = _parseTimeString(time);
          final slotDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            slotTime.hour,
            slotTime.minute,
          );
          // Allow booking for slots at least 30 minutes in the future
          isPast = slotDateTime.isBefore(now.add(const Duration(minutes: 15)));
        }

        final bool isDisabled = isFull || isPast;

        return GestureDetector(
          onTap: isDisabled ? null : () => onTimeSelected(time),
          child: Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
            child: Container(
              width: (MediaQuery.of(context).size.width - 68) / 3,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primary 
                    : (isDisabled ? Colors.grey.shade100 : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? AppColors.primary 
                      : Colors.grey.shade200,
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
                          : (isDisabled ? Colors.grey.shade400 : AppColors.textPrimary),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  if (isFull)
                    const Text(
                      "FULL",
                      style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold),
                    )
                  else if (isPast && isToday)
                    const Text(
                      "PASSED",
                      style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  TimeOfDay _parseTimeString(String time) {
    // Expected format: "09:00 AM"
    final format = DateFormat.jm(); // Uses intl to parse AM/PM
    final dateTime = format.parse(time);
    return TimeOfDay.fromDateTime(dateTime);
  }

  List<String> _generateTimeSlots() {
    List<String> slots = [];
    // 8 AM to 11:30 AM
    for (int i = 8; i < 12; i++) {
      slots.add("${i.toString().padLeft(2, '0')}:00 AM");
      slots.add("${i.toString().padLeft(2, '0')}:30 AM");
    }
    // 12 PM
    slots.add("12:00 PM");
    slots.add("12:30 PM");
    // 1 PM to 4:30 PM
    for (int i = 1; i < 5; i++) {
      slots.add("${i.toString().padLeft(2, '0')}:00 PM");
      slots.add("${i.toString().padLeft(2, '0')}:30 PM");
    }
    return slots;
  }
}
