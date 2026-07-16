import 'package:flutter/material.dart';

import '../../core/router/app_router.dart';
import '../../shared/widgets/app_logo.dart';
import 'auth_provider.dart';

/// Restores the session, then sends the user to their role's home or to login.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final auth = AuthScope.read(context);
    await auth.bootstrap();
    if (!mounted) return;

    final user = auth.user;
    Navigator.of(context).pushReplacementNamed(
      user == null ? AppRoutes.login : AppRouter.homeFor(user.role),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(size: 88, showTagline: true),
            SizedBox(height: 40),
            SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    );
  }
}
