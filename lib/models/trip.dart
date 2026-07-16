enum TripStatus {
  scheduled,
  inProgress,
  completed,
  cancelled;

  static TripStatus fromString(String? value) => TripStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => TripStatus.scheduled,
      );

  String get label => switch (this) {
        TripStatus.scheduled => 'Scheduled',
        TripStatus.inProgress => 'In progress',
        TripStatus.completed => 'Completed',
        TripStatus.cancelled => 'Cancelled',
      };
}

enum TripDirection { pickup, dropoff }

/// A single GPS breadcrumb along a trip.
class TripLocation {
  const TripLocation({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
  });

  final double latitude;
  final double longitude;
  final DateTime recordedAt;

  factory TripLocation.fromJson(Map<String, dynamic> json) => TripLocation(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        recordedAt: DateTime.parse(json['recordedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'recordedAt': recordedAt.toIso8601String(),
      };
}

class Trip {
  const Trip({
    required this.id,
    required this.driverId,
    required this.vehicleId,
    required this.status,
    required this.direction,
    this.studentIds = const [],
    this.scheduledAt,
    this.startedAt,
    this.endedAt,
    this.lastLocation,
  });

  final String id;
  final String driverId;
  final String vehicleId;
  final TripStatus status;
  final TripDirection direction;
  final List<String> studentIds;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final TripLocation? lastLocation;

  bool get isActive => status == TripStatus.inProgress;

  Duration? get elapsed {
    if (startedAt == null) return null;
    return (endedAt ?? DateTime.now()).difference(startedAt!);
  }

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id'].toString(),
        driverId: json['driverId'].toString(),
        vehicleId: json['vehicleId'].toString(),
        status: TripStatus.fromString(json['status'] as String?),
        direction: json['direction'] == 'dropoff'
            ? TripDirection.dropoff
            : TripDirection.pickup,
        studentIds: (json['studentIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        scheduledAt: _parseDate(json['scheduledAt']),
        startedAt: _parseDate(json['startedAt']),
        endedAt: _parseDate(json['endedAt']),
        lastLocation: json['lastLocation'] == null
            ? null
            : TripLocation.fromJson(
                json['lastLocation'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'driverId': driverId,
        'vehicleId': vehicleId,
        'status': status.name,
        'direction': direction.name,
        'studentIds': studentIds,
        'scheduledAt': scheduledAt?.toIso8601String(),
        'startedAt': startedAt?.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'lastLocation': lastLocation?.toJson(),
      };

  Trip copyWith({
    TripStatus? status,
    DateTime? startedAt,
    DateTime? endedAt,
    TripLocation? lastLocation,
  }) =>
      Trip(
        id: id,
        driverId: driverId,
        vehicleId: vehicleId,
        status: status ?? this.status,
        direction: direction,
        studentIds: studentIds,
        scheduledAt: scheduledAt,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
        lastLocation: lastLocation ?? this.lastLocation,
      );

  static DateTime? _parseDate(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Trip && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
