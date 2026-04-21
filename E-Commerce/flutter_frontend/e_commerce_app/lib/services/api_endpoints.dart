class ApiEndpoints {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // auth
  static const String profile      = '$baseUrl/auth';

  // products
  static const String products         = '$baseUrl/products';
  static const String categories       = '$baseUrl/products/categories';
  static const String adminAllProducts = '$baseUrl/products/admin/all';
  static String productById(String id) => '$baseUrl/products/$id';

  // order
  static const String orders           = '$baseUrl/orders';
  static String orderById(String id)   => '$baseUrl/orders/$id';
  static String cancelOrder(String id) => '$baseUrl/orders/$id/cancel';

  // cart
  static const String cart     = '$baseUrl/cart';
  static const String cartSync = '$baseUrl/cart/sync';
}
