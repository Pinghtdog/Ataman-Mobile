class FacilityMedicine {
  final String id;
  final String facilityId;
  final String medicineId;
  final double price;
  final int stockCount;
  final bool isInStock;
  final String? facilityName;
  final String? facilityAddress;

  FacilityMedicine({
    required this.id,
    required this.facilityId,
    required this.medicineId,
    required this.price,
    required this.stockCount,
    required this.isInStock,
    this.facilityName,
    this.facilityAddress,
  });

  factory FacilityMedicine.fromMap(Map<String, dynamic> map) {
    final facility = map['facilities'];
    return FacilityMedicine(
      id: map['id'] as String,
      facilityId: map['facility_id'].toString(),
      medicineId: map['medicine_id'] as String,
      price: (map['price'] as num).toDouble(),
      stockCount: map['stock_count'] as int,
      isInStock: map['is_in_stock'] as bool,
      facilityName: facility?['name'] as String?,
      facilityAddress: facility?['address'] as String?,
    );
  }
}
