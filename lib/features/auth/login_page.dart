import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/auth_backdrop.dart';
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
  void initState() {
    super.initState();
    // Decides whether the device-unlock button has anything to unlock.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AuthScope.read(context).refreshDeviceLockAvailability();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Shared by password sign-in and device unlock, so both honour the
  /// password-change gate.
  void _goHome(AuthProvider auth) {
    final user = auth.user;
    if (user == null) return;

    final route = AppRouter.destinationFor(user);
    Navigator.of(context).pushReplacementNamed(
      route,
      // `forced`: arriving straight off a sign-in makes that screen
      // undismissable.
      arguments: route == AppRoutes.changePassword ? true : null,
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = AuthScope.read(context);
    final ok = await auth.login(
      email: _email.text.trim(),
      password: _password.text,
    );
    if (!mounted || !ok) return;
    _goHome(auth);
  }

  Future<void> _deviceUnlock() async {
    final auth = AuthScope.read(context);
    final ok = await auth.signInWithDeviceLock();
    if (!mounted || !ok) return;
    _goHome(auth);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          const AuthBackdrop(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _formKey,
                  // Heading high, CTA low, form scrolls between them when the
                  // keyboard opens.
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Align keeps the circle at its own size: a bare
                              // Container is stretched full-width by the Column,
                              // and BoxShape.circle then paints itself centred
                              // inside that box.
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  height: 60,
                                  width: 60,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.directions_bus_rounded,
                                    color: AppColors.onAccent,
                                    size: 32,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 36),

                              Text('Welcome\nback.', style: text.displaySmall),
                              const SizedBox(height: 12),
                              Text(
                                AppStrings.loginSubtitle,
                                style: text.bodyLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 32),

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
                                hint: 'At least 8 characters',
                                obscure: true,
                                prefixIcon: Icons.lock_outline_rounded,
                                textInputAction: TextInputAction.done,
                                validator: Validators.password,
                                enabled: !auth.isBusy,
                                onSubmitted: (_) => _submit(),
                              ),
                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  _RememberMe(
                                    value: auth.rememberMe,
                                    enabled: !auth.isBusy,
                                    onChanged: (v) =>
                                        auth.setRememberMe(value: v),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    // Muted on purpose — the accent stays
                                    // reserved for the primary action.
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.textSecondary,
                                    ),
                                    onPressed: auth.isBusy ? null : () {},
                                    child: const Text(
                                        AppStrings.forgotPassword),
                                  ),
                                ],
                              ),

                              if (auth.error != null) ...[
                                const SizedBox(height: 8),
                                _ErrorBanner(message: auth.error!),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                        child: Column(
                          children: [
                            PrimaryButton(
                              label: AppStrings.signIn,
                              busy: auth.isBusy,
                              onPressed: _submit,
                            ),
                            if (auth.deviceLockAvailable) ...[
                              const SizedBox(height: 14),
                              const _OrDivider(),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.fingerprint_rounded,
                                    size: 22),
                                label: const Text(AppStrings.useDeviceLock),
                                onPressed:
                                    auth.isBusy ? null : _deviceUnlock,
                              ),
                            ],
                            const SizedBox(height: 10),
                            _SignUpPrompt(enabled: !auth.isBusy),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RememberMe extends StatelessWidget {
  const _RememberMe({
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: enabled ? () => onChanged(!value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 20,
              width: 20,
              decoration: BoxDecoration(
                color: value ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value ? AppColors.accent : AppColors.outline,
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: AppColors.onAccent)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              AppStrings.rememberMe,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.outline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.outline)),
      ],
    );
  }
}

class _SignUpPrompt extends StatelessWidget {
  const _SignUpPrompt({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppStrings.noAccount,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed:
              enabled ? () => Navigator.of(context).pushNamed(AppRoutes.signup) : null,
          child: const Text(AppStrings.signUp),
        ),
      ],
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
