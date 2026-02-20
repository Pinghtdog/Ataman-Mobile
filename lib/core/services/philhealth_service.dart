import '../../features/auth/data/models/user_model.dart';
import '../../features/triage/data/models/triage_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum PhilHealthBenefitType { inpatient, outpatient, zBenefit, sdgRelated, maternity, primaryCare }

class PhilHealthBenefit {
  final String name;
  final String amount;
  final String requirements;
  final PhilHealthBenefitType type;
  final List<String> keywords; 
  final List<String> recommendedFacilityIds;
  final List<String>? treatmentSteps;
  final double minimumConfidence; 

   PhilHealthBenefit({
    required this.name,
    required this.amount,
    required this.requirements,
    required this.type,
    required this.keywords,
    required this.recommendedFacilityIds,
    this.treatmentSteps,
    this.minimumConfidence = 0.3,
  });
}

class PhilHealthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  final List<PhilHealthBenefit> _benefits = [
    PhilHealthBenefit(
      name: "PhilHealth Konsulta (Yakap Naga)",
      amount: "100% Coverage (OPD)",
      requirements: "Registered at Naga CHO I/II",
      type: PhilHealthBenefitType.primaryCare,
      keywords: ['sipon', 'ubo', 'lagnat', 'checkup', 'konsulta', 'mild', 'routine', 'headache', 'sore throat'],
      recommendedFacilityIds: ['CHO1', 'CHO2'],
    ),
    PhilHealthBenefit(
      name: "Dengue Fever (Level 1)",
      amount: "₱10,000",
      requirements: "Confinement in accredited facility",
      type: PhilHealthBenefitType.inpatient,
      keywords: ['dengue', 'mosquito', 'high fever', 'platelet', 'severe fever'],
      recommendedFacilityIds: ['2255', '2277'],
    ),
    PhilHealthBenefit(
      name: "Pneumonia (Moderate Risk)",
      amount: "₱15,000",
      requirements: "X-ray and Confinement",
      type: PhilHealthBenefitType.inpatient,
      keywords: ['pneumonia', 'difficulty breathing', 'chest pain', 'severe cough'],
      recommendedFacilityIds: ['2255', '2277'],
    ),
    PhilHealthBenefit(
      name: "Breast Cancer (Stage 0-IV)",
      amount: "₱1.4 Million",
      requirements: "Signed Member Empowerment Form",
      type: PhilHealthBenefitType.zBenefit,
      keywords: ['breast cancer', 'lump', 'mastectomy', 'chemo'],
      recommendedFacilityIds: ['2255'],
      treatmentSteps: [
        "Consult with a Gynecologic Oncologist at Bicol Medical Center (BMC).",
        "Complete the Member Empowerment (ME) Form.",
        "Undergo Pre-authorization check by PhilHealth.",
        "Start treatment (Surgery/Chemotherapy/Radiation)."
      ],
    ),
    PhilHealthBenefit(
      name: "Leukemia (ALL - Children)",
      amount: "₱500,000",
      requirements: "Age 1-10 years old",
      type: PhilHealthBenefitType.zBenefit,
      keywords: ['leukemia', 'blood cancer', 'white blood cell'],
      recommendedFacilityIds: ['2255'],
      treatmentSteps: [
        "Consult with a Pediatric Oncologist at BMC.",
        "White blood cell count must be <50,000/µL.",
        "No CNS or testicular involvement at diagnosis.",
        "Obtain Pre-authorization for standard risk package."
      ],
    ),
    PhilHealthBenefit(
      name: "Animal Bite Treatment Package",
      amount: "₱3,900",
      requirements: "Category III Rabies Exposure",
      type: PhilHealthBenefitType.sdgRelated,
      keywords: ['dog bite', 'cat bite', 'rabies', 'animal scratch', 'bite', 'kagat'],
      recommendedFacilityIds: ['CHO1', 'CHO2', '2255'],
    ),
    PhilHealthBenefit(
      name: "TB-DOTS Package",
      amount: "₱4,000 - ₱5,200",
      requirements: "Diagnostic Exams & Consultation",
      type: PhilHealthBenefitType.sdgRelated,
      keywords: ['tuberculosis', 'tb', 'coughing blood', 'dots'],
      recommendedFacilityIds: ['CHO1'],
    ),
    PhilHealthBenefit(
      name: "Maternity Care Package",
      amount: "₱6,500 - ₱8,000",
      requirements: "Prenatal checkups required",
      type: PhilHealthBenefitType.maternity,
      keywords: ['pregnant', 'delivery', 'birth', 'baby', 'labor', 'pagbubuntis'],
      recommendedFacilityIds: ['2277', 'CHO2'],
    ),
  ];

  final List<Map<String, String>> _nagaFacilities = [
    {
      'id': '2255',
      'name': 'Bicol Medical Center (BMC)',
      'address': 'Panganiban Drive, Naga City',
      'type': 'Tertiary / Z-Benefit Provider',
    },
    {
      'id': '2277',
      'name': 'Naga City General Hospital',
      'address': 'Balatas, Naga City',
      'type': 'LGU Hospital / Level 2',
    },
    {
      'id': 'CHO1',
      'name': 'Naga City Health Office (Main)',
      'address': 'J. Miranda Ave (City Hall)',
      'type': 'Primary Care / Animal Bite Center',
    },
    {
      'id': 'CHO2',
      'name': 'Naga City Health Office II',
      'address': 'Sta. Cruz, Naga City',
      'type': 'Primary Care / Lying-in',
    },
  ];

  Map<String, dynamic>? matchBenefitToTriage(TriageResult result) {
    final String input = (result.summaryForProvider ?? result.rawSymptoms).toLowerCase();
    
    PhilHealthBenefit? bestMatch;
    double highestScore = 0;

    for (var benefit in _benefits) {
      double score = 0;
      int matchCount = 0;

      for (var keyword in benefit.keywords) {
        if (input.contains(keyword)) {
          matchCount++;
        }
      }

      if (matchCount > 0) {
        score = matchCount / benefit.keywords.length;

        if (result.urgency == TriageUrgency.routine && benefit.type == PhilHealthBenefitType.primaryCare) {
          score += 0.5;
        } else if (result.urgency != TriageUrgency.routine && benefit.type == PhilHealthBenefitType.inpatient) {
          score += 0.3;
        }

        if (input.contains(benefit.name.toLowerCase())) {
          score += 1.0; 
        }

        if (score > highestScore && score >= benefit.minimumConfidence) {
          highestScore = score;
          bestMatch = benefit;
        }
      }
    }

    if (bestMatch != null) {
      final facilities = _nagaFacilities.where((f) => bestMatch!.recommendedFacilityIds.contains(f['id'])).toList();
      return {
        'found': true, 
        'benefit': bestMatch, 
        'facilities': facilities,
        'confidence': (highestScore.clamp(0.0, 1.0) * 100).toInt(),
      };
    }

    return null;
  }

  String checkEligibilityStatus(UserModel user) {
    if (user.isPhilhealthVerificationValid) {
      return "Active Member";
    }
    if (user.philhealthId != null && validatePIN(user.philhealthId!)) {
      return "PIN Detected (Verify Now)";
    }
    if (user.is4psMember) {
      return "Active (Indigent/4Ps)";
    }
    return "Verification Required";
  }

  bool validatePIN(String pin) {
    final cleanPIN = pin.replaceAll(RegExp(r'[^0-9]'), '');
    return cleanPIN.length == 12;
  }

  Future<void> syncVerifiedData(String userId, Map<String, dynamic> portalData) async {
    // Standardize DOB format from MM-DD-YYYY to YYYY-MM-DD for Supabase
    String dob = portalData['dob'] ?? '';
    if (dob.contains('-')) {
      final parts = dob.split('-');
      if (parts.length == 3) {
        dob = "${parts[2]}-${parts[0]}-${parts[1]}";
      }
    }

    await _supabase.from('users').update({
      'is_philhealth_verified': true,
      'philhealth_verified_at': DateTime.now().toIso8601String(),
      'philhealth_id': portalData['pin'],
      'first_name': portalData['firstName'],
      'last_name': portalData['lastName'],
      'middle_name': portalData['middleName'],
      'suffix': portalData['suffix'],
      'birth_date': dob,
      'gender': portalData['sex'],
      'philhealth_status': 'Active Member',
      'is_profile_complete': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> updateVerificationStatus(String userId, bool status) async {
    await _supabase.from('users').update({
      'is_philhealth_verified': status,
      'philhealth_verified_at': status ? DateTime.now().toIso8601String() : null,
      'philhealth_status': status ? 'Active Member' : 'Verification Required',
    }).eq('id', userId);
  }
}
