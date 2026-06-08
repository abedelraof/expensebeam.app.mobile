import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String _baseUrl = 'https://expensebeam.com/api';
  static final _storage = FlutterSecureStorage();

  static Dio get _dio {
    final dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
    return dio;
  }

  static Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  static Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  static Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  static Future<Response> delete(String path) => _dio.delete(path);

  static Future<String?> getToken() => _storage.read(key: 'jwt_token');
  static Future<void> setToken(String token) =>
      _storage.write(key: 'jwt_token', value: token);
  static Future<void> clearToken() => _storage.delete(key: 'jwt_token');
}
