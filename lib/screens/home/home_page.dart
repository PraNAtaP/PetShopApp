import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

/// Home screen with role-based content rendering.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final isAdmin = user.role == UserRole.admin;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isAdmin
                ? [AppColors.primary, const Color(0xFF002A5C)]
                : [AppColors.background, AppColors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? AppColors.accent
                            : AppColors.secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAdmin
                                ? Icons.admin_panel_settings
                                : Icons.person,
                            size: 16,
                            color: isAdmin
                                ? AppColors.textDark
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user.role.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isAdmin
                                  ? AppColors.textDark
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          await authService.logout();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                size: 18,
                                color: isAdmin
                                    ? AppColors.white
                                    : AppColors.error,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isAdmin
                                      ? AppColors.white
                                      : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 2),

                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: isAdmin
                          ? AppColors.accent.withValues(alpha: 0.2)
                          : AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isAdmin
                            ? AppColors.accent
                            : AppColors.primary,
                        width: 2.5,
                      ),
                    ),
                    child: Icon(
                      isAdmin ? Icons.shield_rounded : Icons.pets,
                      size: 44,
                      color: isAdmin
                          ? AppColors.accent
                          : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                Center(
                  child: Text(
                    isAdmin
                        ? 'Halo admin ${user.nama}'
                        : 'Halo ${user.nama}\nmau ngapain hari ini?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isAdmin ? AppColors.white : AppColors.textDark,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Center(
                  child: Text(
                    isAdmin
                        ? 'Kelola data Pet Point dari dashboard ini.'
                        : 'Jelajahi layanan terbaik untuk hewan kesayangan Anda.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isAdmin
                          ? AppColors.white.withValues(alpha: 0.7)
                          : AppColors.textLight,
                    ),
                  ),
                ),

                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
