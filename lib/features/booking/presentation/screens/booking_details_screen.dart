import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injector.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../../facility/data/models/facility_model.dart';
import '../../../facility/data/models/facility_service_model.dart';
import '../../../facility/data/repositories/facility_repository.dart';
import '../../../profile/data/model/family_member_model.dart';
import '../../../profile/data/repositories/family_repository.dart';
import '../../../triage/data/models/triage_model.dart';
import '../../data/models/booking_model.dart';
import '../../logic/booking_cubit.dart';
import '../../logic/booking_state.dart';
import '../../data/repositories/booking_repository.dart';
import '../widgets/booking_date_selector.dart';
import '../widgets/booking_facility_info.dart';
import '../widgets/booking_member_selector.dart';
import '../widgets/booking_service_selector.dart';
import '../widgets/booking_time_selector.dart';
import '../widgets/booking_success_dialog.dart';

class BookingDetailsScreen extends StatefulWidget {
  final Facility facility;
  final TriageResult? triageResult;

  const BookingDetailsScreen({
    super.key, 
    required this.facility,
    this.triageResult,
  });

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedTime = "09:00 AM";
  FacilityService? _selectedService;
  dynamic _bookingFor = "Self";
  
  // DOH FORM 2 Fields
  String _natureOfVisit = "New Consultation/Case";
  final _complaintController = TextEditingController();

  List<FamilyMember> _familyMembers = [];
  List<FacilityService> _services = [];
  List<String> _occupiedSlots = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    if (widget.triageResult != null) {
      _complaintController.text = widget.triageResult!.rawSymptoms;
    }
  }

  Future<void> _loadInitialData() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      try {
        final family = await getIt<FamilyRepository>().getFamilyMembers(authState.user.id);
        final facilityServices = await getIt<FacilityRepository>().getFacilityServices(widget.facility.id);
        final occupied = await getIt<BookingRepository>().getOccupiedSlots(widget.facility.id, _selectedDate);

        if (mounted) {
          setState(() {
            _familyMembers = family;
            _services = facilityServices;
            _occupiedSlots = occupied;
            if (_services.isNotEmpty) {
              _selectedService = _services.first;
            }
            _isLoadingData = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingData = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error loading data: $e")),
          );
        }
      }
    }
  }

  Future<void> _updateOccupiedSlots(DateTime date) async {
    try {
      final occupied = await getIt<BookingRepository>().getOccupiedSlots(widget.facility.id, date);
      if (mounted) {
        setState(() {
          _selectedDate = date;
          _occupiedSlots = occupied;
        });
      }
    } catch (e) {
      debugPrint("Error updating slots: $e");
    }
  }

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  void _confirmBooking() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a service")),
      );
      return;
    }

    final timeParts = _selectedTime.split(' ');
    final hourMinute = timeParts[0].split(':');
    int hour = int.parse(hourMinute[0]);
    int minute = int.parse(hourMinute[1]);
    
    if (timeParts[1] == "PM" && hour < 12) hour += 12;
    if (timeParts[1] == "AM" && hour == 12) hour = 0;

    final appointmentTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
      minute,
    );

    final familyMemberId = (_bookingFor is FamilyMember) ? (_bookingFor as FamilyMember).id : null;

    final booking = Booking(
      id: '', 
      userId: authState.user.id,
      facilityId: widget.facility.id,
      facilityName: widget.facility.name,
      appointmentTime: appointmentTime,
      status: BookingStatus.confirmed, // CHANGED: Automatic confirmation
      createdAt: DateTime.now(),
      serviceId: _selectedService!.id,
      familyMemberId: familyMemberId,
      triageResult: widget.triageResult?.summaryForProvider,
      triagePriority: widget.triageResult?.urgency.name,
      natureOfVisit: _natureOfVisit,
      chiefComplaint: _complaintController.text,
      referredFrom: widget.triageResult != null ? "Ataman AI Triage" : null,
      referredTo: widget.facility.name,
    );

    context.read<BookingCubit>().createBooking(booking);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    String userName = "User";
    if (authState is Authenticated) {
      userName = authState.profile?.fullName ?? "User";
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<BookingCubit, BookingState>(
        listener: (context, state) {
          if (state is BookingLoaded && state.bookings.isNotEmpty) {
            final latestBooking = state.bookings.first;
            final String patientName = (_bookingFor is FamilyMember) 
                ? (_bookingFor as FamilyMember).fullName 
                : userName;

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => BookingSuccessDialog(
                booking: latestBooking,
                patientName: patientName,
              ),
            );
          } else if (state is BookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.danger),
            );
          }
        },
        builder: (context, state) {
          if (_isLoadingData) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              AtamanSimpleHeader(
                height: 120,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        "Review Booking",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.p24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.triageResult != null) ...[
                        _buildTriageSummaryCard(),
                        const SizedBox(height: 24),
                      ],
                      
                      BookingFacilityInfo(facility: widget.facility),
                      const SizedBox(height: 24),

                      const Text("Nature of Visit", style: AppTextStyles.h3),
                      const SizedBox(height: 12),
                      _buildNatureOfVisitSelector(),
                      const SizedBox(height: 24),

                      const Text("Chief Complaint", style: AppTextStyles.h3),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _complaintController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "Reason for visit...",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text("Booking For", style: AppTextStyles.h3),
                      const SizedBox(height: 12),
                      BookingMemberSelector(
                        userName: userName,
                        familyMembers: _familyMembers,
                        selectedMember: _bookingFor,
                        onMemberSelected: (val) => setState(() => _bookingFor = val),
                      ),
                      const SizedBox(height: 24),

                      const Text("Select Service", style: AppTextStyles.h3),
                      const SizedBox(height: 12),
                      _services.isEmpty 
                        ? const Text("No services available for this facility.")
                        : BookingServiceSelector(
                            services: _services,
                            selectedService: _selectedService,
                            onServiceSelected: (service) => setState(() => _selectedService = service),
                          ),
                      const SizedBox(height: 24),

                      const Text("Select Date & Time", style: AppTextStyles.h3),
                      const SizedBox(height: 12),
                      BookingDateSelector(
                        selectedDate: _selectedDate, 
                        onDateSelected: _updateOccupiedSlots,
                      ),
                      const SizedBox(height: 16),

                      const Text("Available Slots", style: AppTextStyles.caption),
                      const SizedBox(height: 12),
                      BookingTimeSelector(
                        selectedTime: _selectedTime,
                        onTimeSelected: (time) => setState(() => _selectedTime = time),
                        occupiedSlots: _occupiedSlots,
                      ),
                    ],
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(AppSizes.p24),
                child: AtamanButton(
                  text: "Confirm & Get Ticket",
                  isLoading: state is BookingLoading,
                  onPressed: _confirmBooking,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNatureOfVisitSelector() {
    final options = ["New Consultation/Case", "New Admission", "Follow-up visit"];
    return Wrap(
      spacing: 8,
      children: options.map((option) {
        final isSelected = _natureOfVisit == option;
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) setState(() => _natureOfVisit = option);
          },
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
        );
      }).toList(),
    );
  }

  Widget _buildTriageSummaryCard() {
    final result = widget.triageResult!;
    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: result.urgencyColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: result.urgencyColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: result.urgencyColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Triage Reference Included",
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: result.urgencyColor,
                  ),
                ),
                Text(
                  result.summaryForProvider ?? "Priority: ${result.urgency.name}",
                  style: AppTextStyles.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
