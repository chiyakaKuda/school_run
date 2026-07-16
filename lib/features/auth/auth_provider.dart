import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../models/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Auth state for the whole app.
///
/// Exposed through [AuthScope] rather than a package, so nothing extra is
/// needed in `pubspec.yaml`. If you later add `provider` or `riverpod`, this
/// class can be handed to it unchanged — it is a plain [ChangeNotifier].
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? service})
      : _service = service ?? AuthService.instance;

  final AuthService _service;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _error;
  bool _busy = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get isBusy => _busy;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Called once from the splash screen.
  Future<void> bootstrap() async {
    final restored = await _service.restoreSession();
    _user = restored;
    _status =
        restored == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _service.login(email: email, password: password);
      _status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      _error = e.isUnauthorized ? 'Incorrect email or password.' : e.message;
      return false;
    } on UnimplementedError {
      _error = 'Login is not connected to the backend yet.';
      return false;
    } catch (_) {
      _error = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
}

/// Makes an [AuthProvider] available to the subtree and rebuilds dependents
/// when it changes. Read it with `AuthScope.of(context)`.
class AuthScope extends InheritedNotifier<AuthProvider> {
  const AuthScope({
    super.key,
    required AuthProvider super.notifier,
    required super.child,
  });

  static AuthProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope?.notifier != null, 'No AuthScope found above this widget.');
    return scope!.notifier!;
  }

  /// Reads the provider without subscribing to rebuilds — use in callbacks.
  static AuthProvider read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AuthScope>();
    assert(scope?.notifier != null, 'No AuthScope found above this widget.');
    return scope!.notifier!;
  }
}
