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

        if (!isLoggedIn && !isAuthRoute) {
          return '/login';
        }

        if (isLoggedIn) {
          final role = authService.currentUser?.role.value;
          if (role == 'admin') {
            if (isAuthRoute) return '/admin/dashboard';
            return null; // Let them proceed to their admin page
          } else {
             // They are logged in but not an admin.
             if (location != '/forbidden') return '/forbidden';
             return null;
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
        GoRoute(
          path: '/forbidden',
          name: 'forbidden',
          builder: (context, state) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('403 - Akses Ditolak', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Anda tidak memiliki akses sebagai Admin.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => authService.logout(),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
