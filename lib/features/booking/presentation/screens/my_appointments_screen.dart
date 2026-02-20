import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../../telemedicine/logic/telemedicine_cubit.dart';
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
      final userId = authState.user.id;
      context.read<BookingCubit>().startWatchingBookings(userId);
      context.read<TelemedicineCubit>().startWatchingSessions(userId);
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
            isSimple: true,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + AppSizes.p16,
              left: AppSizes.p24,
              right: AppSizes.p24,
              bottom: AppSizes.p16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 20),
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  unselectedLabelStyle: AppTextStyles.bodyMedium,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
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
              builder: (context, bookingState) {
                return BlocBuilder<TelemedicineCubit, TelemedicineState>(
                  builder: (context, telemedState) {
                    if (bookingState is BookingLoading && telemedState is TelemedicineLoading) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }

                    // 1. Process Physical Bookings
                    List<Booking> activePhysical = [];
                    List<Booking> historyPhysical = [];
                    if (bookingState is BookingLoaded) {
                      activePhysical = bookingState.bookings
                          .where((b) => b.status == BookingStatus.pending || b.status == BookingStatus.confirmed)
                          .toList();
                      historyPhysical = bookingState.bookings
                          .where((b) => b.status != BookingStatus.pending && b.status != BookingStatus.confirmed)
                          .toList();
                    }

                    // 2. Process Telemed Sessions
                    List<Map<String, dynamic>> activeTelemed = [];
                    List<Map<String, dynamic>> historyTelemed = [];
                    if (telemedState is TelemedicineLoaded) {
                      activeTelemed = telemedState.activeSessions
                          .where((s) => s['status'] == 'scheduled' || s['status'] == 'active')
                          .toList();
                      // (Assuming past sessions are not in the 'activeSessions' list based on the Cubit logic)
                    }

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCombinedList(
                          physical: activePhysical, 
                          telemed: activeTelemed, 
                          isActive: true
                        ),
                        _buildCombinedList(
                          physical: historyPhysical, 
                          telemed: historyTelemed, 
                          isActive: false
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedList({
    required List<Booking> physical,
    required List<Map<String, dynamic>> telemed,
    required bool isActive,
  }) {
    if (physical.isEmpty && telemed.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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

    return ListView(
      padding: const EdgeInsets.all(AppSizes.p20),
      children: [
        if (telemed.isNotEmpty) ...[
          _buildSectionHeader("Tele-Consultations"),
          ...telemed.map((session) => _buildTelemedCard(session, isActive)),
          const SizedBox(height: 24),
        ],
        if (physical.isNotEmpty) ...[
          _buildSectionHeader("Facility Visits"),
          ...physical.map((booking) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AtamanBookingTicket(
              booking: booking,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => BookingQrDialog(booking: booking),
                );
              },
              onCancel: isActive ? () => _confirmCancel(booking) : null,
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTelemedCard(Map<String, dynamic> session, bool isActive) {
    final scheduledTimeStr = session['scheduled_time'];
    final scheduledTime = scheduledTimeStr != null ? DateTime.parse(scheduledTimeStr) : null;
    final doctorName = session['telemed_doctors']?['full_name'] ?? "Specialist";
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.video_camera_front_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctorName,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  scheduledTime != null 
                    ? DateFormat('MMM dd, yyyy • hh:mm a').format(scheduledTime)
                    : "Immediate Consultation",
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "VIRTUAL SESSION",
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onPressed: () {
                // Navigate to telemed detail or call screen
                Navigator.pushNamed(context, AppRoutes.telemedicine);
              },
            ),
        ],
      ),
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
