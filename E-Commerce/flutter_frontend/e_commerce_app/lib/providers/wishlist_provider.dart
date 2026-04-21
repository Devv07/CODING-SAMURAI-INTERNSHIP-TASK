import 'package:flutter/foundation.dart';
import '../models/product.dart';

class WishlistProvider extends ChangeNotifier {
  final List<Product> _items = [];

  List<Product> get items => List.unmodifiable(_items);
  int get count => _items.length;

  bool contains(String productId) => _items.any((p) => p.id == productId);

  void toggle(Product product) {
    if (contains(product.id)) {
      _items.removeWhere((p) => p.id == product.id);
    } else {
      _items.add(product);
    }
    notifyListeners();
  }

  void remove(String productId) {
    _items.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}