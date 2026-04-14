import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../screens/landing/landing_page.dart';
import '../../screens/login/login_page.dart';
import '../../screens/register/register_page.dart';
import '../../screens/verify/email_verification_page.dart';
import '../../screens/main/base_screen.dart';
import '../../screens/adoption/adoption_screen.dart';
import '../../screens/admin/add_pet_screen.dart';

/// Application route configuration using GoRouter.
class AppRouter {
  static GoRouter router(AuthService authService) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: authService,
      redirect: (context, state) {
        final isLoggedIn = authService.isLoggedIn;
        final location = state.matchedLocation;

        final isAuthRoute = location == '/' ||
            location == '/login' ||
            location == '/register';

        if (isLoggedIn && isAuthRoute) return '/home';

        if (!isLoggedIn && location == '/home') return '/login';

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'landing',
          builder: (context, state) => const LandingPage(),
        ),
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
          builder: (context, state) => const BaseScreen(),
        ),
        GoRoute(
          path: '/adoption',
          name: 'adoption',
          builder: (context, state) => const AdoptionScreen(),
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
