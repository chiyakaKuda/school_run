import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'storage_service.dart';

/// Thrown for any non-2xx response or transport failure.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  /// No response at all — no signal, server down, DNS. Distinct from a 4xx,
  /// which means the server answered and said no.
  bool get isOffline => statusCode == null;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin JSON client over the backend.
///
/// [_send] is the only place that touches the network; the verbs below and
/// every caller are built on it.
class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  final StorageService _storage = StorageService.instance;

  /// One client for the app's life, so connections are pooled rather than a
  /// fresh socket per call.
  final http.Client _client = http.Client();

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
    final uri = _uri(path, query);
    final headers = await _headers();
    final encoded = body == null ? null : jsonEncode(body);

    final http.Response response;
    try {
      final request = switch (method) {
        'GET' => _client.get(uri, headers: headers),
        'POST' => _client.post(uri, headers: headers, body: encoded),
        'PUT' => _client.put(uri, headers: headers, body: encoded),
        'PATCH' => _client.patch(uri, headers: headers, body: encoded),
        'DELETE' => _client.delete(uri, headers: headers),
        _ => throw ArgumentError('Unsupported method: $method'),
      };

      // ApiConstants.receiveTimeout, so a stalled connection surfaces as a
      // failure the UI can show rather than a spinner that never stops.
      response = await request.timeout(ApiConstants.receiveTimeout);
    } on TimeoutException {
      _logTransportFailure(method, uri, 'TimeoutException');
      throw const ApiException('The server took too long to answer.');
    } on SocketException catch (e) {
      _logTransportFailure(method, uri, e.toString());
      throw ApiException(_socketMessage(e));
    } on http.ClientException catch (e) {
      _logTransportFailure(method, uri, e.toString());
      throw ApiException(e.message);
    }

    return _decode(response);
  }

  /// Every SocketException reads the same to a user, but the causes are not
  /// interchangeable — and collapsing them into "check your connection" sends
  /// you debugging the network when the app was never allowed onto it.
  String _socketMessage(SocketException e) {
    final errno = e.osError?.errorCode;

    // EACCES. On Android this is almost always a missing INTERNET permission
    // in the *release* manifest: the debug and profile source sets declare it,
    // so this fails only in a built APK and never under `flutter run`.
    if (errno == 13) {
      return 'The app is not permitted to use the network. '
          'This is a build problem, not your connection.';
    }

    // Failed host lookup — DNS. Either genuinely offline, or the base URL's
    // host is wrong or misspelt.
    if (errno == 7 || e.message.contains('Failed host lookup')) {
      return 'Cannot find the server. Check your connection.';
    }

    // ECONNREFUSED — something answered at that address and closed the door.
    // The host resolves, so this is a wrong port or a server that is down.
    if (errno == 111) {
      return 'The server refused the connection.';
    }

    return 'Cannot reach the server. Check your connection.';
  }

  /// Debug-only. The `assert` body is stripped entirely from release builds,
  /// so the real exception is visible while developing without ever leaking
  /// the URL or transport details into a shipped app.
  void _logTransportFailure(String method, Uri uri, String error) {
    assert(() {
      developer.log(
        '$method $uri failed: $error',
        name: 'ApiService',
      );
      return true;
    }());
  }

  dynamic _decode(http.Response response) {
    final status = response.statusCode;

    // 204, or an empty 200 — logout answers this way. There is nothing to
    // decode, and jsonDecode('') would throw.
    if (response.body.isEmpty) {
      if (status >= 200 && status < 300) return null;
      throw ApiException(_statusMessage(status), statusCode: status);
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      // HTML from a proxy or an error page. Don't let a JSON parse error
      // masquerade as the real problem.
      throw ApiException(
        status >= 200 && status < 300
            ? 'The server sent a response the app could not read.'
            : _statusMessage(status),
        statusCode: status,
      );
    }

    if (status >= 200 && status < 300) return decoded;

    // The API puts a human-readable reason in `message`; fall back to the
    // status when it doesn't.
    final message = decoded is Map<String, dynamic> && decoded['message'] is String
        ? decoded['message'] as String
        : _statusMessage(status);

    throw ApiException(message, statusCode: status);
  }

  String _statusMessage(int status) => switch (status) {
        400 => 'The app sent something the server rejected.',
        401 => 'Your session has expired. Sign in again.',
        403 => 'You do not have access to that.',
        404 => 'That is no longer there.',
        >= 500 => 'The server is having trouble. Try again shortly.',
        _ => 'Something went wrong ($status).',
      };
}
