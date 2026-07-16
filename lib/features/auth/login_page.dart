import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/custom_textfield.dart';
import '../../shared/widgets/primary_button.dart';
import '../../utils/validators.dart';
import 'auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = AuthScope.read(context);
    final ok = await auth.login(
      email: _email.text.trim(),
      password: _password.text,
    );
    if (!mounted) return;

    if (ok && auth.user != null) {
      Navigator.of(context)
          .pushReplacementNamed(AppRouter.homeFor(auth.user!.role));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppLogo(size: 72),
                    const SizedBox(height: 32),
                    Text(
                      AppStrings.welcomeBack,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.loginSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 28),
                    CustomTextField(
                      label: AppStrings.email,
                      controller: _email,
                      hint: 'you@example.com',
                      prefixIcon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                      enabled: !auth.isBusy,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: AppStrings.password,
                      controller: _password,
                      obscure: true,
                      prefixIcon: Icons.lock_outline,
                      textInputAction: TextInputAction.done,
                      validator: Validators.password,
                      enabled: !auth.isBusy,
                      onSubmitted: (_) => _submit(),
                    ),
                    if (auth.error != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(message: auth.error!),
                    ],
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: AppStrings.login,
                      busy: auth.isBusy,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 20, color: colors.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
