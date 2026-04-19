import 'package:go_router/go_router.dart';
import 'package:petshopapp/services/auth_service.dart';
import 'package:petshopapp/ui/shared/auth/login/login_page.dart';
import 'package:petshopapp/ui/shared/auth/register/register_page.dart';
import 'package:petshopapp/ui/shared/auth/verify/email_verification_page.dart';
import 'package:petshopapp/ui/customer/main/base_screen.dart';
import 'package:petshopapp/ui/customer/adoption/adoption_screen.dart';
import 'package:petshopapp/ui/customer/profile/edit_profile_screen.dart';
import 'package:petshopapp/ui/customer/profile/points_screen.dart';
import 'package:petshopapp/ui/customer/profile/profile_screen.dart';

/// Customer application route configuration using GoRouter.
class CustomerRouter {
  static GoRouter router(AuthService authService) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authService,
      redirect: (context, state) {
        final isLoggedIn = authService.isLoggedIn;
        final location = state.matchedLocation;

        final isAuthRoute = location == '/login' || location == '/register';

        if (isLoggedIn && isAuthRoute) return '/home';

        // Block unauthorized access to any route that is not login or register (e.g. /home, /adoption)
        if (!isLoggedIn && !isAuthRoute) return '/login';

        // Additional: block admin users out of customer app or just ignore them.
        // Actually, if role == admin, maybe redirect to an error? Or they can't login here?
        // Let's keep it simple for now as requested.
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/verify-email',
          name: 'verify-email',
          builder: (context, state) => const EmailVerificationPage(),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) =>
              const BaseScreen(), // Contains the BottomNavigationBar
        ),
        GoRoute(
          path: '/adoption',
          name: 'adoption',
          builder: (context, state) => const AdoptionScreen(),
        ),
        GoRoute(
          path: '/edit-profile',
          name: 'edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/points',
          name: 'points',
          builder: (context, state) => const PointsScreen(),
        ),
      ],
    );
  }
}
