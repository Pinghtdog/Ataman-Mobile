import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../../features/medicine_access/data/models/facility_medicine_model.dart';
import 'notification_service.dart';
import '../../injector.dart';

class MedicineAlertService {
  final SupabaseClient _supabase;
  final NotificationService _notificationService = getIt<NotificationService>();

  MedicineAlertService(this._supabase);

  void watchMedicineStock(String medicineId, String medicineName) {
    _supabase
        .from('facility_medicines:medicine_id=eq.$medicineId')
        .stream(primaryKey: ['id'])
        .listen((data) {
      for (var json in data) {
        final stock = FacilityMedicine.fromMap(json);
        if (stock.isInStock) {
          _notificationService.showNotification(
            title: 'Medicine In Stock!',
            body: '$medicineName is now available at ${stock.facilityName}!',
          );
        }
      }
    });
  }
}
