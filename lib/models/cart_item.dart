import '../models/product.dart';

/// CartItem represents a product added to the shopping cart
class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  /// Total price for this cart line item
  double get totalPrice => product.price * quantity;

  /// Increase quantity by 1
  void increment() => quantity++;

  /// Decrease quantity by 1 (minimum 1)
  void decrement() {
    if (quantity > 1) quantity--;
  }

  @override
  String toString() =>
      'CartItem{product: ${product.name}, quantity: $quantity, total: $totalPrice}';
}
