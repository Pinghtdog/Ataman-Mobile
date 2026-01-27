class AppStrings {
  // App General
  static const String appName = "ATAMAN";
  static const String tagLine = "AI-Powered Healthcare Assistant";

  // Auth
  static const String loginTitle = "Welcome Back";
  static const String loginSubtitle = "Sign in to access your medical records";
  static const String emailLabel = "Email Address";
  static const String passwordLabel = "Password";
  static const String forgotPassword = "Forgot Password?";
  static const String loginButton = "Sign In";
  static const String registerText = "Don't have an account? Sign Up";
  static const String registerTitle = "Create Account";

  // Triage / Assessment
  static const String triageTitle = "AI Triage Assessment";
  static const String startAssessment = "Start Assessment";
  static const String symptomInputLabel = "Describe your symptoms...";
  static const String emergencyWarning = "If this is a life-threatening emergency, call 911 immediately.";

  // AI Triage Prompt
  static const String triageSystemPrompt = '''
    You are the ATAMAN AI Triage Engine, the primary healthcare router for Naga City, Philippines.
    
    CORE GOALS:
    1. Identify life-threatening "Red Flags" immediately.
    2. Decongest Naga City General Hospital (NCGH) by routing minor cases to Telemedicine or Barangay Health Centers (BHC).
    3. Generate professional medical documentation (SOAP Notes) for the receiving facility.
    4. DIVERSION PROTOCOL: If you receive a [DIVERSION ALERT] for a facility, DO NOT recommend it. Instead, proactively suggest the nearest available alternative of the same capability level.

    CRITICAL SAFETY RULES:
    1. SUICIDE/SELF-HARM: If detected, IMMEDIATELY set `is_final: true`, `urgency: EMERGENCY`, and `recommended_action: HOSPITAL_ER`.
    2. RED FLAGS: Chest pain, difficulty breathing, stroke signs = EMERGENCY.

    GUIDELINES:
    1. LANGUAGE: The "question" field MUST match the user's dialect (Bicolano/Tagalog/English). All other values MUST be English.
    2. STEP LIMIT: Reach a decision by Step #7.
    3. PRIORITY HIERARCHY: Trauma > Pregnancy > Infectious Disease > General Pain.

    OUTPUT FORMAT (STRICT JSON):
    {
      "is_final": boolean,
      "question": "string (user's language)",
      "input_type": "BUTTONS" | "TEXT",
      "options": ["string"],
      "result": {
        "urgency": "ROUTINE" | "URGENT" | "EMERGENCY",
        "case_category": "string",
        "recommended_action": "TELEMEDICINE" | "BHC_APPOINTMENT" | "HOSPITAL_ER" | "AMBULANCE_DISPATCH",
        "required_capability": "BARANGAY_HEALTH_STATION" | "INFIRMARY" | "HOSPITAL_LEVEL_1" | "HOSPITAL_LEVEL_2" | "HOSPITAL_LEVEL_3",
        "is_telemed_suitable": boolean,
        "ai_confidence": number,
        "specialty": "string",
        "reason": "string (English)",
        "summary_for_provider": "string",
        "soap_note": { "subjective": "...", "objective": "...", "assessment": "...", "plan": "..." }
      }
    }
  ''';

  // Dashboard
  static const String home = "Home";
  static const String history = "History";
  static const String profile = "Profile";
  static const String recentAssessments = "Recent Assessments";

  // Statuses
  static const String statusCritical = "Critical";
  static const String statusStable = "Stable";
  static const String statusCheckup = "Routine Checkup";

  // Vaccination
  static const String vaccinationServices = "Vaccination Services";
  static const String myImmunizationCard = "My Immunization Card";
  static const String viewHistoryAndUpcomingDoses = "View history and upcoming doses";
  static const String viewRecord = "VIEW RECORD";
  static const String availableVaccines = "Available Vaccines";
  static const String all = "All";
  static const String kids = "Kids";
  static const String adults = "Adults";
  static const String seniors = "Seniors";
  static const String influenzaFluVaccine = "Influenza (Flu) Vaccine";
  static const String prioritySeniorsIndigents = "Priority: Seniors & Indigents";
  static const String pneumococcal23 = "Pneumococcal 23";
  static const String lifetimeProtection = "Lifetime protection";
  static const String antiRabies = "Anti-Rabies";
  static const String animalBiteCenterOnly = "Animal Bite Center Only";
  static const String tetanusToxoid = "Tetanus Toxoid";
  static const String checkAvailability = "Check availability";
  static const String inStock = "IN STOCK";
  static const String limited = "LIMITED";
  static const String noStock = "NO STOCK";

  // Book Vaccination
  static const String bookVaccination = "Book Vaccination";
  static const String stockReservedForBooking = "Stock Reserved for Booking";
  static const String concepcionPequenaBHC = "Concepcion Pequeña BHC • 120 Left";
  static const String vaccine = "Vaccine";
  static const String patient = "Patient";
  static const String myself = "Myself";
  static const String miguelSon = "Miguel (Son)";
  static const String schedule = "Schedule";
  static const String date = "DATE";
  static const String time = "TIME";
  static const String healthScreening = "Health Screening";
  static const String doYouHaveFever = "Do you have a fever today?";
  static const String yes = "Yes";
  static const String no = "No";
  static const String confirmVaccinationSlot = "Confirm Vaccination Slot";

  // Errors
  static const String genericError = "Something went wrong. Please try again.";
  static const String fieldRequired = "This field is required";
  static const String invalidEmail = "Please enter a valid email";
}
