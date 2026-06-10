import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petshopapp/services/auth_service.dart';
import 'package:petshopapp/ui/shared/auth/login/login_page.dart';
import 'package:petshopapp/ui/shared/auth/action/auth_action_screen.dart';
import 'package:petshopapp/ui/admin/dashboard/admin_layout.dart';
import 'package:petshopapp/ui/shared/splash/splash_screen.dart';
import 'package:petshopapp/ui/web_landing/landing_page_screen.dart';
import 'package:petshopapp/ui/customer/chat/chat_screen.dart';

final GlobalKey<NavigatorState> adminNavigatorKey = GlobalKey<NavigatorState>();

/// Admin application route configuration using GoRouter.
class AdminRouter {
  static GoRouter router(AuthService authService) {
    return GoRouter(
      navigatorKey: adminNavigatorKey,
      initialLocation: '/',
      refreshListenable: authService,
      redirect: (context, state) {
        final isLoggedIn = authService.isLoggedIn;
        final location = state.matchedLocation;

        final isAuthRoute = location == '/login' || location == '/' || location == '/auth-action';

        if (!isLoggedIn && !isAuthRoute) {
          return '/login';
        }

        if (isLoggedIn) {
          final role = authService.currentUser?.role.value;
          if (role == 'admin') {
            if (location == '/login') return '/admin/dashboard';
            return null; // Let them proceed to their admin page or stay on landing page
          } else {
             // They are logged in but not an admin.
             if (location != '/forbidden' && location != '/') return '/forbidden';
             return null;
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'landing',
          builder: (context, state) {
            final action = state.uri.queryParameters['action'];
            return LandingPageScreen(action: action);
          },
        ),

        GoRoute(
          path: '/login',
          name: 'admin-login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/auth-action',
          name: 'auth-action',
          builder: (context, state) {
            final mode = state.uri.queryParameters['mode'];
            final oobCode = state.uri.queryParameters['oobCode'];
            return AuthActionScreen(mode: mode, oobCode: oobCode);
          },
        ),
        GoRoute(
          path: '/admin/dashboard',
          name: 'admin-dashboard',
          // The AdminLayout will render the Dashboard UI initially or route sub-screens
          builder: (context, state) => const AdminLayout(),
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
        GoRoute(
          path: '/chat',
          name: 'admin-chat',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>?;
            return ChatScreen(
              receiverId: args?['receiverId'],
              receiverName: args?['receiverName'],
            );
          },
        ),
      ],
    );
  }
}
