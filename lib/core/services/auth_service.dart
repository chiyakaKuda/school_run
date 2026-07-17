import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import '../../models/user.dart';
import '../constants/api_constants.dart';
import '../constants/app_strings.dart';
import 'api_service.dart';
import 'demo_data.dart';
import 'storage_service.dart';

/// Why a device-unlock sign-in could not proceed. The UI maps these to copy.
enum DeviceAuthResult {
  success,

  /// The user dismissed the prompt, or failed the challenge.
  cancelled,

  /// The phone has no PIN/pattern/password or biometrics configured.
  noCredentialsSet,

  /// Nothing to unlock — nobody has signed in with a password on this device.
  noSavedSession,

  /// Hardware missing, locked out, or any other platform failure.
  unavailable,
}

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
  final LocalAuthentication _deviceAuth = LocalAuthentication();

  User? _currentUser;
  User? get currentUser => _currentUser;

  Future<bool> get isSignedIn async =>
      (await _storage.readString(StorageService.keyToken)) != null;

  Future<bool> get rememberMe async =>
      _storage.readBool(StorageService.keyRememberMe);

  // ---------------------------------------------------------------- password

  Future<User> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    final user = fakeAuthEnabled
        ? await _fakeLogin(email)
        : await _realLogin(email: email, password: password);

    await _storage.writeBool(StorageService.keyRememberMe, value: rememberMe);
    return user;
  }

  Future<User> _realLogin({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      ApiConstants.login,
      body: {'email': email, 'password': password},
    ) as Map<String, dynamic>;

    final token = response['token'] as String;
    final user = User.fromJson(response['user'] as Map<String, dynamic>);

    await _persist(token: token, user: user);
    return user;
  }

  Future<User> _fakeLogin(String email) async {
    // Stand in for network latency so the button's spinner is visible.
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final user = DemoData.userForEmail(email);
    await _persist(token: 'demo-token', user: user);
    return user;
  }

  Future<void> _persist({required String token, required User user}) async {
    await _storage.writeString(StorageService.keyToken, token);
    await _storage.writeJson(StorageService.keyUser, user.toJson());
    _currentUser = user;
  }

  /// Replaces the signed-in user's password.
  ///
  /// The first thing a provisioned driver or parent does: their account was
  /// created with the school's default and [User.mustChangePassword] is set
  /// until this succeeds.
  ///
  /// The server returns a fresh token and clears the flag server-side; both are
  /// mirrored locally so the app doesn't keep asking.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (fakeAuthEnabled) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      final user = _currentUser;
      if (user != null) {
        _currentUser = user.copyWith(mustChangePassword: false);
        await _storage.writeJson(StorageService.keyUser, _currentUser!.toJson());
      }
      return;
    }

    final response = await _api.post(
      ApiConstants.changePassword,
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    ) as Map<String, dynamic>;

    final user = _currentUser;
    if (user != null) {
      await _persist(
        token: response['token'] as String,
        user: user.copyWith(mustChangePassword: false),
      );
    }
  }

  // ------------------------------------------------------------ device lock

  /// Whether the phone can do biometrics or fall back to PIN/pattern/password.
  Future<bool> canUseDeviceAuth() async {
    try {
      return await _deviceAuth.isDeviceSupported();
    } on Exception {
      return false;
    }
  }

  /// True once someone has signed in with a password and asked to be
  /// remembered — device unlock has nothing to restore before that.
  Future<bool> hasUnlockableSession() async {
    if (!await rememberMe) return false;
    return (await _storage.readString(StorageService.keyToken)) != null;
  }

  /// Prompts for fingerprint / face, falling back to the device PIN, pattern or
  /// password, then restores the remembered session.
  ///
  /// This unlocks a session that already exists on the device; it is not a
  /// credential in its own right, so [hasUnlockableSession] must be true first.
  Future<DeviceAuthResult> signInWithDeviceLock() async {
    if (!await hasUnlockableSession()) return DeviceAuthResult.noSavedSession;

    final bool passed;
    try {
      passed = await _deviceAuth.authenticate(
        localizedReason: AppStrings.unlockReason,
        // false so the system offers PIN / pattern / password as well as
        // biometrics — the user asked for any device lock, not fingerprint only.
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout =>
          DeviceAuthResult.cancelled,
        LocalAuthExceptionCode.noCredentialsSet =>
          DeviceAuthResult.noCredentialsSet,
        // The enum is explicitly open to new values — always keep a fallback.
        _ => DeviceAuthResult.unavailable,
      };
    } on Exception {
      return DeviceAuthResult.unavailable;
    }

    if (!passed) return DeviceAuthResult.cancelled;

    final cached = await _storage.readJson(StorageService.keyUser);
    if (cached == null) return DeviceAuthResult.noSavedSession;

    _currentUser = User.fromJson(cached);
    return DeviceAuthResult.success;
  }

  // ---------------------------------------------------------------- session

  /// Restores the session from storage on cold start. Returns `null` when there
  /// is no usable session.
  Future<User?> restoreSession() async {
    // Not remembered: force a fresh sign-in even though the token is still on
    // disk, so device unlock can still reach it.
    if (!await rememberMe) return null;

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

  Future<User> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (fakeAuthEnabled) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      final user = User(
        id: 'u-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        role: UserRole.parent,
        phone: phone,
      );
      await _persist(token: 'demo-token', user: user);
      await _storage.writeBool(StorageService.keyRememberMe, value: true);
      return user;
    }

    // TODO: no /auth/register endpoint is defined in ApiConstants yet.
    throw UnimplementedError('Registration is not wired to the backend.');
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
    await _storage.writeBool(StorageService.keyRememberMe, value: false);
  }
}
