import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:petshopapp/core/theme/app_colors.dart';

class AuthActionScreen extends StatefulWidget {
  final String? mode;
  final String? oobCode;

  const AuthActionScreen({super.key, this.mode, this.oobCode});

  @override
  State<AuthActionScreen> createState() => _AuthActionScreenState();
}

class _AuthActionScreenState extends State<AuthActionScreen> {
  bool _isLoading = true;
  bool _isSuccess = false;
  String? _errorMessage;

  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isObscureNew = true;
  bool _isObscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _handleAction();
  }

  Future<void> _handleAction() async {
    final mode = widget.mode;
    final oobCode = widget.oobCode;

    if (mode == null || oobCode == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Link tidak valid atau tidak lengkap.';
      });
      return;
    }

    if (mode == 'verifyEmail') {
      await _verifyEmail(oobCode);
    } else if (mode == 'resetPassword') {
      // For resetPassword, we don't automatically process.
      // We just stop loading and show the form.
      setState(() {
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Mode tidak didukung.';
      });
    }
  }

  Future<void> _verifyEmail(String oobCode) async {
    try {
      await FirebaseAuth.instance.applyActionCode(oobCode);
      if (mounted) {
        // Redirect ke landing page dengan penanda sukses
        context.go('/?action=emailVerified');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _getFriendlyErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
      });
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.confirmPasswordReset(
        code: widget.oobCode!,
        newPassword: _newPasswordController.text.trim(),
      );
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _getFriendlyErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
      });
    }
  }

  String _getFriendlyErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'expired-action-code':
      case 'invalid-action-code':
        return 'Link telah kedaluwarsa atau sudah digunakan. Silakan minta link baru dari aplikasi.';
      case 'user-disabled':
        return 'Akun pengguna telah dinonaktifkan.';
      case 'user-not-found':
        return 'Pengguna tidak ditemukan.';
      case 'weak-password':
        return 'Password terlalu lemah.';
      default:
        return 'Gagal memproses permintaan ($errorCode).';
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background like Landing Page
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: NetworkImage(
                    'https://images.unsplash.com/photo-1450778869180-41d0601e046e?q=80&w=2560&auto=format&fit=crop'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black38,
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
          
          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    width: isMobile ? double.infinity : 500,
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: _buildContent(),
                  ),
                ),
              ),
            ),
          ),
          
          // Back Button / Logo
          Positioned(
            top: 40,
            left: isMobile ? 20 : 50,
            child: Row(
              children: [
                Image.asset('lib/assets/img/1776076564947.png', height: 40),
                const SizedBox(width: 12),
                const Text(
                  'Pet Point',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 24),
          Text(
            'Memproses...',
            style: TextStyle(fontSize: 16, color: AppColors.textDark),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 64),
          const SizedBox(height: 24),
          const Text(
            'Ops! Terjadi Kesalahan',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textLight, height: 1.5),
          ),
          const SizedBox(height: 32),
          _buildBackToAppButton(),
        ],
      );
    }

    if (_isSuccess) {
      String title = widget.mode == 'verifyEmail' 
          ? 'Email Berhasil Diverifikasi!' 
          : 'Reset Password Berhasil!';
      String subtitle = widget.mode == 'verifyEmail'
          ? 'Akun kamu sekarang sudah aktif. Silakan kembali ke aplikasi Pet Point dan login.'
          : 'Silakan kembali ke aplikasi Pet Point dan login dengan password barumu.';

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textLight, height: 1.5),
          ),
          const SizedBox(height: 32),
          _buildBackToAppButton(),
        ],
      );
    }

    // Default: Reset Password Form
    if (widget.mode == 'resetPassword') {
      return Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_reset, color: AppColors.primary, size: 64),
            const SizedBox(height: 24),
            const Text(
              'Buat Password Baru',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            const Text(
              'Masukkan password baru untuk akun Pet Point kamu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textLight, height: 1.5),
            ),
            const SizedBox(height: 32),
            
            TextFormField(
              controller: _newPasswordController,
              obscureText: _isObscureNew,
              decoration: InputDecoration(
                labelText: 'Password Baru',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_isObscureNew ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _isObscureNew = !_isObscureNew),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
                if (value.length < 6) return 'Password minimal 6 karakter';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _isObscureConfirm,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_isObscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _isObscureConfirm = !_isObscureConfirm),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Konfirmasi password tidak boleh kosong';
                if (value != _newPasswordController.text) return 'Password tidak sama';
                return null;
              },
            ),
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: _resetPassword,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Simpan Password Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBackToAppButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          // Navigasi ke Landing Page Utama di Web, atau Login di HP
          if (kIsWeb) {
            context.go('/');
          } else {
            context.go('/login');
          }
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(kIsWeb ? 'Kembali ke Landing Page' : 'Kembali ke Halaman Login', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
