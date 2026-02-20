import 'dart:async';

/// Mock Service to simulate interactions with the MyNaga Citizen App API.
/// This provides data that matches the test resident in the public.users table.
class MyNagaService {

  /// Simulates the OAuth 2.0 flow to get a citizen's profile data.
  Future<Map<String, dynamic>> fetchCitizenProfile(String authorizationCode) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // This mock data matches the SQL setup and includes the unique MyNaga Link
    return {
      'mynaga_id': 'NAGA-RESIDENT-001', // The "Bridge" ID
      'is_mynaga_verified': true,
      'email': 'test_resident@naga.gov.ph',
      'first_name': 'Juan',
      'last_name': 'Resident',
      'middle_name': '',
      'birth_date': '1990-01-01',
      'barangay': 'Concepcion Pequeña',
      'civil_status': 'Single',
      'educational_attainment': 'College Graduate',
      'employment_status': 'Employed',
      'is_4ps_member': false,
      'gender': 'Male',
      'phone_number': '09123456789',
    };
  }

  /// Simulates checking if a user exists in the MyNaga system.
  Future<bool> checkUserExists(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return email.toLowerCase() == 'test_resident@naga.gov.ph';
  }
}
