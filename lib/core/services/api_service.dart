import '../constants/api_constants.dart';
import 'storage_service.dart';

/// Thrown for any non-2xx response or transport failure.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin JSON client over the backend.
///
/// [_send] is the only place that touches the network. It is unimplemented
/// because no HTTP package is in `pubspec.yaml` yet — add `http` or `dio` and
/// fill in that one method; the verbs below and every caller stay as they are.
class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  final StorageService _storage = StorageService.instance;

  Future<Map<String, String>> _headers() async {
    final token = await _storage.readString(StorageService.keyToken);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConstants.baseUrl}$path')
          .replace(queryParameters: query?.isEmpty ?? true ? null : query);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    // ignore: unused_local_variable
    final uri = _uri(path, query);
    // ignore: unused_local_variable
    final headers = await _headers();

    throw UnimplementedError(
      'ApiService._send is not wired up. Add an HTTP package to pubspec.yaml, '
      'then issue the $method request here, decode the JSON body, and throw '
      'ApiException for non-2xx responses.',
    );
  }
}
