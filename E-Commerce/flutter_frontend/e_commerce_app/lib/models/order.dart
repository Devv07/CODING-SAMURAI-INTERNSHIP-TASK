import 'cart_item.dart';

enum OrderStatus { processing, shipped, delivered, cancelled }

class Order {
  final String id;
  final List<CartItem> items;
  final double total;
  final DateTime createdAt;
  final OrderStatus status;
  final String shippingAddress;

  const Order({
    required this.id,
    required this.items,
    required this.total,
    required this.createdAt,
    required this.status,
    required this.shippingAddress,
  });

  int get itemCount => items.fold(0, (s, i) => s + i.quantity);

  String get statusLabel {
    switch (status) {
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}
