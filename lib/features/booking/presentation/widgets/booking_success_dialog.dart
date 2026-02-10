import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/booking_model.dart';
import 'booking_qr_dialog.dart';

class BookingSuccessDialog extends StatelessWidget {
  final Booking booking;
  final String patientName;

  const BookingSuccessDialog({
    super.key,
    required this.booking,
    required this.patientName,
  });

  void _addToCalendar() {
    final Event event = Event(
      title: 'Medical Appointment: ${booking.facilityName}',
      description: 'Service: ${booking.natureOfVisit}\nPatient: $patientName\nReference: BHC-${_formatRef(booking.id)}',
      location: booking.facilityName,
      startDate: booking.appointmentTime,
      endDate: booking.appointmentTime.add(const Duration(minutes: 30)),
      allDay: false,
    );

    Add2Calendar.addEvent2Cal(event);
  }

  void _showQrCode(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BookingQrDialog(booking: booking),
    );
  }

  String _formatRef(String id) {
    if (id.isEmpty) return "0000";
    if (id.contains('-')) {
      final lastPart = id.split('-').last;
      return lastPart.length >= 4 ? lastPart.substring(0, 4).toUpperCase() : lastPart.toUpperCase();
    }
    return id.padLeft(4, '0').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? screenWidth * 0.2 : 24, 
        vertical: 24
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: screenHeight * 0.85,
            ),
            margin: const EdgeInsets.only(top: 45), 
            padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Booking Confirmed",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Please arrive 10 minutes early.",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "REF: BHC-${_formatRef(booking.id)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        
                        _buildDetailItem("HEALTH CENTER", booking.facilityName),
                        _buildDetailItem("SERVICE", booking.natureOfVisit), 
                        
                        Row(
                          children: [
                            Expanded(child: _buildDetailItem("DATE", DateFormat('MMM dd, yyyy').format(booking.appointmentTime))),
                            Expanded(child: _buildDetailItem("TIME", DateFormat('h:mm a').format(booking.appointmentTime))),
                          ],
                        ),
                        
                        _buildDetailItem("PATIENT", patientName),
                        
                        const SizedBox(height: 24),
                        
                        // QR Scan Box - Clickable
                        InkWell(
                          onTap: () => _showQrCode(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D3238),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: QrImageView(
                                    data: booking.id,
                                    version: QrVersions.auto,
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Scan at Reception",
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      Text(
                                        "Tap to view full QR code.",
                                        style: TextStyle(color: Colors.white70, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.open_in_full_rounded, color: Colors.white54, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                AtamanButton(
                  text: "Add to Calendar",
                  onPressed: _addToCalendar,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
                  },
                  child: const Text(
                    "Back to Home",
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          
          Positioned(
            top: 5, 
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4), 
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(38),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}
