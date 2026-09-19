import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static late SharedPreferences _prefs;
  static String serverUrl = 'http://127.0.0.1:4173';
  static String appName = 'Beta';
  static String appVersion = '1.0.0';
  static const int sessionHeartbeatInterval = 10;
  static const int maxFileSize = 50 * 1024 * 1024;
  static const Duration tokenRefreshInterval = Duration(hours: 24);
  static const Duration sessionTimeout = Duration(days: 30);

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final savedUrl = _prefs.getString('server_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      serverUrl = savedUrl;
    }
  }

  static Future<void> setServerUrl(String url) async {
    serverUrl = url;
    await _prefs.setString('server_url', url);
  }

  static String get apiBase => '$serverUrl/api';

  static bool get isSecureContext =>
      serverUrl.startsWith('https://') ||
      serverUrl.contains('localhost') ||
      serverUrl.contains('127.0.0.1');

  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Client': 'ios',
        'X-Client-Version': appVersion,
      };
}
