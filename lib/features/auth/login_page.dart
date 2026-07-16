import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';
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
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Container(
                    height: 56,
                    width: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: AppColors.onAccent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // The inspo's oversized display heading.
                  Text('Welcome\nback.', style: text.displaySmall),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.loginSubtitle,
                    style: text.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 36),

                  CustomTextField(
                    label: AppStrings.email,
                    controller: _email,
                    hint: 'you@example.com',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: Validators.email,
                    enabled: !auth.isBusy,
                  ),
                  const SizedBox(height: 18),
                  CustomTextField(
                    label: AppStrings.password,
                    controller: _password,
                    obscure: true,
                    prefixIcon: Icons.lock_outline_rounded,
                    textInputAction: TextInputAction.done,
                    validator: Validators.password,
                    enabled: !auth.isBusy,
                    onSubmitted: (_) => _submit(),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: auth.isBusy ? null : () {},
                      child: const Text('Forgot password?'),
                    ),
                  ),

                  if (auth.error != null) ...[
                    const SizedBox(height: 8),
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
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 20, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
