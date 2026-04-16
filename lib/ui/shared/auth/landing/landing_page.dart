import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petshopapp/core/theme/app_colors.dart';

/// Welcoming landing screen with branding, tagline, and navigation buttons.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, Color(0xFF002A5C)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo placeholder
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.pets,
                    size: 56,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 24),

                // App name
                Text(
                  'Pet Point',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // Tagline
                Text(
                  'Sahabat terbaik untuk perawatan\nhewan kesayangan Anda 🐾',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
                ),

                const Spacer(flex: 3),

                // Login button
                ElevatedButton(
                  onPressed: () => context.push('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.textDark,
                  ),
                  child: const Text('Login'),
                ),
                const SizedBox(height: 14),

                // Register button
                OutlinedButton(
                  onPressed: () => context.push('/register'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    side: const BorderSide(color: AppColors.white, width: 1.5),
                  ),
                  child: const Text('Register'),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
