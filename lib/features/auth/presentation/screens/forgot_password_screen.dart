import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../../core/widgets/pk_input.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _submitted = false;
  String _error = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email address.');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '${ApiEndpoints.baseUrl}/auth/forgot-password/',
        data: {'email': email},
      );
    } on DioException catch (e) {
      // Only surface non-4xx errors; 4xx means the server handled it
      if (e.response == null) {
        if (mounted) {
          setState(() => _error = 'Something went wrong. Please try again.');
        }
        return;
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
      return;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    // Always show success - never reveal whether the email exists
    if (mounted) setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pkmnBg,
      appBar: AppBar(
        backgroundColor: AppColors.pkmnBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.pkmnText,
          onPressed: () => context.go('/login'),
        ),
        title: Text(
          'Forgot Password',
          style: AppTextStyles.heading(size: 18, color: AppColors.pkmnText),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: PkCard(
            child: _submitted ? _buildSuccess() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Check your inbox',
          style: AppTextStyles.heading(size: 18, color: AppColors.pkmnText),
        ),
        const SizedBox(height: 12),
        Text(
          'If an account with that email exists, we sent a password reset link. '
          'Open the link in any browser to set a new password.',
          style: AppTextStyles.body(size: 14, color: AppColors.pkmnGray),
        ),
        const SizedBox(height: 20),
        PkButton(
          label: 'Back to Sign In',
          expand: true,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reset your password',
          style: AppTextStyles.heading(size: 18, color: AppColors.pkmnText),
        ),
        const SizedBox(height: 8),
        Text(
          "Enter your email and we'll send you a reset link.",
          style: AppTextStyles.body(size: 14, color: AppColors.pkmnGray),
        ),
        const SizedBox(height: 20),
        PkInput(
          controller: _emailController,
          label: 'Email address',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            if (_error.isNotEmpty) setState(() => _error = '');
          },
        ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _error,
            style: AppTextStyles.body(size: 13, color: AppColors.pkmnRed),
          ),
        ],
        const SizedBox(height: 20),
        PkButton(
          label: 'Send Reset Link',
          loading: _loading,
          expand: true,
          onPressed: _submit,
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => context.go('/login'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Back to sign in',
              style: AppTextStyles.body(size: 13, color: AppColors.pkmnBlue)
                  .copyWith(decoration: TextDecoration.underline),
            ),
          ),
        ),
      ],
    );
  }
}
