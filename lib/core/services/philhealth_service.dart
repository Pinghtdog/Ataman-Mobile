import '../../features/auth/data/models/user_model.dart';
import '../../features/triage/data/models/triage_model.dart';

enum PhilHealthBenefitType { inpatient, outpatient, zBenefit, sdgRelated, maternity }

class PhilHealthBenefit {
  final String name;
  final String amount;
  final String requirements;
  final PhilHealthBenefitType type;
  final List<String> keywords; 
  final List<String> recommendedFacilityIds;
  final List<String>? treatmentSteps; // Step-by-step guide for Z-Benefits

  PhilHealthBenefit({
    required this.name,
    required this.amount,
    required this.requirements,
    required this.type,
    required this.keywords,
    required this.recommendedFacilityIds,
    this.treatmentSteps,
  });
}

class PhilHealthService {
  final List<PhilHealthBenefit> _benefits = [
    // --- INPATIENT COMMON ---
    PhilHealthBenefit(
      name: "Dengue Fever (Level 1)",
      amount: "₱10,000",
      requirements: "Confinement in accredited facility",
      type: PhilHealthBenefitType.inpatient,
      keywords: ['dengue', 'mosquito', 'high fever', 'platelet'],
      recommendedFacilityIds: ['2255', '2277'],
    ),
    PhilHealthBenefit(
      name: "Pneumonia (Moderate Risk)",
      amount: "₱15,000",
      requirements: "X-ray and Confinement",
      type: PhilHealthBenefitType.inpatient,
      keywords: ['pneumonia', 'lung', 'breathing', 'cough'],
      recommendedFacilityIds: ['2255', '2277'],
    ),

    // --- Z BENEFITS (CATASTROPHIC) ---
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
      name: "Kidney Transplant (Low Risk)",
      amount: "₱600,000",
      requirements: "For End-Stage Renal Disease",
      type: PhilHealthBenefitType.zBenefit,
      keywords: ['kidney', 'renal', 'transplant', 'dialysis'],
      recommendedFacilityIds: ['2255'],
      treatmentSteps: [
        "Undergo evaluation by the Nephrology Team at BMC.",
        "Identify and screen a compatible kidney donor.",
        "Obtain Social Service certification for anti-rejection meds.",
        "File for Z-Benefit Pre-authorization."
      ],
    ),

    // --- SDG / PUBLIC HEALTH (Naga CHO Specialties) ---
    PhilHealthBenefit(
      name: "Animal Bite Treatment Package",
      amount: "₱3,900",
      requirements: "Category III Rabies Exposure",
      type: PhilHealthBenefitType.sdgRelated,
      keywords: ['dog bite', 'cat bite', 'rabies', 'animal scratch', 'bite'],
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
      name: "Outpatient Malaria Package",
      amount: "₱780.00",
      requirements: "Positive Smear/RDT",
      type: PhilHealthBenefitType.sdgRelated,
      keywords: ['malaria', 'chills', 'mosquito'],
      recommendedFacilityIds: ['CHO1'],
    ),

    // --- MATERNITY ---
    PhilHealthBenefit(
      name: "Maternity Care Package",
      amount: "₱6,500 - ₱8,000",
      requirements: "Prenatal checkups required",
      type: PhilHealthBenefitType.maternity,
      keywords: ['pregnant', 'delivery', 'birth', 'baby', 'labor'],
      recommendedFacilityIds: ['2277', 'CHO2'],
    ),
    PhilHealthBenefit(
      name: "Newborn Care Package",
      amount: "₱2,950",
      requirements: "Newborn Screening & Hearing Test",
      type: PhilHealthBenefitType.maternity,
      keywords: ['newborn', 'baby', 'infant'],
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

  /// Intelligent matching of symptoms/diagnosis to benefits
  Map<String, dynamic>? matchBenefitToCondition(String diagnosisOrSymptoms) {
    String input = diagnosisOrSymptoms.toLowerCase();
    try {
      final benefit = _benefits.firstWhere((b) => b.keywords.any((k) => input.contains(k)));
      final facilities = _nagaFacilities.where((f) => benefit.recommendedFacilityIds.contains(f['id'])).toList();
      return {'found': true, 'benefit': benefit, 'facilities': facilities};
    } catch (e) {
      return null;
    }
  }

  /// Returns the User's Eligibility Status string
  String checkEligibilityStatus(UserModel user) {
    if (user.philhealthId != null && validatePIN(user.philhealthId!)) {
      return "Active Member";
    }
    if (user.is4psMember) {
      return "Active (Indigent/4Ps)";
    }
    return "Verification Required";
  }

  /// PhilHealth PIN Validation (12 digits)
  bool validatePIN(String pin) {
    final cleanPIN = pin.replaceAll(RegExp(r'[^0-9]'), '');
    return cleanPIN.length == 12;
  }
}
