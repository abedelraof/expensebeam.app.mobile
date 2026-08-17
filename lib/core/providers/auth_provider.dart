import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../api/api_client.dart';

class AuthProvider extends ChangeNotifier {
  /// Lets us unwind any pushed sub-screens when the session dies, so the user
  /// lands on the login screen rather than on a stale detail page.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  bool _isAuthenticated = false;
  bool _isChecking = true;
  bool _isLoading = false;
  String? _error;

  AuthProvider() {
    ApiClient.onUnauthorized = _handleUnauthorized;
  }

  bool get isAuthenticated => _isAuthenticated;
  bool get isChecking => _isChecking;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> checkAuth() async {
    final results = await Future.wait([
      ApiClient.getToken(),
      Future.delayed(const Duration(seconds: 2)),
    ]);
    final token = results[0] as String?;
    // A token in storage is not proof of a live session — it may be expired or
    // revoked. Ask the server before letting the user into the app.
    _isAuthenticated = token != null && await _isTokenValid();
    _isChecking = false;
    notifyListeners();
  }

  /// Returns false only when the server explicitly rejects the token. A network
  /// failure is not a rejection — signing the user out for being offline would
  /// lose their session every time they open the app without connectivity.
  Future<bool> _isTokenValid() async {
    try {
      await ApiClient.get('/settings');
      return true;
    } on DioException catch (e) {
      return e.response?.statusCode != 401;
    } catch (_) {
      return true;
    }
  }

  void _handleUnauthorized() {
    if (!_isAuthenticated && !_isChecking) return;
    _isAuthenticated = false;
    _isChecking = false;
    notifyListeners();
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient.post('/auth/login',
          data: {'email': email, 'password': password});
      await ApiClient.setToken(res.data['token']);
      _isAuthenticated = true;
      return true;
    } catch (e) {
      _error = _parseError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signup(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient.post('/auth/signup',
          data: {'email': email, 'password': password});
      await ApiClient.setToken(res.data['token']);
      _isAuthenticated = true;
      return true;
    } catch (e) {
      _error = _parseError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await ApiClient.post('/auth/forgot-password', data: {'email': email});
      return true;
    } catch (e) {
      _error = _parseError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await ApiClient.clearToken();
    _isAuthenticated = false;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    try {
      return e.response?.data['message'] ?? e.toString();
    } catch (_) {
      return e.toString();
    }
  }
}
