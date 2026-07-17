import '../../models/student.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

/// Reads and writes for [Student], over [ApiService].
///
/// Query-string scoping (`parentId`, `tripId`) is a hint, not a security
/// boundary — the backend always re-derives the caller's actual scope from
/// their token. Passing the wrong id here narrows or fails the request; it
/// cannot widen it.
class StudentsRepository {
  StudentsRepository._();

  static final StudentsRepository instance = StudentsRepository._();

  final ApiService _api = ApiService.instance;

  /// The signed-in parent's children, or — for a driver — everyone on the
  /// manifest of the given [tripId].
  Future<List<Student>> list({String? parentId, String? tripId}) async {
    final response = await _api.get(
      ApiConstants.students,
      query: {
        // ignore: use_null_aware_elements — the '?' form for map entries
        // doesn't parse on this SDK; this `if` form is correct and compiles.
        if (parentId != null) 'parentId': parentId,
        if (tripId != null) 'tripId': tripId,
      },
    ) as List<dynamic>;

    return response
        .map((e) => Student.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Student> getById(String id) async {
    final response =
        await _api.get(ApiConstants.studentById(id)) as Map<String, dynamic>;
    return Student.fromJson(response);
  }

  /// What `StudentListPage._cycleStatus` calls when a driver marks a child
  /// onboard, dropped off, or absent.
  ///
  /// [tripId] is required by the endpoint, not optional here: it is the
  /// manifest row that proves this driver actually runs this child today, and
  /// without it the server has nothing to authorize the write against.
  Future<void> updateStatus({
    required String studentId,
    required StudentStatus status,
    required String tripId,
  }) async {
    await _api.patch(
      ApiConstants.studentById(studentId),
      body: {'status': status.name, 'tripId': tripId},
    );
  }
}
