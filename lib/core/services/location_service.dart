import 'package:geolocator/geolocator.dart';

/// Why a location stream could not start. The UI maps these to copy, the same
/// pattern as [DeviceAuthResult] for the fingerprint prompt.
enum LocationAccessResult {
  granted,

  /// The OS setting is off — no app can get a fix until the user enables it.
  serviceDisabled,

  /// Asked once and refused; asking again is worth trying.
  denied,

  /// Refused permanently ("Don't ask again") — only Settings can undo this.
  deniedForever,
}

/// Wraps `geolocator`'s permission dance so [TripPage] can ask one question —
/// "can I stream position?" — instead of threading `LocationPermission`
/// through the widget.
class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  Future<LocationAccessResult> requestAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccessResult.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return switch (permission) {
      LocationPermission.whileInUse ||
      LocationPermission.always =>
        LocationAccessResult.granted,
      LocationPermission.deniedForever => LocationAccessResult.deniedForever,
      LocationPermission.denied ||
      LocationPermission.unableToDetermine =>
        LocationAccessResult.denied,
    };
  }

  /// A new [Position] whenever the device moves roughly 15m — that spacing
  /// keeps a bus reporting steadily along its route without flooding
  /// `POST /trips/:id/location` on every metre of GPS jitter while stopped at
  /// a light.
  Stream<Position> watchPosition() => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15,
        ),
      );
}
