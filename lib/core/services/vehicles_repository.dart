import '../../models/vehicle.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

/// Reads for [Vehicle], over [ApiService].
class VehiclesRepository {
  VehiclesRepository._();

  static final VehiclesRepository instance = VehiclesRepository._();

  final ApiService _api = ApiService.instance;

  /// A driver's own vehicle is index 0 of their (single-item) fleet list —
  /// there is no `/vehicles/me`, and a driver only ever runs one vehicle in
  /// this schema.
  Future<List<Vehicle>> list() async {
    final response = await _api.get(ApiConstants.vehicles) as List<dynamic>;
    return response
        .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Vehicle> getById(String id) async {
    final response =
        await _api.get(ApiConstants.vehicleById(id)) as Map<String, dynamic>;
    return Vehicle.fromJson(response);
  }
}
