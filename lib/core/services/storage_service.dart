import 'dart:convert';

/// Key-value persistence for tokens and cached user data.
///
/// The current implementation is in-memory only, so values are lost when the
/// app restarts. Swap `_box` for `shared_preferences` (or
/// `flutter_secure_storage` for the auth token) once the package is added —
/// every method here already returns a `Future`, so callers won't change.
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const String keyToken = 'auth_token';
  static const String keyUser = 'auth_user';
  static const String keyOnboarded = 'onboarded';

  final Map<String, String> _box = <String, String>{};

  Future<String?> readString(String key) async => _box[key];

  Future<void> writeString(String key, String value) async {
    _box[key] = value;
  }

  Future<Map<String, dynamic>?> readJson(String key) async {
    final raw = _box[key];
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> writeJson(String key, Map<String, dynamic> value) async {
    _box[key] = jsonEncode(value);
  }

  Future<bool> readBool(String key, {bool defaultValue = false}) async =>
      _box[key] == null ? defaultValue : _box[key] == 'true';

  Future<void> writeBool(String key, {required bool value}) async {
    _box[key] = value.toString();
  }

  Future<void> remove(String key) async {
    _box.remove(key);
  }

  Future<void> clear() async {
    _box.clear();
  }
}
