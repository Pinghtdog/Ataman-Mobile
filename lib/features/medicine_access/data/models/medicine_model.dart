class Medicine {
  final String id;
  final String name;
  final String? description;
  final String? category;

  Medicine({
    required this.id,
    required this.name,
    this.description,
    this.category,
  });

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      category: map['category'] as String?,
    );
  }
}
