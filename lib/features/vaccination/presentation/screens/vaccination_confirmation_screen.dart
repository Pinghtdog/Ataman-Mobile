import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../data/models/vaccine_model.dart';

class VaccinationConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const VaccinationConfirmationScreen({
    super.key,
    required this.bookingData,
  });

  void _addToCalendar() {
    final DateTime date = bookingData['date'];
    final TimeOfDay time = bookingData['time'];
    final DateTime start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    
    final Event event = Event(
      title: 'Vaccination: ${bookingData['vaccineName']}',
      description: 'Dose 1 of 1 at Concepcion Pequeña BHC',
      location: 'Concepcion Pequeña BHC',
      startDate: start,
      endDate: start.add(const Duration(hours: 1)),
    );

    Add2Calendar.addEvent2Cal(event);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00695C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildConfirmationCard(context),
              const Spacer(),
              ElevatedButton(
                onPressed: _addToCalendar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF00695C),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.p24)),
                ),
                child: const Text('Add to Calendar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false),
                child: const Text('Back to Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.p24),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: -30,
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 32),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.p24),
            child: Column(
              children: [
                const SizedBox(height: 30),
                const Text(
                  'Vaccination Confirmed',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '✓ STOCK RESERVED',
                    style: TextStyle(color: Color(0xFF4CAF50), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'REF: VAX-FL-2023',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 24),
                _buildInfoRow('VACCINE', bookingData['vaccineName'] ?? 'Influenza (Flu)', color: Colors.purple),
                const Text('Dose 1 of 1', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildInfoRow('DATE', bookingData['dateString'] ?? 'Oct 25')),
                    Expanded(child: _buildInfoRow('TIME', bookingData['timeString'] ?? '8:00 AM')),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow('LOCATION', 'Concepcion Pequeña BHC'),
                const SizedBox(height: 16),
                _buildInfoRow('PATIENT', bookingData['patientName'] ?? 'Juan Dela Cruz', isPatient: true),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(AppSizes.p16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.qr_code, size: 40),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Inventory Claim Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('Present this to claim vaccine.', style: TextStyle(color: Colors.white70, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color, bool isPatient = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        isPatient 
          ? Row(
              children: [
                const CircleAvatar(radius: 12, backgroundColor: Color(0xFF00695C), child: Text('J', style: TextStyle(color: Colors.white, fontSize: 10))),
                const SizedBox(width: 8),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            )
          : Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color ?? Colors.black,
              ),
            ),
      ],
    );
  }
}
