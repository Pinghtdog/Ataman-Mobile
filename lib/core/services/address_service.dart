import 'package:supabase_flutter/supabase_flutter.dart';

class AddressService {
  final _supabase = Supabase.instance.client;

  /// Fetches the list of barangays from the Supabase database.
  Future<List<String>> getNagaBarangays() async {
    try {
      final List<dynamic> response = await _supabase
          .from('barangays')
          .select('name')
          .order('name', ascending: true);
      
      return response.map((item) => item['name'] as String).toList();
    } catch (e) {
      return [
        "Abella", "Bagumbayan Norte", "Bagumbayan Sur", "Balatas",
        "Calauag", "Cararayan", "Carolina", "Concepcion Grande",
        "Concepcion Pequeña", "Dayangdang", "Del Rosario", "Dinaga",
        "Igualdad Interior", "Lerma", "Liboton", "Mabolo", "Pacol", 
        "Panicuason", "Peñafrancia", "Sabang", "San Felipe", "San Francisco",
        "San Isidro", "Santa Cruz", "Tabuco", "Tinago", "Triangulo"
      ];
    }
  }
}
