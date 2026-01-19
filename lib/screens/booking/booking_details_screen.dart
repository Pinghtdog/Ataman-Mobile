import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../constants/constants.dart';
import '../../data/models/facility_model.dart';
import '../../data/models/booking_model.dart';
import '../../logic/booking/booking_cubit.dart';
import '../../logic/booking/booking_state.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../widgets/ataman_header.dart';

class BookingDetailsScreen extends StatefulWidget {
  final Facility facility;

  const BookingDetailsScreen({super.key, required this.facility});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _confirmBooking() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    final appointmentTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final booking = Booking(
      id: '',
      userId: authState.user!.id,
      facilityId: widget.facility.id,
      facilityName: widget.facility.name,
      appointmentTime: appointmentTime,
      status: BookingStatus.pending,
      createdAt: DateTime.now(),
    );

    context.read<BookingCubit>().createBooking(booking);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<BookingCubit, BookingState>(
        listener: (context, state) {
          if (state is BookingLoaded) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Booking Successful!")),
            );
            Navigator.pop(context);
          } else if (state is BookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              AtamanHeader(
                height: 150,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.facility.name,
                      style: AppTextStyles.h2.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      widget.facility.address,
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.p24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Select Appointment Date & Time", style: AppTextStyles.h3),
                      const SizedBox(height: 24),
                      ListTile(
                        title: const Text("Date"),
                        subtitle: Text(DateFormat('MMMM dd, yyyy').format(_selectedDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _selectDate(context),
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text("Time"),
                        subtitle: Text(_selectedTime.format(context)),
                        trailing: const Icon(Icons.access_time),
                        onTap: () => _selectTime(context),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: state is BookingLoading ? null : _confirmBooking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: state is BookingLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Confirm Booking", style: TextStyle(color: Colors.white, fontSize: 18)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
