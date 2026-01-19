import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../constants/constants.dart';
import '../../logic/booking/booking_cubit.dart';
import '../../logic/booking/booking_state.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../widgets/ataman_header.dart';
import '../../widgets/booking/ataman_booking_ticket.dart';
import '../../widgets/booking/booking_qr_dialog.dart';
import '../../data/models/booking_model.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  void _loadBookings() {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<BookingCubit>().startWatchingBookings(authState.user!.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AtamanHeader(
            height: 140,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "My Appointments",
                  style: AppTextStyles.h2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  unselectedLabelStyle: AppTextStyles.bodyMedium,
                  tabs: const [
                    Tab(text: "Active"),
                    Tab(text: "History"),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<BookingCubit, BookingState>(
              builder: (context, state) {
                if (state is BookingLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is BookingLoaded) {
                  final activeBookings = state.bookings
                      .where((b) => b.status == BookingStatus.pending || b.status == BookingStatus.confirmed)
                      .toList();
                  final historyBookings = state.bookings
                      .where((b) => b.status != BookingStatus.pending && b.status != BookingStatus.confirmed)
                      .toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBookingList(activeBookings, isActive: true),
                      _buildBookingList(historyBookings, isActive: false),
                    ],
                  );
                } else if (state is BookingError) {
                  return Center(child: Text(state.message));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingList(List<Booking> bookings, {required bool isActive}) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              isActive ? "No active appointments" : "No appointment history",
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.p20),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return AtamanBookingTicket(
          booking: booking,
          onTap: () {
            if (isActive) {
              showDialog(
                context: context,
                builder: (context) => BookingQrDialog(booking: booking),
              );
            }
          },
          onCancel: isActive ? () => _confirmCancel(booking) : null,
        );
      },
    );
  }

  void _confirmCancel(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Appointment"),
        content: const Text("Are you sure you want to cancel this appointment?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () {
              context.read<BookingCubit>().cancelBooking(booking.id);
              Navigator.pop(context);
            },
            child: const Text("Yes, Cancel", style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
