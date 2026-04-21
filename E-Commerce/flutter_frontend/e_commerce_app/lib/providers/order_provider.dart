import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool   _isLoading   = false;
  String _error       = '';

  List<Order> get orders    => List.unmodifiable(_orders.reversed.toList());
  bool   get hasOrders      => _orders.isNotEmpty;
  bool   get isLoading      => _isLoading;
  String get error          => _error;

  Future<Order?> placeOrder({
    required List<CartItem> items,
    required String shippingAddress,
    String paymentMethod = 'card',
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await ApiService.instance.post(
        ApiEndpoints.orders,
        {
          'items': items.map((i) => {
            'id':       i.product.id,
            'name':     i.product.name,
            'price':    i.product.price,
            'quantity': i.quantity,
            'imageEmoji': i.product.imageEmoji,
            'colorHex':   i.product.colorHex,
          }).toList(),
          'shippingAddress': shippingAddress,
          'paymentMethod':   paymentMethod,
        },
      );

      final order = _orderFromJson(response['data']);
      _orders.add(order);
      _isLoading = false;
      notifyListeners();
      return order;
    } on ApiException catch (e) {
      _error = e.message;
      if (kDebugMode) print('[OrderProvider] $e');
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Failed to place order. Please try again.';
      if (kDebugMode) print('[OrderProvider] $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await ApiService.instance.get(ApiEndpoints.orders);
      _orders = (response['data'] as List)
          .map((j) => _orderFromJson(j as Map<String, dynamic>))
          .toList();
      _error = '';
    } on ApiException catch (e) {
      _error = e.message;
      if (kDebugMode) print('[OrderProvider] $e');
    } catch (e) {
      _error = 'Failed to load orders.';
      if (kDebugMode) print('[OrderProvider] $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    try {
      await ApiService.instance.patch(ApiEndpoints.cancelOrder(orderId));
      _orders = _orders.map((o) {
        if (o.id == orderId) {
          return Order(
            id: o.id, items: o.items, total: o.total,
            createdAt: o.createdAt, status: OrderStatus.cancelled,
            shippingAddress: o.shippingAddress,
          );
        }
        return o;
      }).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Order _orderFromJson(Map<String, dynamic> json) {
    OrderStatus parseStatus(String s) {
      switch (s) {
        case 'shipped':   return OrderStatus.shipped;
        case 'delivered': return OrderStatus.delivered;
        case 'cancelled': return OrderStatus.cancelled;
        default:          return OrderStatus.processing;
      }
    }

    return Order(
      id:              json['id'] as String,
      items:           [],
      total:           (json['total'] as num).toDouble(),
      createdAt:       DateTime.parse(json['createdAt'] as String),
      status:          parseStatus(json['status'] as String),
      shippingAddress: json['shippingAddress'] as String,
    );
  }
}
