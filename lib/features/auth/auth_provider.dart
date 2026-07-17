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
  bool _rememberMe = true;
  bool _deviceLockAvailable = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get isBusy => _busy;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get rememberMe => _rememberMe;

  /// True only when the phone supports a lock *and* there is a remembered
  /// session to unlock. The device-unlock button hides otherwise, since it
  /// would have nothing to restore.
  bool get deviceLockAvailable => _deviceLockAvailable;

  void setRememberMe({required bool value}) {
    _rememberMe = value;
    notifyListeners();
  }

  /// Called once from the splash screen.
  Future<void> bootstrap() async {
    final restored = await _service.restoreSession();
    _user = restored;
    _status =
        restored == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    await refreshDeviceLockAvailability();
    notifyListeners();
  }

  Future<void> refreshDeviceLockAvailability() async {
    _deviceLockAvailable = await _service.canUseDeviceAuth() &&
        await _service.hasUnlockableSession();
    notifyListeners();
  }

  /// Re-reads the user the service holds.
  ///
  /// Needed after a password change: that clears [User.mustChangePassword] on
  /// the service's copy, and without this the provider would keep handing back
  /// the stale one — routing the user to the change screen forever.
  void syncUser() {
    _user = _service.currentUser;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    return _run(() => _service.login(
          email: email,
          password: password,
          rememberMe: _rememberMe,
        ));
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    return _run(() => _service.register(
          name: name,
          email: email,
          phone: phone,
          password: password,
        ));
  }

  /// Fingerprint / face, falling back to the device PIN, pattern or password.
  Future<bool> signInWithDeviceLock() async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.signInWithDeviceLock();
      if (result == DeviceAuthResult.success) {
        _user = _service.currentUser;
        _status = AuthStatus.authenticated;
        return true;
      }

      _error = switch (result) {
        // Dismissing the prompt is a deliberate choice, not an error to shout
        // about.
        DeviceAuthResult.cancelled => null,
        DeviceAuthResult.noCredentialsSet =>
          'Set a screen lock on your phone to use this.',
        DeviceAuthResult.noSavedSession =>
          'Sign in with your password once first.',
        DeviceAuthResult.unavailable =>
          'Device unlock is unavailable right now.',
        DeviceAuthResult.success => null,
      };
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> _run(Future<User> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      _user = await action();
      _status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      _error = e.isUnauthorized ? 'Incorrect email or password.' : e.message;
      return false;
    } on UnimplementedError {
      _error = 'This is not connected to the backend yet.';
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
    await refreshDeviceLockAvailability();
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
