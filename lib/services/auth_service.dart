import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBase,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: AppConfig.defaultHeaders,
  ));

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  String? _sessionToken;
  String? _accessToken;
  Map<String, dynamic>? _currentUser;

  String? get sessionToken => _sessionToken;
  String? get accessToken => _accessToken;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoggedIn => _sessionToken != null && _accessToken != null;

  Future<bool> tryRestoreSession() async {
    _sessionToken = await _storage.read(key: 'session_token');
    _accessToken = await _storage.read(key: 'access_token');
    final userJson = await _storage.read(key: 'current_user');
    if (userJson != null) {
      _currentUser = jsonDecode(userJson);
    }
    if (_sessionToken == null || _accessToken == null) return false;
    try {
      final response = await _dio.get(
        '/profile',
        options: Options(
          headers: {'Authorization': 'Bearer $_sessionToken'},
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        _currentUser = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        await _storage.write(
          key: 'current_user',
          value: jsonEncode(_currentUser),
        );
        return true;
      }
    } catch (e) {
      await clearSession();
    }
    return false;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/login', data: {
        'email': email,
        'password': password,
      });
      final data = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      if (data['twoFactorRequired'] == true) {
        return {'twoFactorRequired': true, 'tempToken': data['tempToken']};
      }
      await _saveSession(data);
      return data;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      throw Exception(e.message ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> verifyTwoFactor({
    required String tempToken,
    required String code,
  }) async {
    try {
      final response = await _dio.post('/login/2fa', data: {
        'tempToken': tempToken,
        'code': code,
      });
      final data = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      await _saveSession(data);
      return data;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      throw Exception(e.message ?? 'Network error');
    }
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/register', data: {
        'fullName': fullName,
        'username': username,
        'email': email,
        'password': password,
        'terms': true,
      });
      final data = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      await _saveSession(data);
      return data;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      throw Exception(e.message ?? 'Network error');
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(
        '/logout',
        options: Options(
          headers: {'Authorization': 'Bearer $_sessionToken'},
        ),
      );
    } catch (_) {}
    await clearSession();
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    _sessionToken = data['sessionToken'] ?? data['session_token'];
    _accessToken = data['accessToken'] ?? data['access_token'];
    _currentUser = data['user'];
    if (_sessionToken != null) {
      await _storage.write(key: 'session_token', value: _sessionToken);
    }
    if (_accessToken != null) {
      await _storage.write(key: 'access_token', value: _accessToken);
    }
    if (_currentUser != null) {
      await _storage.write(
        key: 'current_user',
        value: jsonEncode(_currentUser),
      );
    }
  }

  Future<void> clearSession() async {
    _sessionToken = null;
    _accessToken = null;
    _currentUser = null;
    await _storage.delete(key: 'session_token');
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'current_user');
  }

  Map<String, String> get authHeaders => {
        if (_sessionToken != null) 'Authorization': 'Bearer $_sessionToken',
        ...AppConfig.defaultHeaders,
      };
}
