import '../../models/trip.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

/// Reads and writes for [Trip], over [ApiService].
///
/// Scoped by the caller's token on the server: a driver's list is their own
/// runs, a parent's is whatever carries their children — see the route
/// handlers in the dashboard's `src/app/api/v1/trips`.
class TripsRepository {
  TripsRepository._();

  static final TripsRepository instance = TripsRepository._();

  final ApiService _api = ApiService.instance;

  Future<List<Trip>> list() async {
    final response = await _api.get(ApiConstants.trips) as List<dynamic>;
    return response.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Trip> getById(String id) async {
    final response =
        await _api.get(ApiConstants.tripById(id)) as Map<String, dynamic>;
    return Trip.fromJson(response);
  }

  /// What `TripPage._toggleTrip` calls. The server checks the transition
  /// against the trip's current status — starting an already-running trip or
  /// ending a scheduled one throws [ApiException] rather than silently
  /// no-opping, so a stale screen finds out rather than lying to the driver.
  Future<Trip> start(String tripId) => _setAction(tripId, 'start');

  Future<Trip> end(String tripId) => _setAction(tripId, 'end');

  Future<Trip> cancel(String tripId) => _setAction(tripId, 'cancel');

  Future<Trip> _setAction(String tripId, String action) async {
    final response = await _api.patch(
      ApiConstants.tripById(tripId),
      body: {'action': action},
    ) as Map<String, dynamic>;
    return Trip.fromJson(response);
  }

  /// One GPS breadcrumb. What the "begin location streaming" TODO on
  /// `TripPage._toggleTrip` becomes once a trip is running — call this on an
  /// interval (a `Timer.periodic` alongside `Geolocator.getPositionStream`,
  /// once a location plugin is added) for as long as the trip is in progress.
  Future<TripLocation> postLocation({
    required String tripId,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _api.post(
      ApiConstants.tripLocation(tripId),
      body: {'latitude': latitude, 'longitude': longitude},
    ) as Map<String, dynamic>;
    return TripLocation.fromJson(response);
  }
}
