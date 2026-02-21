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

/// [MyAppointmentsScreen] displays a categorized view of the user's medical appointments.
///
/// It handles two main types of appointments:
/// 1. **Physical Facility Visits**: Managed via [BookingCubit].
/// 2. **Tele-Consultations**: Managed via [TelemedicineCubit].
///
/// The screen uses a [TabController] to toggle between:
/// - **Active**: Shows upcoming physical visits and ongoing/scheduled virtual sessions.
/// - **History**: Shows past, completed, cancelled, or missed appointments.
///
/// **Instant Fix Logic**:
/// To improve UX, this screen locally filters "pending" physical appointments into
/// the "History" tab if their scheduled time has already passed, providing immediate
/// feedback even before the backend cron job updates the status to 'missed'.
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

  /// Initializes data fetching for both physical and telemedicine bookings.
  /// Listens to the [AuthCubit] to ensure the user is authenticated.
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

                    final now = DateTime.now();

                    // 1. Process Physical Bookings with Instant Fix Logic
                    List<Booking> activePhysical = [];
                    List<Booking> historyPhysical = [];
                    if (bookingState is BookingLoaded) {
                      activePhysical = bookingState.bookings.where((b) {
                        final isPending = b.status == BookingStatus.pending || b.status == BookingStatus.confirmed;
                        // ONLY show as active if it's pending AND the time hasn't passed yet
                        return isPending && b.appointmentTime.isAfter(now);
                      }).toList();

                      historyPhysical = bookingState.bookings.where((b) {
                        final isNotPending = b.status != BookingStatus.pending && b.status != BookingStatus.confirmed;
                        // Show in history if status is finished OR if the time has already passed
                        return isNotPending || b.appointmentTime.isBefore(now);
                      }).toList();
                    }

                    // 2. Process Telemed Sessions
                    List<Map<String, dynamic>> activeTelemed = [];
                    List<Map<String, dynamic>> historyTelemed = [];
                    if (telemedState is TelemedicineLoaded) {
                      activeTelemed = telemedState.activeSessions
                          .where((s) => s['status'] == 'scheduled' || s['status'] == 'active')
                          .toList();
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

  /// Builds a scrollable list combining both Telemedicine and Physical bookings.
  /// Displays an empty state message if no appointments are found for the current tab.
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

  /// Builds a small uppercase header for different appointment categories.
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

  /// Renders a specialized card for Telemedicine sessions.
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
                Navigator.pushNamed(context, AppRoutes.telemedicine);
              },
            ),
        ],
      ),
    );
  }

  /// Shows a confirmation dialog before cancelling a physical booking.
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
