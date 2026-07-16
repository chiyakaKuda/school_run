import 'package:flutter/foundation.dart';

import '../../models/user.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';
import 'demo_data.dart';
import 'storage_service.dart';

/// Owns the auth token and the signed-in [User].
///
/// Talks to [ApiService] and persists the result via [StorageService]. UI does
/// not call this directly — it goes through `AuthProvider`.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  /// Accepts any well-formed credentials and returns a [DemoData] user instead
  /// of calling the backend, so the app can be clicked through before
  /// `ApiService._send` exists. Debug builds only — a release build ignores
  /// this and hits the real API.
  ///
  /// Sign in with an address containing "driver" for the driver role; anything
  /// else lands on the parent side.
  ///
  /// Turn it off with: `flutter run --dart-define=FAKE_AUTH=false`
  static const bool _fakeAuthFlag =
      bool.fromEnvironment('FAKE_AUTH', defaultValue: true);

  static bool get fakeAuthEnabled => kDebugMode && _fakeAuthFlag;

  final ApiService _api = ApiService.instance;
  final StorageService _storage = StorageService.instance;

  User? _currentUser;
  User? get currentUser => _currentUser;

  Future<bool> get isSignedIn async =>
      (await _storage.readString(StorageService.keyToken)) != null;

  Future<User> login({
    required String email,
    required String password,
  }) async {
    if (fakeAuthEnabled) return _fakeLogin(email);

    final response = await _api.post(
      ApiConstants.login,
      body: {'email': email, 'password': password},
    ) as Map<String, dynamic>;

    final token = response['token'] as String;
    final user = User.fromJson(response['user'] as Map<String, dynamic>);

    await _storage.writeString(StorageService.keyToken, token);
    await _storage.writeJson(StorageService.keyUser, user.toJson());
    _currentUser = user;

    return user;
  }

  Future<User> _fakeLogin(String email) async {
    // Stand in for network latency so the button's spinner is visible.
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final user = DemoData.userForEmail(email);
    await _storage.writeString(StorageService.keyToken, 'demo-token');
    await _storage.writeJson(StorageService.keyUser, user.toJson());
    _currentUser = user;
    return user;
  }

  /// Restores the session from storage on cold start. Returns `null` when there
  /// is no usable session.
  Future<User?> restoreSession() async {
    final token = await _storage.readString(StorageService.keyToken);
    if (token == null) return null;

    final cached = await _storage.readJson(StorageService.keyUser);
    if (cached != null) {
      _currentUser = User.fromJson(cached);
    }

    // No `/me` round trip to validate a demo token.
    if (fakeAuthEnabled) return _currentUser;

    try {
      final fresh = await _api.get(ApiConstants.me) as Map<String, dynamic>;
      _currentUser = User.fromJson(fresh);
      await _storage.writeJson(StorageService.keyUser, _currentUser!.toJson());
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await logout();
        return null;
      }
      // Offline or server hiccup: fall back to the cached user.
    }

    return _currentUser;
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiConstants.logout);
    } on ApiException {
      // Best effort — clear the local session regardless.
    } on UnimplementedError {
      // Transport not wired yet.
    }
    _currentUser = null;
    await _storage.remove(StorageService.keyToken);
    await _storage.remove(StorageService.keyUser);
  }
}
