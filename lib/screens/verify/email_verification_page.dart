import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';

/// Email verification waiting screen.
///
/// Shown after registration. Instructs the user to verify their email.
/// Provides "Saya Sudah Verifikasi" and "Kirim Ulang Email" actions.
class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _isCheckingVerification = false;
  bool _isResending = false;

  Future<void> _checkVerification() async {
    setState(() => _isCheckingVerification = true);

    final authService = context.read<AuthService>();
    final isVerified = await authService.checkEmailVerified();

    if (!mounted) return;
    setState(() => _isCheckingVerification = false);

    if (isVerified) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sabar King, email kamu belum terverifikasi.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);

    final authService = context.read<AuthService>();
    final error = await authService.resendVerificationEmail();

    if (!mounted) return;
    setState(() => _isResending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? 'Email verifikasi telah dikirim ulang!',
        ),
        backgroundColor: error != null ? AppColors.error : AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 40),

              Text(
                'Verifikasi Akun Kamu, King!',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Kami telah mengirimkan link verifikasi ke email kamu. '
                'Silakan klik link tersebut untuk mengaktifkan akun Pet Point.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textLight,
                  height: 1.6,
                ),
              ),

              const Spacer(flex: 1),

              ElevatedButton(
                onPressed:
                    _isCheckingVerification ? null : _checkVerification,
                child: _isCheckingVerification
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Saya Sudah Verifikasi'),
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: _isResending ? null : _resendEmail,
                child: _isResending
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary.withValues(alpha: 0.6),
                        ),
                      )
                    : Text(
                        'Kirim Ulang Email',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () async {
                  final router = GoRouter.of(context);
                  final authService = context.read<AuthService>();
                  await authService.logout();
                  router.go('/login');
                },
                child: Text(
                  'Kembali ke Login',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
