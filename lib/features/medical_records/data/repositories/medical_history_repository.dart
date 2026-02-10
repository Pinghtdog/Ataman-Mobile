import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medical_history_model.dart';

class MedicalHistoryRepository {
  final SupabaseClient _supabase;

  MedicalHistoryRepository(this._supabase);

  Future<List<MedicalHistoryItem>> getMedicalHistory(String userId) async {
    final response = await _supabase
        .from('medical_history')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);

    return (response as List).map((json) => MedicalHistoryItem.fromMap(json)).toList();
  }

  Future<void> addMedicalHistory(MedicalHistoryItem item, String userId) async {
    await _supabase.from('medical_history').insert({
      'user_id': userId,
      'title': item.title,
      'subtitle': item.subtitle,
      'date': item.date.toIso8601String(),
      'type': item.type.name,
      'tag': item.tag,
      'extra_info': item.extraInfo,
      'has_pdf': item.hasPdf,
      'file_url': item.fileUrl,
      'subjective': item.subjective,
      'objective': item.objective,
      'assessment': item.assessment,
      'plan': item.plan,
    });
  }
}
