import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medicine_model.dart';
import '../models/facility_medicine_model.dart';

class MedicineRepository {
  final SupabaseClient _supabase;

  MedicineRepository(this._supabase);

  Future<List<Medicine>> getMedicines() async {
    final response = await _supabase.from('medicines').select();
    return (response as List).map((json) => Medicine.fromMap(json)).toList();
  }

  Future<List<FacilityMedicine>> getFacilityMedicineStock(String medicineId) async {
    final response = await _supabase
        .from('facility_medicines')
        .select('*, facilities(name, address, contact_number)')
        .eq('medicine_id', medicineId);

    return (response as List).map((json) => FacilityMedicine.fromMap(json)).toList();
  }

  Stream<List<FacilityMedicine>> watchMedicineStock(String medicineId) {
    return _supabase
        .from('facility_medicines:medicine_id=eq.$medicineId')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((json) => FacilityMedicine.fromMap(json)).toList());
  }
}
