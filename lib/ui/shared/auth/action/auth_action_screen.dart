import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petshopapp/core/theme/app_colors.dart';

class AuthActionScreen extends StatefulWidget {
  final String? mode;
  final String? oobCode;

  const AuthActionScreen({super.key, this.mode, this.oobCode});

  @override
  State<AuthActionScreen> createState() => _AuthActionScreenState();
}

class _AuthActionScreenState extends State<AuthActionScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isSuccess = false;
  String _errorMessage = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    // Jika modenya verifikasi email, langsung proses otomatis saat halaman dibuka
    if (widget.mode == 'verifyEmail' && widget.oobCode != null) {
      _verifyEmail();
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await FirebaseAuth.instance.applyActionCode(widget.oobCode!);
      setState(() => _isSuccess = true);
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'expired-action-code') {
          _errorMessage = 'Link verifikasi sudah kadaluarsa. Silakan kirim ulang dari aplikasi.';
        } else if (e.code == 'invalid-action-code') {
          _errorMessage = 'Link verifikasi tidak valid atau sudah pernah digunakan.';
        } else {
          _errorMessage = e.message ?? 'Terjadi kesalahan saat memverifikasi email.';
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan sistem.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await FirebaseAuth.instance.confirmPasswordReset(
        code: widget.oobCode!,
        newPassword: _passwordController.text,
      );
      setState(() => _isSuccess = true);
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'expired-action-code') {
          _errorMessage = 'Link reset password sudah kadaluarsa. Silakan ajukan ulang.';
        } else if (e.code == 'invalid-action-code') {
          _errorMessage = 'Link tidak valid atau password sudah diubah.';
        } else if (e.code == 'weak-password') {
          _errorMessage = 'Password terlalu lemah.';
        } else {
          _errorMessage = e.message ?? 'Gagal mengubah password.';
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan sistem.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background (mengikuti gaya landing page)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const NetworkImage(
                    'https://images.unsplash.com/photo-1450778869180-41d0601e046e?q=80&w=2560&auto=format&fit=crop'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.35),
                  BlendMode.darken,
                ),
              ),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2B83E5),
                  Color(0xFF67B5F7),
                  Color(0xFF8CD0FF),
                ],
              ),
            ),
          ),
          
          // Konten Utama
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo / Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.mode == 'resetPassword' ? Icons.lock_reset : Icons.mark_email_read,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Judul
                      Text(
                        widget.mode == 'resetPassword' ? 'Reset Password' : 'Verifikasi Email',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (widget.oobCode == null || widget.mode == null) ...[
                        _buildErrorState('Link tidak valid. Pastikan Anda mengklik link langsung dari email.'),
                      ] else if (_isLoading) ...[
                        const SizedBox(height: 32),
                        const CircularProgressIndicator(color: AppColors.primary),
                        const SizedBox(height: 16),
                        Text(
                          widget.mode == 'resetPassword' ? 'Memproses...' : 'Sedang memverifikasi email...',
                          style: const TextStyle(color: AppColors.textLight),
                        ),
                      ] else if (_isSuccess) ...[
                        _buildSuccessState(),
                      ] else ...[
                        if (_errorMessage.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(top: 16, bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                        if (widget.mode == 'resetPassword')
                          _buildResetPasswordForm(),
                          
                        if (widget.mode == 'verifyEmail' && _errorMessage.isNotEmpty)
                          const SizedBox(height: 24),
                      ],
                      
                      // Tombol Kembali ke Landing Page (Ditampilkan kalau error, atau kalau verifikasi sukses)
                      if ((_errorMessage.isNotEmpty && !_isLoading) || _isSuccess || widget.oobCode == null) ...[
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => context.go('/'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Kembali ke Halaman Awal',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                      ]
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

  Widget _buildSuccessState() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          widget.mode == 'resetPassword' 
            ? 'Password berhasil diubah!\nSilakan login menggunakan password baru Anda.'
            : 'Email berhasil diverifikasi!\nAkun Anda sekarang sudah aktif dan siap digunakan.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textLight, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.red.shade700, height: 1.5),
      ),
    );
  }

  Widget _buildResetPasswordForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Masukkan password baru Anda di bawah ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textLight, fontSize: 14),
          ),
          const SizedBox(height: 24),
          
          // Field Password Baru
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password Baru',
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
              if (value.length < 6) return 'Password minimal 6 karakter';
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Field Konfirmasi Password
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Konfirmasi Password',
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Konfirmasi password wajib diisi';
              if (value != _passwordController.text) return 'Password tidak cocok';
              return null;
            },
          ),
          const SizedBox(height: 32),
          
          // Tombol Submit Reset
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Simpan Password Baru',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
