import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  Future<String?> _getToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>> _headers({bool requireAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept':       'application/json',
    };
    if (requireAuth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  dynamic _parse(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw ApiException(
      response.statusCode,
      body['message'] ?? 'Request failed',
    );
  }

  Future<dynamic> get(String url, {bool requireAuth = true}) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: await _headers(requireAuth: requireAuth),
      );
      return _parse(response);
    } on SocketException {
      throw ApiException(0, 'No internet connection. Check your network.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Unexpected error: $e');
    }
  }

  Future<dynamic> post(
      String url,
      Map<String, dynamic> body, {
        bool requireAuth = true,
      }) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: await _headers(requireAuth: requireAuth),
        body: jsonEncode(body),
      );
      return _parse(response);
    } on SocketException {
      throw ApiException(0, 'No internet connection. Check your network.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Unexpected error: $e');
    }
  }

  Future<dynamic> patch(
      String url, {
        Map<String, dynamic>? body,
        bool requireAuth = true,
      }) async {
    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: await _headers(requireAuth: requireAuth),
        body: body != null ? jsonEncode(body) : null,
      );
      return _parse(response);
    } on SocketException {
      throw ApiException(0, 'No internet connection. Check your network.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Unexpected error: $e');
    }
  }

  Future<dynamic> delete(String url, {bool requireAuth = true}) async {
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: await _headers(requireAuth: requireAuth),
      );
      return _parse(response);
    } on SocketException {
      throw ApiException(0, 'No internet connection. Check your network.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(0, 'Unexpected error: $e');
    }
  }
}
