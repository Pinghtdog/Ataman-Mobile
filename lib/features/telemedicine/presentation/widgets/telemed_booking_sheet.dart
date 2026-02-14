import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../logic/telemedicine_cubit.dart';
import '../../data/models/doctor_model.dart';
import '../../../notification/logic/notification_cubit.dart';

class TelemedBookingSheet extends StatefulWidget {
  final DoctorModel doctor;
  final String userId;

  const TelemedBookingSheet({
    super.key,
    required this.doctor,
    required this.userId,
  });

  @override
  State<TelemedBookingSheet> createState() => _TelemedBookingSheetState();
}

class _TelemedBookingSheetState extends State<TelemedBookingSheet> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  List<Map<String, dynamic>> _availability = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final slots = await context.read<TelemedicineCubit>().getDoctorAvailability(widget.doctor.id);
    if (mounted) {
      setState(() {
        _availability = slots;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Schedule with ${widget.doctor.fullName}", 
                  style: AppTextStyles.h3,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 24),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_availability.isEmpty)
            const Center(child: Text("No available shifts found for this doctor."))
          else ...[
            const Text("Available Shifts", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availability.map((slot) {
                final dayName = _getDayName(slot['day_of_week']);
                final timeRange = "${slot['start_time']} - ${slot['end_time']}";
                final isSelected = _selectedSlot == "${slot['id']}";

                return ChoiceChip(
                  label: Text("$dayName ($timeRange)"),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() => _selectedSlot = val ? "${slot['id']}" : null);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            AtamanButton(
              text: "Confirm Booking",
              onPressed: _selectedSlot == null ? null : _handleBooking,
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _getDayName(int day) {
    const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    return days[day];
  }

  Future<void> _handleBooking() async {
    final slot = _availability.firstWhere((s) => "${s['id']}" == _selectedSlot);
    final int targetDay = slot['day_of_week'];
    
    DateTime bookingTime = DateTime.now();
    while (bookingTime.weekday % 7 != targetDay) {
      bookingTime = bookingTime.add(const Duration(days: 1));
    }
    
    final parts = slot['start_time'].split(':');
    bookingTime = DateTime(bookingTime.year, bookingTime.month, bookingTime.day, int.parse(parts[0]), int.parse(parts[1]));

    try {
      // Prevent double booking on the same day for the same doctor
      final canBook = await context.read<TelemedicineCubit>().checkBookingConflict(
        widget.userId,
        widget.doctor.id,
        bookingTime,
      );

      if (!canBook) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You already have an appointment with this doctor on this day."),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      await context.read<TelemedicineCubit>().initiateCall(
        widget.userId,
        widget.doctor.id,
        scheduledTime: bookingTime,
      );
      
      if (mounted) {
        // Trigger local notification via NotificationCubit
        context.read<NotificationCubit>().addNotification(
          title: "Consultation Confirmed",
          body: "Your session with ${widget.doctor.fullName} is scheduled for ${DateFormat('MMM dd, h:mm a').format(bookingTime)}",
          type: "telemedicine",
        );

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Consultation scheduled for ${DateFormat('MMM dd, h:mm a').format(bookingTime)}"),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
