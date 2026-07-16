import 'package:flutter/material.dart';

import '../../features/auth/login_page.dart';
import '../../features/auth/signup_page.dart';
import '../../features/auth/splash_page.dart';
import '../../features/driver/driver_home.dart';
import '../../features/driver/student_list_page.dart';
import '../../features/driver/trip_page.dart';
import '../../features/parent/live_tracking_page.dart';
import '../../features/parent/notifications_page.dart';
import '../../features/parent/parent_home.dart';
import '../../features/profile/profile_page.dart';
import '../../models/user.dart';

class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String driverHome = '/driver';
  static const String trip = '/driver/trip';
  static const String studentList = '/driver/students';
  static const String parentHome = '/parent';
  static const String liveTracking = '/parent/tracking';
  static const String notifications = '/parent/notifications';
  static const String profile = '/profile';
}

/// Named-route table driven by [Navigator]. Swap for `go_router` later if you
/// need deep links or nested shells — the route name constants stay valid.
class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      AppRoutes.splash => _page(const SplashPage(), settings),
      AppRoutes.login => _page(const LoginPage(), settings),
      AppRoutes.signup => _page(const SignupPage(), settings),
      AppRoutes.driverHome => _page(const DriverHome(), settings),
      AppRoutes.trip => _page(
          TripPage(tripId: settings.arguments as String?),
          settings,
        ),
      AppRoutes.studentList => _page(
          StudentListPage(tripId: settings.arguments as String?),
          settings,
        ),
      AppRoutes.parentHome => _page(const ParentHome(), settings),
      AppRoutes.liveTracking => _page(
          LiveTrackingPage(studentId: settings.arguments as String?),
          settings,
        ),
      AppRoutes.notifications => _page(const NotificationsPage(), settings),
      AppRoutes.profile => _page(const ProfilePage(), settings),
      _ => _page(_UnknownRoute(name: settings.name), settings),
    };
  }

  /// Where a user lands after signing in.
  static String homeFor(UserRole role) => switch (role) {
        UserRole.driver => AppRoutes.driverHome,
        UserRole.parent || UserRole.admin => AppRoutes.parentHome,
      };

  static MaterialPageRoute<dynamic> _page(Widget child, RouteSettings settings) =>
      MaterialPageRoute<dynamic>(builder: (_) => child, settings: settings);
}

class _UnknownRoute extends StatelessWidget {
  const _UnknownRoute({this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text('No route defined for "$name".')),
    );
  }
}
