class Product {
  final String id;
  final String name;
  final String categoryId;
  final double price;
  int quantity;

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.quantity,
  });

  bool get isLowStock => quantity <= 10;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'categoryId': categoryId,
      'price': price,
      'quantity': quantity,
    };
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      categoryId: map['categoryId'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
    );
  }
}
