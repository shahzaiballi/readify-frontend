import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static final ApiClient instance = ApiClient._internal();
  factory ApiClient() => instance;
  ApiClient._internal();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  final _storage = const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  // ── Token Management ──
  Future<void> setTokens({
    required String access,
    required String refresh,
  }) async {
    await _storage.write(key: _accessTokenKey, value: access);
    await _storage.write(key: _refreshTokenKey, value: refresh);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ── Headers ──
  Future<Map<String, String>> get _headers async {
    final token = await getAccessToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ── Token Refresh ──
  Future<bool> _tryRefreshToken() async {
    final refresh = await getRefreshToken();
    if (refresh == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await setTokens(
          access: data['access'],
          refresh: data['refresh'] ?? refresh,
        );
        return true;
      }
    } catch (_) {}

    await clearTokens();
    return false;
  }

  // ── ✅ FILE UPLOAD (FIXED) ──
  Future<http.Response> uploadFile({
    required String endpoint,
    String fieldName = 'file', // ✅ key fix
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
    Map<String, String> fields = const {},
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest('POST', uri);

    // Auth
    final token = await getAccessToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Fields
    request.fields.addAll(fields);

    // File attach
    if (fileBytes != null && fileName != null) {
      debugPrint('🌐 Uploading bytes file: $fileName');
      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName, // ✅ dynamic
          fileBytes,
          filename: fileName,
        ),
      );
    } else if (filePath != null) {
      debugPrint('📱 Uploading file: $filePath');
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName, // ✅ dynamic
          filePath,
        ),
      );
    } else {
      throw Exception('No file provided');
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        return uploadFile(
          endpoint: endpoint,
          fieldName: fieldName,
          filePath: filePath,
          fileBytes: fileBytes,
          fileName: fileName,
          fields: fields,
        );
      }
    }

    return response;
  }

  // ── JSON Request Core ──
  Future<dynamic> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    Future<http.Response> makeRequest() async {
      final headers = await _headers;
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters:
            queryParameters?.map((k, v) => MapEntry(k, v.toString())),
      );

      switch (method) {
        case 'GET':
          return http.get(uri, headers: headers);
        case 'POST':
          return http.post(uri,
              headers: headers, body: jsonEncode(body ?? {}));
        case 'PATCH':
          return http.patch(uri,
              headers: headers, body: jsonEncode(body ?? {}));
        case 'PUT':
          return http.put(uri,
              headers: headers, body: jsonEncode(body ?? {}));
        case 'DELETE':
          return http.delete(uri, headers: headers);
        default:
          throw Exception('Unsupported method');
      }
    }

    var response = await makeRequest();

    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (!refreshed) throw const AuthException('Session expired');
      response = await makeRequest();
    }

    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    final decoded =
        response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    String message = 'Something went wrong';
    if (decoded is Map<String, dynamic>) {
      message =
          decoded['detail'] ?? decoded['error'] ?? decoded['message'] ?? message;
    }

    throw ApiException(message, statusCode: response.statusCode);
  }

  // ── Public Methods ──
  Future<dynamic> get(String endpoint,
          {Map<String, dynamic>? queryParameters}) =>
      _request('GET', endpoint, queryParameters: queryParameters);

  Future<dynamic> post(String endpoint,
          {Map<String, dynamic>? body}) =>
      _request('POST', endpoint, body: body);

  Future<dynamic> patch(String endpoint,
          {Map<String, dynamic>? body}) =>
      _request('PATCH', endpoint, body: body);

  Future<dynamic> put(String endpoint,
          {Map<String, dynamic>? body}) =>
      _request('PUT', endpoint, body: body);

  Future<dynamic> delete(String endpoint) =>
      _request('DELETE', endpoint);
}

// ── Exceptions ──
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  const ApiException(this.message, {required this.statusCode});
  @override
  String toString() => message;
}