import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../constants/constants.dart';
import '../../data/models/booking_model.dart';

class BookingQrDialog extends StatelessWidget {
  final Booking booking;

  const BookingQrDialog({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLarge)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Booking Appointment",
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.p8),
            Text(
              booking.facilityName,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.p24),
            Container(
              padding: const EdgeInsets.all(AppSizes.p16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: QrImageView(
                data: booking.id,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: AppSizes.p24),
            Text(
              "Show this QR code at the facility reception for quick check-in.",
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.p24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSmall)),
                ),
                child: const Text("Close", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
