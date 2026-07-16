import '../../models/student.dart';
import '../../models/trip.dart';
import '../../models/user.dart';
import '../../models/vehicle.dart';

/// Hardcoded fixtures used while there is no backend.
///
/// Debug builds only — [AuthService] gates every read of this behind
/// `kDebugMode`. Delete this file once `ApiService._send` is wired up.
class DemoData {
  const DemoData._();

  static const User driver = User(
    id: 'u-driver-1',
    name: 'Tendai Mukamuri',
    email: 'driver@schoolrun.co.zw',
    role: UserRole.driver,
    phone: '+263 77 412 8890',
  );

  static const User parent = User(
    id: 'u-parent-1',
    name: 'Rutendo Chikafu',
    email: 'parent@schoolrun.co.zw',
    role: UserRole.parent,
    phone: '+263 71 205 3317',
  );

  /// Any email containing "driver" signs in as the driver; anything else is a
  /// parent. Lets you check both roles without a backend.
  static User userForEmail(String email) =>
      email.toLowerCase().contains('driver') ? driver : parent;

  static const Vehicle vehicle = Vehicle(
    id: 'v-1',
    plateNumber: 'AEZ 4821',
    capacity: 14,
    model: 'Toyota Hiace',
    colour: 'White',
    driverId: 'u-driver-1',
  );

  static final List<Student> students = [
    const Student(
      id: 's-1',
      name: 'Tanaka Moyo',
      grade: 'Grade 3',
      parentId: 'u-parent-1',
      school: 'Hillside Primary',
      pickupAddress: '14 Josiah Chinamano Rd',
      status: StudentStatus.onboard,
    ),
    const Student(
      id: 's-2',
      name: 'Rufaro Ncube',
      grade: 'Grade 1',
      parentId: 'u-parent-1',
      school: 'Hillside Primary',
      pickupAddress: '14 Josiah Chinamano Rd',
      status: StudentStatus.waiting,
    ),
    const Student(
      id: 's-3',
      name: 'Anesu Dube',
      grade: 'Grade 5',
      parentId: 'u-parent-2',
      school: 'Hillside Primary',
      pickupAddress: '8 Fife Ave',
      status: StudentStatus.onboard,
    ),
    const Student(
      id: 's-4',
      name: 'Chipo Marufu',
      grade: 'Grade 2',
      parentId: 'u-parent-3',
      school: 'Hillside Primary',
      pickupAddress: '31 Samora Machel Ave',
      status: StudentStatus.droppedOff,
    ),
    const Student(
      id: 's-5',
      name: 'Farai Sibanda',
      grade: 'Grade 6',
      parentId: 'u-parent-4',
      school: 'Hillside Primary',
      pickupAddress: '2 Enterprise Rd',
      status: StudentStatus.absent,
    ),
  ];

  /// The parent fixture's own children.
  static List<Student> get myChildren =>
      students.where((s) => s.parentId == parent.id).toList();

  static List<Trip> get trips => [
        Trip(
          id: 't-1',
          driverId: driver.id,
          vehicleId: vehicle.id,
          status: TripStatus.inProgress,
          direction: TripDirection.pickup,
          studentIds: students.map((s) => s.id).toList(),
          scheduledAt: _at(6, 30),
          startedAt: DateTime.now().subtract(const Duration(minutes: 18)),
          lastLocation: TripLocation(
            latitude: -17.8216,
            longitude: 31.0492,
            recordedAt: DateTime.now().subtract(const Duration(seconds: 40)),
          ),
        ),
        Trip(
          id: 't-2',
          driverId: driver.id,
          vehicleId: vehicle.id,
          status: TripStatus.scheduled,
          direction: TripDirection.dropoff,
          studentIds: students.take(4).map((s) => s.id).toList(),
          scheduledAt: _at(13, 15),
        ),
        Trip(
          id: 't-3',
          driverId: driver.id,
          vehicleId: vehicle.id,
          status: TripStatus.scheduled,
          direction: TripDirection.dropoff,
          studentIds: students.take(2).map((s) => s.id).toList(),
          scheduledAt: _at(16, 45),
        ),
      ];

  static Student? studentById(String? id) {
    if (id == null) return null;
    for (final s in students) {
      if (s.id == id) return s;
    }
    return null;
  }

  static DateTime _at(int hour, int minute) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}
