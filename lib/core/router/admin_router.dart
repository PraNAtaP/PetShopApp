import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petshopapp/services/auth_service.dart';
import 'package:petshopapp/ui/shared/auth/login/login_page.dart';
import 'package:petshopapp/ui/admin/dashboard/admin_layout.dart';
import 'package:petshopapp/ui/admin/admin/add_pet_screen.dart';

/// Admin application route configuration using GoRouter.
class AdminRouter {
  static GoRouter router(AuthService authService) {
    return GoRouter(
      initialLocation: '/admin/dashboard',
      refreshListenable: authService,
      redirect: (context, state) {
        final isLoggedIn = authService.isLoggedIn;
        final location = state.matchedLocation;

        final isAuthRoute = location == '/login' || location == '/';

        if (isLoggedIn && isAuthRoute) return '/admin/dashboard';

        if (!isLoggedIn && (location.startsWith('/admin') || location == '/')) return '/login';

        // Additional admin verification loop:
        if (isLoggedIn && authService.currentUser != null) {
          if (authService.currentUser!.role.value != 'admin') {
            // Wait, we logged in as a normal user. For now just logout?
            // This happens on web.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              authService.logout();
            });
            return '/login';
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          name: 'admin-login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/admin/dashboard',
          name: 'admin-dashboard',
          // The AdminLayout will render the Dashboard UI initially or route sub-screens
          builder: (context, state) => const AdminLayout(),
        ),
        GoRoute(
          path: '/admin/add-pet',
          name: 'add-pet',
          builder: (context, state) => const AddPetScreen(),
        ),
      ],
    );
  }
}
