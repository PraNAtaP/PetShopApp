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
import 'package:petshopapp/ui/customer/checkout/checkout_review_screen.dart';
import 'package:petshopapp/ui/customer/checkout/payment_method_screen.dart';
import 'package:petshopapp/ui/customer/checkout/payment_execution_screen.dart';
import 'package:petshopapp/ui/shared/splash/splash_screen.dart';

/// Customer application route configuration using GoRouter.
class CustomerRouter {
  static GoRouter router(AuthService authService) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authService,
      redirect: (context, state) {
        final isLoggedIn = authService.isLoggedIn;
        final location = state.matchedLocation;

        final isAuthRoute = location == '/login' || location == '/register' || location == '/splash' || location == '/verify-email';

        if (isLoggedIn && (location == '/login' || location == '/register' || location == '/verify-email')) return '/home';

        // Block unauthorized access to any route that is not an auth route
        if (!isLoggedIn && !isAuthRoute) return '/splash';

        // Additional: block admin users out of customer app or just ignore them.
        // Actually, if role == admin, maybe redirect to an error? Or they can't login here?
        // Let's keep it simple for now as requested.
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
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
        GoRoute(
          path: '/checkout-review',
          name: 'checkout-review',
          builder: (context, state) => const CheckoutReviewScreen(),
        ),
        GoRoute(
          path: '/payment-method',
          name: 'payment-method',
          builder: (context, state) => const PaymentMethodScreen(),
        ),
        GoRoute(
          path: '/payment-execution',
          name: 'payment-execution',
          builder: (context, state) {
            final method = state.extra as String? ?? 'QRIS';
            return PaymentExecutionScreen(paymentMethod: method);
          },
        ),
      ],
    );
  }
}
