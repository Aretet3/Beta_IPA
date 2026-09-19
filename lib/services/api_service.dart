import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBase,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: AppConfig.defaultHeaders,
  ));

  final AuthService _auth = AuthService();

  Options get _authOptions => Options(
        headers: _auth.authHeaders,
      );

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/profile', options: _authOptions);
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? username,
    String? bio,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['fullName'] = fullName;
    if (username != null) data['username'] = username;
    if (bio != null) data['bio'] = bio;
    final response =
        await _dio.patch('/profile', data: data, options: _authOptions);
    return _parseResponse(response);
  }

  Future<List<dynamic>> getChats() async {
    final response = await _dio.get('/chats', options: _authOptions);
    final data = _parseResponse(response);
    return data['chats'] ?? [];
  }

  Future<List<dynamic>> getMessages(int chatId,
      {int limit = 50, int? before}) async {
    final params = <String, dynamic>{'chatId': chatId, 'limit': limit};
    if (before != null) params['before'] = before;
    final response = await _dio.get('/messages',
        queryParameters: params, options: _authOptions);
    final data = _parseResponse(response);
    return data['messages'] ?? [];
  }

  Future<Map<String, dynamic>> sendMessage({
    required int chatId,
    required String content,
    int? replyToMessageId,
  }) async {
    final data = <String, dynamic>{
      'chatId': chatId,
      'content': content,
    };
    if (replyToMessageId != null) data['replyToMessageId'] = replyToMessageId;
    final response =
        await _dio.post('/messages', data: data, options: _authOptions);
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> sendAttachment({
    required int chatId,
    required File file,
    required String messageType,
    String? content,
    int? replyToMessageId,
    Function(double)? onProgress,
  }) async {
    final fileName = file.path.split('/').last;
    final bytes = await file.readAsBytes();
    final base64Data = base64Encode(bytes);
    final dataUrl =
        'data:${_getMimeType(fileName)};base64,$base64Data';

    final payload = <String, dynamic>{
      'chatId': chatId,
      'fileName': fileName,
      'dataUrl': dataUrl,
      'messageType': messageType,
      'content': content ?? '',
    };
    if (replyToMessageId != null) payload['replyToMessageId'] = replyToMessageId;

    final response = await _dio.post('/messages/attachment',
        data: payload, options: _authOptions);
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> uploadFile({
    required int chatId,
    required File file,
    String? content,
    int? replyToMessageId,
    Function(double)? onProgress,
  }) async {
    final fileName = file.path.split('/').last;
    final formData = FormData.fromMap({
      'chatId': chatId,
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
      if (content != null) 'content': content,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
    });

    final response = await _dio.post(
      '/messages/file-upload',
      data: formData,
      options: _authOptions,
      onSendProgress: (sent, total) {
        if (onProgress != null && total > 0) {
          onProgress(sent / total);
        }
      },
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> createOrGetDirectChat(int userId) async {
    final response = await _dio.post('/chats/direct',
        data: {'userId': userId}, options: _authOptions);
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> createGroup({
    required String name,
    List<int>? memberIds,
  }) async {
    final response = await _dio.post('/groups', data: {
      'name': name,
      if (memberIds != null) 'memberIds': memberIds,
    }, options: _authOptions);
    return _parseResponse(response);
  }

  Future<List<dynamic>> searchUsers(String query) async {
    final response = await _dio.get('/users',
        queryParameters: {'q': query}, options: _authOptions);
    return _parseResponse(response)['users'] ?? [];
  }

  Future<List<dynamic>> getStories() async {
    final response = await _dio.get('/stories', options: _authOptions);
    return _parseResponse(response)['stories'] ?? [];
  }

  Future<Map<String, dynamic>> getSettings() async {
    final response = await _dio.get('/settings', options: _authOptions);
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) async {
    final response =
        await _dio.patch('/settings', data: settings, options: _authOptions);
    return _parseResponse(response);
  }

  Future<void> sendHeartbeat() async {
    try {
      await _dio.post('/sessions/heartbeat', options: _authOptions);
    } catch (_) {}
  }

  Future<File> downloadAttachment(int attachmentId, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    if (await file.exists()) return file;

    final response = await _dio.download(
      '/attachments/$attachmentId',
      file.path,
      options: _authOptions,
    );
    return file;
  }

  Map<String, dynamic> _parseResponse(Response response) {
    if (response.data is String) {
      return jsonDecode(response.data);
    }
    return response.data;
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    const mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'mp4': 'video/mp4',
      'webm': 'video/webm',
      'mov': 'video/quicktime',
      'mp3': 'audio/mpeg',
      'ogg': 'audio/ogg',
      'wav': 'audio/wav',
      'm4a': 'audio/mp4',
      'pdf': 'application/pdf',
      'zip': 'application/zip',
      'txt': 'text/plain',
    };
    return mimeTypes[ext] ?? 'application/octet-stream';
  }
}
