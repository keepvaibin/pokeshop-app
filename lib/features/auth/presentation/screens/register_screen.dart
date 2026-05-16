import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../../core/widgets/pk_input.dart';
import '../providers/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _codeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _codeValid = false;
  bool _validating = false;
  String? _localError;

  @override
  void dispose() {
    _codeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: PkCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Access Code', style: AppTextStyles.heading(size: 22)),
                    const SizedBox(height: 8),
                    Text('Non-UCSC accounts need a shop-issued access code.',
                        style: AppTextStyles.body()),
                    const SizedBox(height: 16),
                    PkInput(controller: _codeController, label: 'Access Code'),
                    const SizedBox(height: 12),
                    PkButton(
                      label: _codeValid ? 'Code Verified' : 'Validate Code',
                      variant: _codeValid
                          ? PkButtonVariant.accent
                          : PkButtonVariant.secondary,
                      loading: _validating,
                      onPressed: _validating
                          ? null
                          : () async {
                              setState(() {
                                _validating = true;
                                _localError = null;
                              });
                              try {
                                final valid = await controller
                                    .validateAccessCode(_codeController.text);
                                setState(() => _codeValid = valid);
                              } catch (error) {
                                setState(() => _localError = '$error');
                              } finally {
                                if (mounted) {
                                  setState(() => _validating = false);
                                }
                              }
                            },
                    ),
                    if (_codeValid) ...[
                      const SizedBox(height: 20),
                      Text('Account Details',
                          style: AppTextStyles.heading(size: 18)),
                      const SizedBox(height: 12),
                      PkInput(
                          controller: _emailController,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      PkInput(
                          controller: _passwordController,
                          label: 'Password',
                          obscureText: true),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: PkInput(
                                  controller: _firstNameController,
                                  label: 'First Name')),
                          const SizedBox(width: 12),
                          Expanded(
                              child: PkInput(
                                  controller: _lastNameController,
                                  label: 'Last Name')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      PkButton(
                        label: 'Create Account',
                        loading: auth.busy,
                        onPressed: auth.busy
                            ? null
                            : () => controller.registerWithAccessCode(
                                  email: _emailController.text,
                                  password: _passwordController.text,
                                  accessCode: _codeController.text,
                                  firstName: _firstNameController.text,
                                  lastName: _lastNameController.text,
                                ),
                      ),
                    ],
                    if ((_localError ?? auth.errorMessage) != null) ...[
                      const SizedBox(height: 12),
                      Text(_localError ?? auth.errorMessage!,
                          style: AppTextStyles.body(color: AppColors.pkmnRed)),
                    ],
                    const SizedBox(height: 12),
                    TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Back to sign in')),
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
