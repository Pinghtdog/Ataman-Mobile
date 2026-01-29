import 'package:ataman/core/constants/app_strings.dart';
import 'package:ataman/features/auth/logic/auth_cubit.dart';
import 'package:ataman/features/profile/data/repositories/family_repository.dart';
import 'package:ataman/features/vaccination/data/repositories/vaccine_repository.dart';
import 'package:ataman/features/vaccination/presentation/widgets/health_screening_card.dart';
import 'package:ataman/features/vaccination/presentation/widgets/patient_selection.dart';
import 'package:ataman/features/vaccination/presentation/widgets/schedule_selector.dart';
import 'package:ataman/features/vaccination/presentation/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/constants.dart';
import '../../../../injector.dart';
import '../../data/models/vaccine_model.dart';
import '../../../profile/data/model/family_member_model.dart';
import '../../../profile/logic/family_cubit.dart';

class BookVaccinationScreen extends StatefulWidget {
  const BookVaccinationScreen({super.key});

  @override
  State<BookVaccinationScreen> createState() => _BookVaccinationScreenState();
}

class _BookVaccinationScreenState extends State<BookVaccinationScreen> {
  Vaccine? _selectedVaccine;
  VaccineInventory? _selectedFacility;
  dynamic _selectedPatient = 'Myself';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _hasFever = false;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Vaccine && _selectedVaccine == null) {
      _selectedVaccine = args;
    }
  }

  Future<void> _handleBooking() async {
    if (_selectedVaccine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vaccine')),
      );
      return;
    }

    if (_selectedFacility == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a facility')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is Authenticated) {
        final appointmentDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        String targetUserId = authState.user!.id;

        // If booking for a family member, use their specific user ID if applicable
        // Or handle it in the backend via patient_id.
        if (_selectedPatient is FamilyMember) {
           // targetUserId = _selectedPatient.id; // Optional: depending on your DB design
        }

        await getIt<VaccineRepository>().bookVaccineAppointment(
          userId: targetUserId,
          vaccineId: _selectedVaccine!.id,
          doseNumber: 1, 
          appointmentDate: appointmentDateTime,
          facilityId: _selectedFacility!.facilityId, // Use the BigInt facilityId
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vaccination appointment booked successfully!')),
          );
          Navigator.pushReplacementNamed(context, AppRoutes.vaccinationRecord);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error booking appointment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = FamilyCubit(getIt<FamilyRepository>());
        final authState = context.read<AuthCubit>().state;
        if (authState is Authenticated) {
          cubit.loadFamilyMembers(authState.user!.id);
        }
        return cubit;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(AppStrings.bookVaccination),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Vaccine Info
                  const SectionHeader(AppStrings.vaccine),
                  _buildSelectedVaccineInfo(),
                  
                  const SizedBox(height: 24),
                  
                  // 2. Facility Selection
                  const SectionHeader('Select Facility'),
                  _buildFacilityDropdown(),

                  const SizedBox(height: 24),
                  const SectionHeader(AppStrings.patient),
                  PatientSelection(
                    selectedPatient: _selectedPatient,
                    onChanged: (val) => setState(() => _selectedPatient = val),
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(AppStrings.schedule),
                  ScheduleSelector(
                    selectedDate: _selectedDate,
                    selectedTime: _selectedTime,
                    onDateChanged: (date) => setState(() => _selectedDate = date),
                    onTimeChanged: (time) => setState(() => _selectedTime = time),
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(AppStrings.healthScreening),
                  HealthScreeningCard(
                    hasFever: _hasFever,
                    onChanged: (val) => setState(() => _hasFever = val),
                  ),
                ],
              ),
            ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(_isLoading ? 'Processing...' : AppStrings.confirmVaccinationSlot),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedVaccineInfo() {
    if (_selectedVaccine == null) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(_selectedVaccine!.abbr ?? _selectedVaccine!.name[0], 
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedVaccine!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(_selectedVaccine!.description ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityDropdown() {
    final facilities = _selectedVaccine?.inventory ?? [];
    
    if (facilities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text('No facilities currently have this vaccine in stock.', 
          style: TextStyle(color: Colors.red, fontSize: 13)),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: DropdownButtonFormField<VaccineInventory>(
        isExpanded: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintText: 'Choose where to get vaccinated',
        ),
        items: facilities
            .map((inv) => DropdownMenuItem(
                  value: inv,
                  child: Text(
                    '${inv.facilityName} (${inv.status})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList(),
        onChanged: (val) => setState(() => _selectedFacility = val),
      ),
    );
  }
}
