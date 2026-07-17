import '../../models/notification.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

/// Reads and writes for [AppNotification], over [ApiService].
class NotificationsRepository {
  NotificationsRepository._();

  static final NotificationsRepository instance = NotificationsRepository._();

  final ApiService _api = ApiService.instance;

  Future<List<AppNotification>> list() async {
    final response = await _api.get(ApiConstants.notifications) as List<dynamic>;
    return response
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(String id, {bool read = true}) async {
    await _api.patch(ApiConstants.notificationById(id), body: {'read': read});
  }
}
