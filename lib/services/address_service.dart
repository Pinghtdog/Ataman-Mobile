import 'dart:convert';
// import 'package:http/http.dart' as http; for real API

class AddressService {

  //mock list
  Future<List<String>> getNagaBarangays() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      "Abella", "Bagumbayan Norte", "Bagumbayan Sur", "Balatas",
      "Calauag", "Cararayan", "Carolina", "Concepcion Grande",
      "Concepcion Pequeña", "Dayangdang", "Del Rosario", "Dinaga",
      "Igualdad", "Lerma", "Liboton", "Mabolo", "Pacol", "Panicuason",
      "Peñafrancia", "Sabang", "San Felipe", "San Francisco",
      "San Isidro", "Santa Cruz", "Tabuco", "Tinago", "Triangulo"
    ];
  }

/* * PRODUCTION READY CODE
   * * Future<List<String>> fetchBarangaysFromApi() async {
   * final response = await http.get(Uri.parse('https://psgc.gitlab.io/api/cities/051724000/barangays/'));
   * if (response.statusCode == 200) {
   * final List data = json.decode(response.body);
   * return data.map<String>((json) => json['name'].toString()).toList();
   * } else {
   * throw Exception('Failed to load address data');
   * }
   * }
   */
}