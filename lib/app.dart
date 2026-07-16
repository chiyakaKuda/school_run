import 'package:flutter/material.dart';

import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_provider.dart';

/// Root widget: owns app-wide state and configures [MaterialApp].
class SchoolRunApp extends StatefulWidget {
  const SchoolRunApp({super.key});

  @override
  State<SchoolRunApp> createState() => _SchoolRunAppState();
}

class _SchoolRunAppState extends State<SchoolRunApp> {
  final AuthProvider _auth = AuthProvider();

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      notifier: _auth,
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
