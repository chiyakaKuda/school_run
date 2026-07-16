class Vehicle {
  const Vehicle({
    required this.id,
    required this.plateNumber,
    required this.capacity,
    this.model,
    this.colour,
    this.driverId,
  });

  final String id;
  final String plateNumber;
  final int capacity;
  final String? model;
  final String? colour;
  final String? driverId;

  String get displayName =>
      model == null ? plateNumber : '$model • $plateNumber';

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'].toString(),
        plateNumber: json['plateNumber'] as String? ?? '',
        capacity: (json['capacity'] as num?)?.toInt() ?? 0,
        model: json['model'] as String?,
        colour: json['colour'] as String?,
        driverId: json['driverId']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'plateNumber': plateNumber,
        'capacity': capacity,
        'model': model,
        'colour': colour,
        'driverId': driverId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Vehicle && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
