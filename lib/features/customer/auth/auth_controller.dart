import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';

enum AuthStatus { splash, unauthenticated, authenticated }

class AuthController extends ChangeNotifier {
  AuthController({required AuthService authService})
    : _authService = authService;

  final AuthService _authService;

  AuthStatus _status = AuthStatus.splash;
  bool _busy = false;
  Object? _bootError;

  AuthStatus get status => _status;
  bool get isBusy => _busy;
  Object? get bootError => _bootError;

  Future<void> boot() async {
    _setBusy(true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final token = await _authService.getStoredToken();
      _status = (token != null && token.isNotEmpty)
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
      _bootError = null;
    } catch (e) {
      _bootError = e;
      _status = AuthStatus.unauthenticated;
    } finally {
      _setBusy(false);
    }
  }

  void setBootError(Object error) {
    _bootError = error;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<String?> login({required String phone, required String otp}) async {
    if (_busy) return 'Please wait…';

    _setBusy(true);
    try {
      await _authService.login(phone: phone, otp: otp, role: 'customer');
      _status = AuthStatus.authenticated;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Login failed';
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout() async {
    if (_busy) return;
    _setBusy(true);
    try {
      try {
        await _authService.logout();
      } catch (e) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        rethrow;
      }

      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool value) {
    if (_busy == value) return;
    _busy = value;
    notifyListeners();
  }
}
