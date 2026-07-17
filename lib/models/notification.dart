/// A single alert — a pickup, a drop-off, a delay, a driver check-in.
///
/// Extracted from `notifications_page.dart`, which held this with no
/// `fromJson` until `GET /notifications` existed to decode.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'].toString(),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        read: json['read'] as bool? ?? false,
      );

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        createdAt: createdAt,
        read: read ?? this.read,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AppNotification && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
