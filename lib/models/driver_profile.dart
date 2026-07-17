/// The minimal, public view of a driver — what `GET /drivers/:id` returns.
///
/// Deliberately not a [User]: that carries an email and a role, and a parent
/// asking "who is driving my child" has no business learning the driver's
/// login address. This is the whole answer the endpoint is willing to give.
class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.name,
    this.phone,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String? phone;
  final String? photoUrl;

  factory DriverProfile.fromJson(Map<String, dynamic> json) => DriverProfile(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String?,
        photoUrl: json['photoUrl'] as String?,
      );
}
