import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/constants.dart';
import '../../data/models/booking_model.dart';

class AtamanBookingTicket extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const AtamanBookingTicket({
    super.key,
    required this.booking,
    required this.onTap,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCancelled = booking.status == BookingStatus.cancelled;
    final bool isCompleted = booking.status == BookingStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      ),
                      child: const Icon(Icons.medical_services_outlined, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.facilityName,
                            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            DateFormat('MMMM dd, yyyy • hh:mm a').format(booking.appointmentTime),
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Ticket ID: ${booking.id}", style: AppTextStyles.caption),
                    if (onCancel != null && !isCancelled && !isCompleted)
                      TextButton(
                        onPressed: onCancel,
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        child: const Text("Cancel", style: TextStyle(color: AppColors.danger)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color = Colors.grey;
    String text = booking.status.name.toUpperCase();

    switch (booking.status) {
      case BookingStatus.pending:
        color = Colors.orange;
        break;
      case BookingStatus.confirmed:
        color = AppColors.success;
        break;
      case BookingStatus.completed:
        color = AppColors.primary;
        break;
      case BookingStatus.cancelled:
        color = AppColors.danger;
        break;
      case BookingStatus.missed:
        color = Colors.black;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}
