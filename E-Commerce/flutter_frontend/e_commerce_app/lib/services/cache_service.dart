import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  static const _productsKey   = 'cached_products';
  static const _productsTsKey = 'cached_products_ts';
  static const _maxAgeMs      = 5 * 60 * 1000;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> saveProducts(List<Map<String, dynamic>> products) async {
    final prefs = await _p;
    await prefs.setString(_productsKey, jsonEncode(products));
    await prefs.setInt(_productsTsKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<Map<String, dynamic>>?> loadProducts() async {
    final prefs = await _p;
    final raw = prefs.getString(_productsKey);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<bool> isProductsCacheFresh() async {
    final prefs = await _p;
    final ts = prefs.getInt(_productsTsKey);
    if (ts == null) return false;
    return DateTime.now().millisecondsSinceEpoch - ts < _maxAgeMs;
  }

  Future<void> clearProducts() async {
    final prefs = await _p;
    await prefs.remove(_productsKey);
    await prefs.remove(_productsTsKey);
  }

  Future<void> saveLastUid(String uid) async {
    final prefs = await _p;
    await prefs.setString('last_uid', uid);
  }

  Future<String?> loadLastUid() async {
    final prefs = await _p;
    return prefs.getString('last_uid');
  }

  Future<void> clearAuth() async {
    final prefs = await _p;
    await prefs.remove('last_uid');
  }
}