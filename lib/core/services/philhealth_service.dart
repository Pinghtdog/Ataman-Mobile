import '../../features/auth/data/models/user_model.dart';
import '../../features/triage/data/models/triage_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Categories of PhilHealth benefits available in the application.
enum PhilHealthBenefitType { 
  /// Standard hospital confinement.
  inpatient, 
  /// Consultations and laboratory tests.
  outpatient, 
  /// High-value medical cases like cancer or transplants.
  zBenefit, 
  /// Specific programs like Animal Bite or TB-DOTS.
  sdgRelated, 
  /// Childbirth and prenatal services.
  maternity, 
  /// Primary care services under the Konsulta program.
  primaryCare 
}

/// Represents a specific PhilHealth benefit package with its matching criteria.
class PhilHealthBenefit {
  /// The official name of the benefit package.
  final String name;
  /// The maximum coverage amount or a description of the coverage (e.g., "₱10,000").
  final String amount;
  /// The required documents or conditions to claim the benefit.
  final String requirements;
  /// The category of the benefit.
  final PhilHealthBenefitType type;
  /// List of symptoms or keywords used for matching triage results.
  final List<String> keywords; 
  /// IDs of Naga City facilities that are accredited for this specific benefit.
  final List<String> recommendedFacilityIds;
  /// Optional list of clinical steps for Z-Benefit packages.
  final List<String>? treatmentSteps;
  /// The threshold for matching confidence before this benefit is suggested.
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

/// [PhilHealthService] manages the integration between medical triage results 
/// and government healthcare benefits.
///
/// It provides logic for matching symptoms to benefit packages, verifying 
/// membership eligibility, and synchronizing data with the PhilHealth portal.
class PhilHealthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Pre-defined list of PhilHealth benefits relevant to Naga City residents.
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

  /// List of major health facilities in Naga City with their PhilHealth provider types.
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

  /// Matches a [TriageResult] to the most likely PhilHealth benefit package.
  ///
  /// Analyzes keywords within the triage summary and applies scoring based on 
  /// urgency and specific case matches. 
  /// 
  /// Returns a map containing the matched benefit, accredited facilities, 
  /// and a confidence percentage, or `null` if no match is found.
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

        // Apply weight based on urgency
        if (result.urgency == TriageUrgency.routine && benefit.type == PhilHealthBenefitType.primaryCare) {
          score += 0.5;
        } else if (result.urgency != TriageUrgency.routine && benefit.type == PhilHealthBenefitType.inpatient) {
          score += 0.3;
        }

        // Exact name match bonus
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

  /// Determines the current membership eligibility status of a [user].
  ///
  /// Checks for verification validity, PIN presence, or 4Ps status.
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

  /// Validates if a [pin] string follows the 12-digit PhilHealth format.
  bool validatePIN(String pin) {
    final cleanPIN = pin.replaceAll(RegExp(r'[^0-9]'), '');
    return cleanPIN.length == 12;
  }

  /// Synchronizes identity data verified via the PhilHealth portal to the local database.
  ///
  /// Standardizes date formats and updates core user identity fields (Name, DOB, Gender)
  /// to match official government records.
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

  /// Manually updates the PhilHealth verification flag and status for a specific [userId].
  Future<void> updateVerificationStatus(String userId, bool status) async {
    await _supabase.from('users').update({
      'is_philhealth_verified': status,
      'philhealth_verified_at': status ? DateTime.now().toIso8601String() : null,
      'philhealth_status': status ? 'Active Member' : 'Verification Required',
    }).eq('id', userId);
  }
}
