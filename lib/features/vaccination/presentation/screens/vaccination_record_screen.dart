import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/constants.dart';
import '../../../auth/logic/auth_cubit.dart';
import '../../data/models/vaccine_model.dart';
import '../../data/repositories/vaccine_repository.dart';
import '../widgets/immunization_id_card.dart';
import '../widgets/vaccination_timeline_item.dart';
import '../../../../injector.dart';

class VaccinationRecordScreen extends StatefulWidget {
  const VaccinationRecordScreen({super.key});

  @override
  State<VaccinationRecordScreen> createState() => _VaccinationRecordScreenState();
}

class _VaccinationRecordScreenState extends State<VaccinationRecordScreen> {
  late Future<List<VaccineRecord>> _recordsFuture;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _refreshRecords();
  }

  void _refreshRecords() {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      setState(() {
        _recordsFuture = getIt<VaccineRepository>().getUserVaccineRecords(authState.user!.id);
      });
    }
  }

  List<VaccineRecord> _filterRecords(List<VaccineRecord> records) {
    if (_selectedFilter == 'All') return records;
    return records.where((r) {
      if (_selectedFilter == 'Completed') return r.status.toUpperCase() == 'COMPLETED';
      if (_selectedFilter == 'Due') return r.status.toUpperCase() == 'PENDING';
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    String patientName = 'Patient';
    String dob = 'N/A';

    if (authState is Authenticated) {
      patientName = authState.profile?.fullName ?? patientName;
      dob = authState.profile?.birthDate != null 
          ? authState.profile!.birthDate.toString().split(' ')[0] 
          : dob;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Immunization Record',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshRecords(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.p20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ImmunizationIdCard(
                patientName: patientName,
                dob: dob,
                immunizationId: authState is Authenticated ? 'PH-${authState.user!.id.substring(0, 8).toUpperCase()}' : 'N/A',
              ),
              const SizedBox(height: 24),
              _buildFilters(),
              const SizedBox(height: 24),
              const Text(
                'Vaccination History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<VaccineRecord>>(
                future: _recordsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final allRecords = snapshot.data ?? [];
                  final filteredRecords = _filterRecords(allRecords);
                  
                  if (filteredRecords.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text('No records found for this filter.'),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredRecords.length,
                    itemBuilder: (context, index) {
                      final record = filteredRecords[index];
                      return VaccinationTimelineItem(
                        title: record.vaccineName ?? 'Unknown Vaccine',
                        subtitle: 'Dose ${record.doseNumber} • ${record.remarks ?? 'No remarks'}',
                        date: record.administeredAt != null 
                            ? _formatDate(record.administeredAt!)
                            : (record.nextDoseDue != null ? 'Due: ${_formatDate(record.nextDoseDue!)}' : 'TBD'),
                        location: record.providerName ?? 'Assigned Facility',
                        isCompleted: record.status.toUpperCase() == 'COMPLETED',
                        isDue: record.status.toUpperCase() == 'PENDING',
                      );
                    },
                  );
                }
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildFilters() {
    return Row(
      children: [
        _buildFilterChip('All'),
        const SizedBox(width: 8),
        _buildFilterChip('Completed'),
        const SizedBox(width: 8),
        _buildFilterChip('Due'),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF333333) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
