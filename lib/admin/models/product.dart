class Product {
  final String id;
  String name;
  String description;
  String unit;
  double salePrice;
  double purchasePrice;
  int stockQuantity;
  String category;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.unit,
    required this.salePrice,
    required this.purchasePrice,
    required this.stockQuantity,
    required this.category,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      unit: map['unit'] ?? '',
      salePrice: (map['salePrice'] is int)
          ? (map['salePrice'] as int).toDouble()
          : (map['salePrice'] ?? 0.0),
      purchasePrice: (map['purchasePrice'] is int)
          ? (map['purchasePrice'] as int).toDouble()
          : (map['purchasePrice'] ?? 0.0),
      stockQuantity: map['stockQuantity'] ?? 0,
      category: map['category'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'unit': unit,
      'salePrice': salePrice,
      'purchasePrice': purchasePrice,
      'stockQuantity': stockQuantity,
      'category': category,
    };
  }
}
