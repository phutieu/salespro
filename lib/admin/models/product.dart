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
}
