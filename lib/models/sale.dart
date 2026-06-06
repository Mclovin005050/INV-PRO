class Sale {
  final String id;
  final String productId;
  final int quantity;
  final DateTime date;
  final double totalPrice;

  Sale({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.date,
    required this.totalPrice,
  });
}
