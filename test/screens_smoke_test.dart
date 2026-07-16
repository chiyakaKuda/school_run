import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:school_run/core/constants/app_strings.dart';
import 'package:school_run/core/theme/app_theme.dart';
import 'package:school_run/features/auth/auth_provider.dart';
import 'package:school_run/features/auth/login_page.dart';
import 'package:school_run/features/driver/driver_home.dart';
import 'package:school_run/features/driver/student_list_page.dart';
import 'package:school_run/features/driver/trip_page.dart';
import 'package:school_run/features/parent/live_tracking_page.dart';
import 'package:school_run/features/parent/notifications_page.dart';
import 'package:school_run/features/auth/signup_page.dart';
import 'package:school_run/features/parent/parent_home.dart';
import 'package:school_run/features/profile/profile_page.dart';

/// Pumps every screen at phone size to catch layout overflows and render
/// exceptions. Does not assert on looks — fonts and colours only prove out on
/// a real device.
void main() {
  // Without this, text is measured in the test framework's fallback font, whose
  // glyphs are all square em boxes — far wider than real Outfit/Inter. That
  // reports overflows on rows that fit perfectly on a device.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final (family, path) in const [
      ('Outfit', 'assets/fonts/Outfit-Variable.ttf'),
      ('Inter', 'assets/fonts/Inter-Variable.ttf'),
    ]) {
      final loader = FontLoader(family)..addFont(rootBundle.load(path));
      await loader.load();
    }
  });

  // StorageService talks to shared_preferences, which has no platform side in a
  // test. local_auth needs no stub: its MissingPluginException is an Exception,
  // which AuthService.canUseDeviceAuth already catches and reports as
  // unavailable — so the device-unlock button simply stays hidden here.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Signs in via the debug fake-auth path, then pumps [child] with the
  /// resulting user in scope.
  ///
  /// The login runs inside [WidgetTester.runAsync] because `_fakeLogin` waits
  /// on a real `Future.delayed`, and testWidgets' fake clock would never let it
  /// complete.
  Future<void> pumpScreen(
    WidgetTester tester,
    Widget child, {
    required String email,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final auth = AuthProvider();
    await tester.runAsync(
      () => auth.login(email: email, password: 'password123'),
    );

    await tester.pumpWidget(
      AuthScope(
        notifier: auth,
        child: MaterialApp(theme: AppTheme.dark, home: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  const driverEmail = 'driver@schoolrun.co.zw';
  const parentEmail = 'parent@schoolrun.co.zw';

  final screens = <String, (Widget, String)>{
    'DriverHome': (const DriverHome(), driverEmail),
    'TripPage': (const TripPage(), driverEmail),
    'StudentListPage': (const StudentListPage(), driverEmail),
    'ParentHome': (const ParentHome(), parentEmail),
    'LiveTrackingPage': (const LiveTrackingPage(studentId: 's-1'), parentEmail),
    'NotificationsPage': (const NotificationsPage(), parentEmail),
    'ProfilePage': (const ProfilePage(), parentEmail),
  };

  for (final entry in screens.entries) {
    testWidgets(
      '${entry.key} renders without exceptions',
      (tester) async {
        await pumpScreen(tester, entry.value.$1, email: entry.value.$2);
        expect(tester.takeException(), isNull);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  }

  testWidgets(
    'LoginPage renders and validates empty input',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        AuthScope(
          notifier: AuthProvider(),
          child: MaterialApp(theme: AppTheme.dark, home: const LoginPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(AppStrings.signIn));
      await tester.pumpAndSettle();
      expect(find.text('Email is required.'), findsOneWidget);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  testWidgets(
    'SignupPage renders and validates mismatched passwords',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        AuthScope(
          notifier: AuthProvider(),
          child: MaterialApp(theme: AppTheme.dark, home: const SignupPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'At least 8 characters'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Repeat your password'),
        'different456',
      );
      await tester.tap(find.text(AppStrings.signUp).last);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  // Plain `test`, not `testWidgets`: no widgets involved, and the real
  // Future.delayed in _fakeLogin needs a real clock.
  test(
    'fake auth routes driver and parent to different roles',
    () async {
      final driverAuth = AuthProvider();
      await driverAuth.login(email: driverEmail, password: 'password123');
      expect(driverAuth.user?.isDriver, isTrue);

      final parentAuth = AuthProvider();
      await parentAuth.login(email: parentEmail, password: 'password123');
      expect(parentAuth.user?.isParent, isTrue);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
