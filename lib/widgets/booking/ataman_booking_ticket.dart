import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../constants/constants.dart';

class AtamanBookingTicket extends StatelessWidget {
  final String patientName;
  final String serviceName;
  final String facilityName;
  final DateTime date;
  final String time;
  final String ticketId;

  const AtamanBookingTicket({
    super.key,
    required this.patientName,
    required this.serviceName,
    required this.facilityName,
    required this.date,
    required this.time,
    required this.ticketId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSizes.p24),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSizes.radiusLarge),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 64,
                ),
                const SizedBox(height: AppSizes.p12),
                Text(
                  "Booking Successful!",
                  style: AppTextStyles.h3.copyWith(color: AppColors.success),
                ),
                const SizedBox(height: AppSizes.p4),
                Text(
                  "Ticket ID: $ticketId",
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          // 2. Ticket Details
          Padding(
            padding: const EdgeInsets.all(AppSizes.p24),
            child: Column(
              children: [
                _buildDetailRow("Patient", patientName),
                const SizedBox(height: AppSizes.p16),
                _buildDetailRow("Service", serviceName),
                const SizedBox(height: AppSizes.p16),
                _buildDetailRow("Facility", facilityName),
                const SizedBox(height: AppSizes.p16),
                
                const Divider(height: 32, thickness: 1),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "DATE",
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSizes.p4),
                        Text(
                          "${date.month}/${date.day}/${date.year}", 
                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "TIME",
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSizes.p4),
                        Text(
                          time,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold, 
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // QR Code Section
          Padding(
            padding: const EdgeInsets.only(
              bottom: AppSizes.p32, 
              left: AppSizes.p32, 
              right: AppSizes.p32,
            ),
            child: QrImageView(
              data: ticketId,
              version: QrVersions.auto,
              size: 180.0,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.primary,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        const SizedBox(width: AppSizes.p16),
        Expanded(
          child: Text(
            value, 
            textAlign: TextAlign.end,
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
