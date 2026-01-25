import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../data/models/booking_model.dart';
import '../../logic/booking_cubit.dart';
import '../../logic/booking_state.dart';
import '../widgets/ataman_booking_ticket.dart';
import '../widgets/booking_qr_dialog.dart';

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
      context.read<BookingCubit>().startWatchingBookings(authState.user.id);
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
          AtamanSimpleHeader(
            height: 160,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "My Appointments",
                      style: AppTextStyles.h2.copyWith(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
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
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<BookingCubit, BookingState>(
              builder: (context, state) {
                if (state is BookingLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                } else if (state is BookingLoaded) {
                  // Dynamic Filtering based on SQL status
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
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(state.message, textAlign: TextAlign.center),
                    ),
                  );
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
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height - 250,
          alignment: Alignment.center,
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
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.p20),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        // UI Feedback: Using AtamanBookingTicket which handles dynamic display
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
          // Action Integration: Cancel functionality
          onCancel: isActive ? () => _confirmCancel(booking) : null,
        );
      },
    );
  }

  void _confirmCancel(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Cancel Appointment"),
        content: const Text("Are you sure you want to cancel this appointment?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final authState = context.read<AuthCubit>().state;
              if (authState is Authenticated) {
                // Action Integration: Calling repository via Cubit
                context.read<BookingCubit>().cancelBooking(booking.id, authState.user.id);
              }
              Navigator.pop(context);
            },
            child: const Text("Yes, Cancel", style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
