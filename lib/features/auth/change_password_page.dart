import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/auth_backdrop.dart';
import '../../shared/widgets/custom_textfield.dart';
import '../../shared/widgets/primary_button.dart';
import '../../utils/validators.dart';
import 'auth_provider.dart';

/// Forces a provisioned account onto its own password.
///
/// The school's admin created this driver or parent with a shared default, and
/// [User.mustChangePassword] stays set until they replace it. Until then this
/// screen is the whole app: there is no skip, and the back gesture is blocked,
/// because the point is that the handover credential stops working.
///
/// It is reachable voluntarily too — [forced] false gives it a back button and
/// the usual title.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key, this.forced = false});

  final bool forced;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await AuthService.instance.changePassword(
        currentPassword: _current.text,
        newPassword: _next.text,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
      return;
    }

    if (!mounted) return;

    final user = AuthService.instance.currentUser;
    if (user == null) {
      // The session went away mid-change. Nothing to go home to.
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
      return;
    }

    AuthScope.of(context).syncUser();

    if (widget.forced) {
      // Replace the stack — there is nothing behind this screen worth going
      // back to, and the login page is done with.
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.homeFor(user.role),
        (route) => false,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return PopScope(
      // A forced change cannot be dismissed: backing out would leave the
      // account on the shared default with a valid token in hand.
      canPop: !widget.forced,
      child: Scaffold(
        appBar: widget.forced
            ? null
            : AppBar(title: const Text('Change password')),
        body: Stack(
          children: [
            const AuthBackdrop(intensity: 0.6),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.forced) ...[
                            const AppLogo(size: 60, showName: false),
                            const SizedBox(height: 28),
                            Text(
                              'Set your\npassword.',
                              style: text.displaySmall,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Your school gave you a temporary one. Choose your '
                              'own to carry on.',
                              style: text.bodyLarge
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 32),
                          ],
                          CustomTextField(
                            label: widget.forced
                                ? 'Temporary password'
                                : 'Current password',
                            controller: _current,
                            hint: 'The one you were given',
                            obscure: true,
                            enabled: !_busy,
                            prefixIcon: Icons.lock_outline_rounded,
                            validator: (v) => Validators.required(
                              v,
                              field: 'Your current password',
                            ),
                          ),
                          const SizedBox(height: 18),
                          CustomTextField(
                            label: 'New password',
                            controller: _next,
                            hint: 'At least 8 characters',
                            obscure: true,
                            enabled: !_busy,
                            prefixIcon: Icons.lock_reset_rounded,
                            validator: (v) {
                              final base = Validators.password(v);
                              if (base != null) return base;
                              // Clearing the flag while keeping the shared
                              // default would defeat the whole exercise — the
                              // server rejects it too.
                              if (v == _current.text) {
                                return 'Choose something different from the old one.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          CustomTextField(
                            label: 'Confirm new password',
                            controller: _confirm,
                            hint: 'Type it again',
                            obscure: true,
                            enabled: !_busy,
                            prefixIcon: Icons.lock_reset_rounded,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _busy ? null : _submit(),
                            validator: (v) =>
                                Validators.confirmPassword(v, _next.text),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            _ErrorBanner(message: _error!),
                          ],
                          const SizedBox(height: 28),
                          PrimaryButton(
                            label: 'Save password',
                            busy: _busy,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
