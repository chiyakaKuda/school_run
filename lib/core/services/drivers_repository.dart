import '../../models/driver_profile.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

/// Reads for the driver-facing side of a [DriverProfile], over [ApiService].
///
/// What resolves "who is driving" on the parent screens — `parent_home.dart`'s
/// driver strip and `live_tracking_page.dart`'s contact sheet both used to
/// hardcode `DemoData.driver` regardless of whose trip was actually showing.
class DriversRepository {
  DriversRepository._();

  static final DriversRepository instance = DriversRepository._();

  final ApiService _api = ApiService.instance;

  Future<DriverProfile> getById(String id) async {
    final response =
        await _api.get(ApiConstants.driverById(id)) as Map<String, dynamic>;
    return DriverProfile.fromJson(response);
  }
}
