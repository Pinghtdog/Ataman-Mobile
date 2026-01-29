class Vaccine {
  final String id;
  final String name;
  final String? abbr;
  final String? description;
  final String? manufacturer;
  final int dosesRequired;
  final int minAgeMonths;
  final bool isActive;
  final List<VaccineInventory>? inventory;

  Vaccine({
    required this.id,
    required this.name,
    this.abbr,
    this.description,
    this.manufacturer,
    this.dosesRequired = 1,
    this.minAgeMonths = 0,
    this.isActive = true,
    this.inventory,
  });

  factory Vaccine.fromMap(Map<String, dynamic> map) {
    return Vaccine(
      id: map['id'],
      name: map['name'],
      abbr: map['abbr'],
      description: map['description'],
      manufacturer: map['manufacturer'],
      dosesRequired: map['doses_required'] ?? 1,
      minAgeMonths: map['min_age_months'] ?? 0,
      isActive: map['is_active'] ?? true,
      inventory: map['facility_vaccines'] != null
          ? (map['facility_vaccines'] as List)
              .map((i) => VaccineInventory.fromMap(i))
              .toList()
          : null,
    );
  }

  bool get hasStock => inventory?.any((i) => i.stockCount > 0) ?? false;
}

class VaccineInventory {
  final String id;
  final int facilityId; // Add this
  final int stockCount;
  final String status;
  final String? facilityName;

  VaccineInventory({
    required this.id,
    required this.facilityId,
    required this.stockCount,
    required this.status,
    this.facilityName,
  });

  factory VaccineInventory.fromMap(Map<String, dynamic> map) {
    return VaccineInventory(
      id: map['id'],
      facilityId: map['facility_id'] ?? 0, // Map the facility_id
      stockCount: map['stock_count'] ?? 0,
      status: map['status'] ?? 'NO_STOCK',
      facilityName: map['facilities']?['name'],
    );
  }
}

class VaccineRecord {
  final String id;
  final String userId;
  final String vaccineId;
  final String? vaccineName;
  final int doseNumber;
  final DateTime? administeredAt;
  final DateTime? nextDoseDue;
  final String status;
  final String? providerName;
  final String? remarks;

  VaccineRecord({
    required this.id,
    required this.userId,
    required this.vaccineId,
    this.vaccineName,
    required this.doseNumber,
    this.administeredAt,
    this.nextDoseDue,
    required this.status,
    this.providerName,
    this.remarks,
  });

  factory VaccineRecord.fromMap(Map<String, dynamic> map) {
    return VaccineRecord(
      id: map['id'],
      userId: map['user_id'],
      vaccineId: map['vaccine_id'],
      vaccineName: map['vaccines']?['name'],
      doseNumber: map['dose_number'] ?? 1,
      administeredAt: map['administered_at'] != null 
          ? DateTime.parse(map['administered_at']) 
          : null,
      nextDoseDue: map['next_dose_due'] != null 
          ? DateTime.parse(map['next_dose_due']) 
          : null,
      status: map['status'] ?? 'PENDING',
      providerName: map['provider_name'],
      remarks: map['remarks'],
    );
  }
}
