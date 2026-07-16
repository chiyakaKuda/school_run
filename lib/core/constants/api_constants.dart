/// Backend endpoints and network tuning values.
class ApiConstants {
  const ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';

  // Resources
  static const String students = '/students';
  static const String vehicles = '/vehicles';
  static const String trips = '/trips';
  static const String notifications = '/notifications';

  static String tripById(String id) => '$trips/$id';
  static String studentById(String id) => '$students/$id';
  static String vehicleById(String id) => '$vehicles/$id';
}
