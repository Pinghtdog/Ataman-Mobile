import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/family_member_model.dart';

class FamilyRepository {
  final SupabaseClient _supabase;

  FamilyRepository(this._supabase);

  Future<List<FamilyMember>> getFamilyMembers(String userId) async {
    final response = await _supabase
        .from('family_members')
        .select()
        .eq('user_id', userId);
    
    return (response as List).map((json) => FamilyMember.fromMap(json)).toList();
  }
}
