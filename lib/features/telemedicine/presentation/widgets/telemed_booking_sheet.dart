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
  String? _selectedSlot;
  List<Map<String, dynamic>> _availability = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

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
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(AppSizes.p24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLarge)),
          ),
          child: ListView(
            controller: scrollController,
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
              const SizedBox(height: AppSizes.p24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_availability.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Text("No available shifts found for this doctor."),
                ))
              else ...[
                const Text("Available Shifts", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSizes.p12),
                Wrap(
                  spacing: AppSizes.p8,
                  runSpacing: AppSizes.p8,
                  children: _availability.map((slot) {
                    final dayName = _getDayName(slot['day_of_week']);
                    final timeRange = "${slot['start_time']} - ${slot['end_time']}";
                    final isSelected = _selectedSlot == "${slot['id']}";

                    return ChoiceChip(
                      label: Text("$dayName ($timeRange)"),
                      selected: isSelected,
                      onSelected: (val) {
                        if (!_isSubmitting) {
                          setState(() => _selectedSlot = val ? "${slot['id']}" : null);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSizes.p32),
                AtamanButton(
                  text: "Confirm Booking",
                  isLoading: _isSubmitting,
                  onPressed: _selectedSlot == null || _isSubmitting ? null : _handleBooking,
                ),
              ],
              const SizedBox(height: AppSizes.p24),
            ],
          ),
        );
      },
    );
  }

  String _getDayName(int day) {
    const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    return days[day];
  }

  Future<void> _handleBooking() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final slot = _availability.firstWhere((s) => "${s['id']}" == _selectedSlot);
    final int targetDay = slot['day_of_week'];
    
    DateTime bookingTime = DateTime.now();
    final int adjustedTargetDay = targetDay == 0 ? 7 : targetDay;
    
    while (bookingTime.weekday != adjustedTargetDay) {
      bookingTime = bookingTime.add(const Duration(days: 1));
    }
    
    final parts = slot['start_time'].split(':');
    bookingTime = DateTime(bookingTime.year, bookingTime.month, bookingTime.day, int.parse(parts[0]), int.parse(parts[1]));

    try {
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
        setState(() => _isSubmitting = false);
        return;
      }

      await context.read<TelemedicineCubit>().initiateCall(
        widget.userId,
        widget.doctor.id,
        scheduledTime: bookingTime,
      );
      
      if (mounted) {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _isSubmitting = false);
      }
    }
  }
}
