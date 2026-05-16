import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../../core/widgets/pk_input.dart';
import '../../../notifications/data/push_notification_service.dart';
import '../providers/auth_controller.dart';

enum _LoginMode { google, email }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  _LoginMode _mode = _LoginMode.google;
  PushPermissionResult? _notificationResult;
  bool _notificationBusy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PkCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'SCTCG',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading(
                              size: 34, color: AppColors.pkmnBlueDark),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Access your campus pickup account',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body(color: AppColors.pkmnGray),
                        ),
                        const SizedBox(height: 18),
                        _NotificationPermissionCard(
                          busy: _notificationBusy,
                          result: _notificationResult,
                          onPressed: _requestNotificationPermission,
                        ),
                        const SizedBox(height: 22),
                        _AuthTabs(
                          mode: _mode,
                          onChanged: (mode) {
                            setState(() => _mode = mode);
                            controller.clearError();
                          },
                        ),
                        if (auth.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          _AuthError(message: auth.errorMessage!),
                        ],
                        const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: _mode == _LoginMode.google
                              ? _GoogleLoginPane(
                                  busy: auth.busy,
                                  onPressed: auth.busy
                                      ? null
                                      : () => controller.loginWithGoogle(),
                                )
                              : _EmailLoginPane(
                                  busy: auth.busy,
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  onChanged: controller.clearError,
                                  onSubmit: auth.busy
                                      ? null
                                      : () => controller.loginWithEmail(
                                            email: _emailController.text,
                                            password: _passwordController.text,
                                          ),
                                ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'By signing in, you agree to our terms and conditions.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body(
                              size: 12, color: AppColors.pkmnGrayDark),
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
    );
  }

  Future<void> _requestNotificationPermission() async {
    setState(() => _notificationBusy = true);
    final result =
        await ref.read(pushNotificationServiceProvider).requestPermission();
    if (!mounted) return;
    setState(() {
      _notificationBusy = false;
      _notificationResult = result;
    });
  }
}

class _NotificationPermissionCard extends StatelessWidget {
  const _NotificationPermissionCard({
    required this.busy,
    required this.onPressed,
    this.result,
  });

  final bool busy;
  final PushPermissionResult? result;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final granted = result?.canRegister ?? false;
    final denied = result?.state == PushPermissionState.denied;
    final color = granted
      ? Colors.green.shade700
      : denied
            ? AppColors.pkmnRed
            : AppColors.pkmnBlue;
    final message = result?.message.isNotEmpty == true
        ? result!.message
        : 'Get order updates, counteroffers, pickup changes, and completed or cancelled alerts.';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: AppDecorations.controlRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  granted
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_none_outlined,
                  color: color,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order update alerts',
                          style: AppTextStyles.label(color: color)),
                      const SizedBox(height: 4),
                      Text(message,
                          style: AppTextStyles.body(
                              size: 12, color: AppColors.pkmnGrayDark)),
                    ],
                  ),
                ),
              ],
            ),
            if (!granted) ...[
              const SizedBox(height: 12),
              PkButton(
                label: busy ? 'Checking...' : 'Enable Notifications',
                icon: const Icon(Icons.notifications_active_outlined),
                loading: busy,
                onPressed: busy ? null : onPressed,
                expand: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AuthTabs extends StatelessWidget {
  const _AuthTabs({required this.mode, required this.onChanged});

  final _LoginMode mode;
  final ValueChanged<_LoginMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.pkmnBorder)),
      ),
      child: Row(
        children: [
          _AuthTabButton(
            label: 'UCSC Google',
            selected: mode == _LoginMode.google,
            onTap: () => onChanged(_LoginMode.google),
          ),
          _AuthTabButton(
            label: 'Email Login',
            icon: Icons.mail_outline,
            selected: mode == _LoginMode.email,
            onTap: () => onChanged(_LoginMode.email),
          ),
        ],
      ),
    );
  }
}

class _AuthTabButton extends StatelessWidget {
  const _AuthTabButton(
      {required this.label,
      required this.selected,
      required this.onTap,
      this.icon});

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.pkmnBlue : AppColors.pkmnGray;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDecorations.controlRadius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: selected ? AppColors.pkmnBlue : Colors.transparent,
                  width: 2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style:
                      AppTextStyles.label(color: color).copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthError extends StatelessWidget {
  const _AuthError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.pkmnRed.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.pkmnRed.withValues(alpha: 0.22)),
        borderRadius: AppDecorations.controlRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppColors.pkmnRed, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message,
                    style: AppTextStyles.body(
                        size: 14, color: AppColors.pkmnRed))),
          ],
        ),
      ),
    );
  }
}

class _GoogleLoginPane extends StatelessWidget {
  const _GoogleLoginPane({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey(_LoginMode.google),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sign in with your UCSC Google account.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body(size: 14, color: AppColors.pkmnGray),
        ),
        const SizedBox(height: 16),
        PkButton(
          label: 'Continue with Google',
          icon: const Icon(Icons.g_mobiledata),
          loading: busy,
          expand: true,
          onPressed: onPressed,
        ),
        if (busy) ...[
          const SizedBox(height: 12),
          Text('Signing you in...',
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.body(size: 13, color: AppColors.pkmnGrayDark)),
        ],
        const SizedBox(height: 16),
        PkButton(
          label: 'I have an access code',
          variant: PkButtonVariant.secondary,
          expand: true,
          onPressed: () => context.go('/register'),
        ),
      ],
    );
  }
}

class _EmailLoginPane extends StatelessWidget {
  const _EmailLoginPane({
    required this.busy,
    required this.emailController,
    required this.passwordController,
    required this.onChanged,
    required this.onSubmit,
  });

  final bool busy;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onChanged;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey(_LoginMode.email),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sign in with your email and password.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body(size: 14, color: AppColors.pkmnGray),
        ),
        const SizedBox(height: 14),
        PkInput(
          controller: emailController,
          label: 'Email address',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        PkInput(
          controller: passwordController,
          label: 'Password',
          obscureText: true,
          textInputAction: TextInputAction.done,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 16),
        PkButton(
            label: 'Sign In', loading: busy, expand: true, onPressed: onSubmit),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Not from UCSC? ',
                style: AppTextStyles.body(
                    size: 13, color: AppColors.pkmnGrayDark)),
            InkWell(
              onTap: () => context.go('/register'),
              borderRadius: AppDecorations.controlRadius,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Text(
                  'Have a code?',
                  style: AppTextStyles.body(size: 13, color: AppColors.pkmnBlue)
                      .copyWith(decoration: TextDecoration.underline),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
