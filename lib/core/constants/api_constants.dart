/// Backend endpoints and network tuning values.
class ApiConstants {
  const ApiConstants._();

  /// The dashboard hosts the API — one backend for both clients — so this
  /// points at the Next app rather than a service of its own.
  ///
  /// 10.0.2.2 is how the Android emulator reaches the host machine's localhost
  /// (the emulator's own 127.0.0.1 is the emulator). Neither works on a
  /// physical device — pass the machine's LAN address instead:
  ///
  ///   flutter run \
  ///     --dart-define=API_BASE_URL=http://192.168.1.20:3000/api/v1 \
  ///     --dart-define=FAKE_AUTH=false
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  static const String register = '/auth/register';
  static const String changePassword = '/auth/change-password';

  // Resources
  static const String students = '/students';
  static const String vehicles = '/vehicles';
  static const String trips = '/trips';
  static const String notifications = '/notifications';

  static String tripById(String id) => '$trips/$id';
  static String studentById(String id) => '$students/$id';
  static String vehicleById(String id) => '$vehicles/$id';
}
