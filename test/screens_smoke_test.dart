import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_run/core/theme/app_theme.dart';
import 'package:school_run/features/auth/auth_provider.dart';
import 'package:school_run/features/auth/login_page.dart';
import 'package:school_run/features/driver/driver_home.dart';
import 'package:school_run/features/driver/student_list_page.dart';
import 'package:school_run/features/driver/trip_page.dart';
import 'package:school_run/features/parent/live_tracking_page.dart';
import 'package:school_run/features/parent/notifications_page.dart';
import 'package:school_run/features/parent/parent_home.dart';
import 'package:school_run/features/profile/profile_page.dart';

/// Pumps every screen at phone size to catch layout overflows and render
/// exceptions. Does not assert on looks — fonts and colours only prove out on
/// a real device.
void main() {
  /// Signs in through the debug fake-auth path so screens have a user.
  Future<Widget> harness(Widget child, {required String email}) async {
    final auth = AuthProvider();
    await auth.login(email: email, password: 'password123');

    return AuthScope(
      notifier: auth,
      child: MaterialApp(theme: AppTheme.dark, home: child),
    );
  }

  setUp(() {
    // Pixel-ish logical size; the default 800x600 is not a phone.
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
        .views.first;
    view.physicalSize = const Size(1080, 2340);
    view.devicePixelRatio = 3.0;
  });

  tearDown(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
        .views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  final driverScreens = <String, Widget>{
    'DriverHome': const DriverHome(),
    'TripPage': const TripPage(),
    'StudentListPage': const StudentListPage(),
  };

  final parentScreens = <String, Widget>{
    'ParentHome': const ParentHome(),
    'LiveTrackingPage': const LiveTrackingPage(studentId: 's-1'),
    'NotificationsPage': const NotificationsPage(),
    'ProfilePage': const ProfilePage(),
  };

  for (final entry in driverScreens.entries) {
    testWidgets('${entry.key} renders without exceptions', (tester) async {
      await tester.pumpWidget(
        await harness(entry.value, email: 'driver@schoolrun.co.zw'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  for (final entry in parentScreens.entries) {
    testWidgets('${entry.key} renders without exceptions', (tester) async {
      await tester.pumpWidget(
        await harness(entry.value, email: 'parent@schoolrun.co.zw'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('LoginPage renders and validates empty input', (tester) async {
    final auth = AuthProvider();
    await tester.pumpWidget(
      AuthScope(
        notifier: auth,
        child: MaterialApp(theme: AppTheme.dark, home: const LoginPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Email is required.'), findsOneWidget);
  });

  testWidgets('fake auth routes driver and parent to different roles',
      (tester) async {
    final driverAuth = AuthProvider();
    await driverAuth.login(email: 'driver@x.com', password: 'password123');
    expect(driverAuth.user?.isDriver, isTrue);

    final parentAuth = AuthProvider();
    await parentAuth.login(email: 'mum@x.com', password: 'password123');
    expect(parentAuth.user?.isParent, isTrue);
  });
}
