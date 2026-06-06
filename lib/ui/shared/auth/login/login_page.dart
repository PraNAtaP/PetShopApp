import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:petshopapp/services/auth_service.dart';

/// Login screen with email and password fields.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = context.read<AuthService>();
    final result = await authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result == 'email-not-verified') {
      context.go('/verify-email');
    } else if (result != null) {
      setState(() => _errorMessage = result);
    } else {
      // On success, tell the OS to save the credentials
      TextInput.finishAutofillContext();
      
      // Explicitly navigate instead of relying solely on GoRouter's refreshListenable
      final role = authService.currentUser?.role.value;
      if (role == 'admin') {
        context.go('/admin/dashboard');
      } else {
        context.go('/home');
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = context.read<AuthService>();
    final result = await authService.loginWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != null) {
      setState(() => _errorMessage = result);
    } else {
      final role = authService.currentUser?.role.value;
      if (role == 'admin') {
        context.go('/admin/dashboard');
      } else {
        context.go('/home');
      }
    }
  } 

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(text: _emailController.text);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lupa Password?'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Masukkan email Anda yang terdaftar untuk menerima link reset password.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Email tidak boleh kosong';
                  if (!value.contains('@')) return 'Format email tidak valid';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                final authService = context.read<AuthService>();
                final result = await authService.resetPassword(email: resetEmailController.text.trim());
                if (!mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result ?? 'Link reset password berhasil dikirim ke email Anda.'),
                    backgroundColor: result == null ? Colors.green : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Kirim Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Login'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: kIsWeb ? const EdgeInsets.all(32) : EdgeInsets.zero,
            decoration: kIsWeb
                ? BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  )
                : null,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),

                  // ── Header ───────────────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'lib/assets/img/1776076564947.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.pets,
                            size: 80,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Selamat Datang Kembali!',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Masuk ke akun Pet Point Anda',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textLight,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── Pesan Error ──────────────────────────────────────────
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Field Email ──────────────────────────────────────────
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      hintText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email tidak boleh kosong';
                      }
                      if (!value.contains('@')) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Field Password ───────────────────────────────────────
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  
                  // ── Lupa Password ──────────────────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _showForgotPasswordDialog,
                      child: const Text(
                        'Lupa Password?',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // ── Tombol Login ─────────────────────────────────────────
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.white,
                            ),
                          )
                        : const Text('Login'),
                  ),
                  
                  if (!kIsWeb) ...[
                    const SizedBox(height: 24),

                    // ── Divider ──────────────────────────────────────────────
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'ATAU MASUK DENGAN',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textLight,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Tombol Google ────────────────────────────────────────
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      icon: Image.asset(
                        'lib/assets/img/google_logo.png',
                        height: 20,
                        width: 20,
                        fit: BoxFit.contain,
                      ),
                      label: const Text('Masuk dengan Google'),
                    ),
                    const SizedBox(height: 16),

                    // ── Link ke Register ─────────────────────────────────────
                    Center(
                      child: TextButton(
                        onPressed:
                            _isLoading ? null : () => context.go('/register'),
                        child: RichText(
                          text: TextSpan(
                            text: 'Belum punya akun? ',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textLight,
                                ),
                            children: const [
                              TextSpan(
                                text: 'Daftar',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
