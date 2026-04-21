import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../services/cache_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _allProducts   = [];
  List<Product> _adminProducts = [];
  String _selectedCategory     = 'All';
  String _searchQuery          = '';
  String _sortBy               = 'default';
  bool   _isLoading            = false;
  bool   _isRefreshing         = false;
  String _error                = '';

  List<Product> get adminProducts    => List.unmodifiable(_adminProducts);
  String        get selectedCategory => _selectedCategory;
  String        get searchQuery      => _searchQuery;
  String        get sortBy           => _sortBy;
  bool          get isLoading        => _isLoading;
  bool          get isRefreshing     => _isRefreshing;
  String        get error            => _error;
  bool          get hasError         => _error.isNotEmpty;
  bool          get hasProducts      => _allProducts.isNotEmpty;

  static const List<String> categories = [
    'All', 'Outerwear', 'Dresses', 'Footwear',
    'Tops', 'Bottoms', 'Accessories',
  ];

  List<Product> get filteredProducts {
    List<Product> result = List.from(_allProducts);
    if (_selectedCategory != 'All') {
      result = result.where((p) => p.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) =>
      p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q)).toList();
    }
    switch (_sortBy) {
      case 'price_asc':  result.sort((a, b) => a.price.compareTo(b.price));   break;
      case 'price_desc': result.sort((a, b) => b.price.compareTo(a.price));   break;
      case 'rating':     result.sort((a, b) => b.rating.compareTo(a.rating)); break;
    }
    return result;
  }

  Future<void> loadFromCache() async {
    final cached = await CacheService.instance.loadProducts();
    if (cached != null && cached.isNotEmpty) {
      _allProducts = cached
          .map((j) => Product.fromJson(j))
          .toList();
      notifyListeners();
    }
  }

  Future<void> fetchProducts({bool silent = false}) async {
    if (_allProducts.isEmpty) {
      _isLoading = true;
      _error = '';
      notifyListeners();
    } else if (!silent) {
      _isRefreshing = true;
      notifyListeners();
    }

    try {
      final uri = Uri.parse(ApiEndpoints.products).replace(
        queryParameters: {
          if (_selectedCategory != 'All') 'category': _selectedCategory,
          if (_searchQuery.isNotEmpty)    'search':   _searchQuery,
          if (_sortBy != 'default')       'sortBy':   _sortBy,
        },
      );
      final response = await ApiService.instance.get(
          uri.toString(), requireAuth: false);

      final fresh = (response['data'] as List)
          .map((j) => Product.fromJson(j as Map<String, dynamic>))
          .toList();

      _allProducts = fresh;
      _error = '';

      await CacheService.instance.saveProducts(
        fresh.map((p) => p.toJson()).toList(),
      );
    } on ApiException catch (e) {
      if (_allProducts.isEmpty) _error = e.message;
      if (kDebugMode) print('[ProductProvider] $e');
    } catch (e) {
      if (_allProducts.isEmpty) _error = 'Failed to load products.';
    } finally {
      _isLoading    = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllProductsAdmin() async {
    _isLoading = true; _error = ''; notifyListeners();
    try {
      final response = await ApiService.instance.get(
          ApiEndpoints.adminAllProducts);
      _adminProducts = (response['data'] as List)
          .map((j) => Product.fromJson(j as Map<String, dynamic>))
          .toList();
      _error = '';
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Failed to load products.';
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<bool> createProduct(Map<String, dynamic> body) async {
    _error = '';
    try {
      final response = await ApiService.instance.post(ApiEndpoints.products, body);
      final created = Product.fromJson(response['data'] as Map<String, dynamic>);
      _adminProducts.insert(0, created);
      _allProducts.insert(0, created);
      await CacheService.instance.clearProducts();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message; notifyListeners(); return false;
    } catch (e) {
      _error = 'Failed to create product.'; notifyListeners(); return false;
    }
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> body) async {
    _error = '';
    try {
      final response = await ApiService.instance.patch(
          ApiEndpoints.productById(id), body: body);
      final updated = Product.fromJson(response['data'] as Map<String, dynamic>);
      _adminProducts = _adminProducts.map((p) => p.id == id ? updated : p).toList();
      _allProducts   = _allProducts.map((p) => p.id == id ? updated : p).toList();
      await CacheService.instance.clearProducts();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message; notifyListeners(); return false;
    } catch (e) {
      _error = 'Failed to update product.'; notifyListeners(); return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    _error = '';
    try {
      await ApiService.instance.delete(ApiEndpoints.productById(id));
      _adminProducts = _adminProducts
          .map((p) => p.id == id ? p.copyWith(isActive: false) : p)
          .toList();
      _allProducts.removeWhere((p) => p.id == id);
      await CacheService.instance.clearProducts();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message; notifyListeners(); return false;
    } catch (e) {
      _error = 'Failed to delete product.'; notifyListeners(); return false;
    }
  }

  Future<void> toggleProductActive(Product product) async {
    await updateProduct(product.id, {'isActive': !product.isActive});
  }

  void setCategory(String c) {
    _selectedCategory = c;
    notifyListeners();
    fetchProducts(silent: true);
  }

  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setSortBy(String s) {
    _sortBy = s;
    notifyListeners();
    fetchProducts(silent: true);
  }

  void resetFilters() {
    _selectedCategory = 'All'; _searchQuery = ''; _sortBy = 'default';
    notifyListeners();
    fetchProducts(silent: true);
  }
}