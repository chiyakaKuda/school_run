import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/auth_backdrop.dart';
import '../../shared/widgets/custom_textfield.dart';
import '../../shared/widgets/primary_button.dart';
import '../../utils/validators.dart';
import 'auth_provider.dart';

/// Registration. Accounts created here are parents — drivers are provisioned by
/// the school, not self-signup.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = AuthScope.read(context);
    final ok = await auth.register(
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      password: _password.text,
    );
    if (!mounted || !ok || auth.user == null) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.homeFor(auth.user!.role),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          const AuthBackdrop(intensity: 0.7),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 0, 0),
                          child: IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Create\naccount.',
                                  style: text.displaySmall),
                              const SizedBox(height: 12),
                              Text(
                                AppStrings.signUpSubtitle,
                                style: text.bodyLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 32),

                              CustomTextField(
                                label: AppStrings.fullName,
                                controller: _name,
                                hint: 'Rutendo Chikafu',
                                prefixIcon: Icons.person_outline_rounded,
                                textInputAction: TextInputAction.next,
                                validator: (v) => Validators.required(
                                  v,
                                  field: AppStrings.fullName,
                                ),
                                enabled: !auth.isBusy,
                              ),
                              const SizedBox(height: 18),
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
                                label: AppStrings.phone,
                                controller: _phone,
                                hint: '+263 77 000 0000',
                                prefixIcon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                validator: Validators.phone,
                                enabled: !auth.isBusy,
                              ),
                              const SizedBox(height: 18),
                              CustomTextField(
                                label: AppStrings.password,
                                controller: _password,
                                hint: 'At least 8 characters',
                                obscure: true,
                                prefixIcon: Icons.lock_outline_rounded,
                                textInputAction: TextInputAction.next,
                                validator: Validators.password,
                                enabled: !auth.isBusy,
                              ),
                              const SizedBox(height: 18),
                              CustomTextField(
                                label: AppStrings.confirmPassword,
                                controller: _confirm,
                                hint: 'Repeat your password',
                                obscure: true,
                                prefixIcon: Icons.lock_outline_rounded,
                                textInputAction: TextInputAction.done,
                                validator: (v) => Validators.confirmPassword(
                                  v,
                                  _password.text,
                                ),
                                enabled: !auth.isBusy,
                                onSubmitted: (_) => _submit(),
                              ),

                              if (auth.error != null) ...[
                                const SizedBox(height: 16),
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
                              label: AppStrings.signUp,
                              busy: auth.isBusy,
                              onPressed: _submit,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppStrings.haveAccount,
                                  style: text.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: auth.isBusy
                                      ? null
                                      : () => Navigator.of(context).maybePop(),
                                  child: const Text(AppStrings.signIn),
                                ),
                              ],
                            ),
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
