import 'package:flutter/material.dart';
import '../api/api_client.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> checkAuth() async {
    final token = await ApiClient.getToken();
    _isAuthenticated = token != null;
    notifyListeners();
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
