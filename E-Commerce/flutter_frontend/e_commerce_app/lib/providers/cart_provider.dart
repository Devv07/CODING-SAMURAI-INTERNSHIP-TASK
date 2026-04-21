import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items      => Map.unmodifiable(_items);
  List<CartItem>     get itemList   => _items.values.toList();
  int                get itemCount  => _items.values.fold(0, (s, i) => s + i.quantity);
  double             get totalPrice => _items.values.fold(0.0, (s, i) => s + i.totalPrice);
  bool               contains(String id) => _items.containsKey(id);
  int                quantityOf(String id) => _items[id]?.quantity ?? 0;

  Future<void> loadFromBackend() async {
    try {
      final response = await ApiService.instance.get(ApiEndpoints.cart);
      final serverItems = response['data'] as List;
      _items.clear();
      for (final json in serverItems) {
        final product = Product(
          id: (json['id'] is int)
              ? json['id']
              : int.parse(json['id'].toString()),
          name:        json['name'] as String,
          price:       (json['price'] as num).toDouble(),
          category:    json['category'] as String? ?? '',
          tag:         json['tag'] as String?,
          rating:      (json['rating'] as num?)?.toDouble() ?? 0.0,
          reviews:     json['reviews'] as int? ?? 0,
          imageEmoji:  json['imageEmoji'] as String? ?? '',
          colorHex:    json['colorHex'] as String? ?? '#CCCCCC',
          description: json['description'] as String? ?? '',
        );
        _items[product.id] = CartItem(
          product:  product,
          quantity: json['quantity'] as int,
        );
      }
      notifyListeners();
    } on ApiException catch (e) {
      if (kDebugMode) print('[CartProvider] loadFromBackend: $e');
    }
  }

  Future<void> _syncToBackend() async {
    try {
      await ApiService.instance.post(
        ApiEndpoints.cartSync,
        {
          'items': _items.values.map((i) => {
            'id':          i.product.id,
            'name':        i.product.name,
            'price':       i.product.price,
            'category':    i.product.category,
            'imageEmoji':  i.product.imageEmoji,
            'colorHex':    i.product.colorHex,
            'quantity':    i.quantity,
          }).toList(),
        },
      );
    } on ApiException catch (e) {
      if (kDebugMode) print('[CartProvider] _syncToBackend: $e');
    }
  }

  void addItem(Product product) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity++;
    } else {
      _items[product.id] = CartItem(product: product);
    }
    notifyListeners();
    _syncToBackend();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
    _syncToBackend();
  }

  void increment(String productId) {
    if (_items.containsKey(productId)) {
      _items[productId]!.quantity++;
      notifyListeners();
      _syncToBackend();
    }
  }

  void decrement(String productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity <= 1) {
      _items.remove(productId);
    } else {
      _items[productId]!.quantity--;
    }
    notifyListeners();
    _syncToBackend();
  }

  Future<void> clearCart() async {
    _items.clear();
    notifyListeners();
    try {
      await ApiService.instance.delete(ApiEndpoints.cart);
    } on ApiException catch (e) {
      if (kDebugMode) print('[CartProvider] clearCart: $e');
    }
  }
}