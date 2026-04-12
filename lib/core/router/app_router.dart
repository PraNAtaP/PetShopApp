import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../screens/landing/landing_page.dart';
import '../../screens/login/login_page.dart';
import '../../screens/register/register_page.dart';
import '../../screens/home/home_page.dart';

/// Application route configuration using GoRouter.
class AppRouter {
  static GoRouter router(AuthService authService) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: authService,
      redirect: (context, state) {
        final isLoggedIn = authService.isLoggedIn;
        final location = state.matchedLocation;

        final isAuthRoute =
            location == '/' || location == '/login' || location == '/register';

        // Logged in → skip landing/login/register, go to home
        if (isLoggedIn && isAuthRoute) return '/home';

        // Not logged in → block /home
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
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),
      ],
    );
  }
}
