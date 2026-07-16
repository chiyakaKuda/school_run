import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Key-value persistence for tokens and cached user data.
///
/// Backed by `shared_preferences`, so values survive a restart. Note that this
/// is plain-text storage: fine for the cached user and the "remember me" flag,
/// but a production auth token belongs in `flutter_secure_storage` (Keystore /
/// Keychain) instead.
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const String keyToken = 'auth_token';
  static const String keyUser = 'auth_user';
  static const String keyRememberMe = 'remember_me';
  static const String keyOnboarded = 'onboarded';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _box async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<String?> readString(String key) async => (await _box).getString(key);

  Future<void> writeString(String key, String value) async =>
      (await _box).setString(key, value);

  Future<Map<String, dynamic>?> readJson(String key) async {
    final raw = (await _box).getString(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> writeJson(String key, Map<String, dynamic> value) async =>
      (await _box).setString(key, jsonEncode(value));

  Future<bool> readBool(String key, {bool defaultValue = false}) async =>
      (await _box).getBool(key) ?? defaultValue;

  Future<void> writeBool(String key, {required bool value}) async =>
      (await _box).setBool(key, value);

  Future<void> remove(String key) async => (await _box).remove(key);

  Future<void> clear() async => (await _box).clear();
}
