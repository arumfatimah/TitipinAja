
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Alamat API Laravel
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // Token login
  static String? token;

  // Data pengguna yang sedang login
  static Map<String, dynamic>? user;

  // Header request API
  static Map<String, String> get headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // REGISTER
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'role': role,
      }),
    );

    final result = _handleResponse(response);
    _saveLoginData(result);
    return result;
  }

  // LOGIN
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final result = _handleResponse(response);
    _saveLoginData(result);
    return result;
  }

  // SIMPAN TOKEN DAN DATA USER
  static void _saveLoginData(Map<String, dynamic> result) {
    final data = result['data'];

    if (data is Map<String, dynamic>) {
      token = data['token']?.toString();

      if (data['user'] is Map<String, dynamic>) {
        user = Map<String, dynamic>.from(data['user']);
      }
    }
  }

  // LOGOUT
  static Future<void> logout() async {
    if (token != null) {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: headers,
      );

      _handleResponse(response);
    }

    token = null;
    user = null;
  }

  // AMBIL DATA TEMPAT PENYIMPANAN
  static Future<Map<String, dynamic>> getStoragePlaces() async {
    final response = await http.get(
      Uri.parse('$baseUrl/storage-places'),
      headers: headers,
    );

    return _handleResponse(response);
  }

  // AMBIL DATA SLOT PENYIMPANAN
  static Future<Map<String, dynamic>> getStorageSlots() async {
    final response = await http.get(
      Uri.parse('$baseUrl/storage-slots'),
      headers: headers,
    );

    return _handleResponse(response);
  }

  // PERIKSA RESPONS LARAVEL
  static Map<String, dynamic> _handleResponse(
      http.Response response) {
    final decoded = jsonDecode(response.body);

    final data = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    final message = data['message'] ??
        'Terjadi kesalahan pada server.';

    throw Exception(message);
  }
}
