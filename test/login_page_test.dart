import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:petshopapp/ui/shared/auth/login/login_page.dart';
import 'package:petshopapp/services/auth_service.dart';
import 'package:petshopapp/models/user_model.dart';

// Fake implementation of AuthService to bypass Firebase and provide controlled responses
class FakeAuthService extends ChangeNotifier implements AuthService {
  UserModel? _currentUser;
  bool _isLoading = false;

  String? loginReturnValue;
  String? googleLoginReturnValue;
  String? resetPasswordReturnValue;

  @override
  UserModel? get currentUser => _currentUser;

  @override
  bool get isLoggedIn => _currentUser != null;

  @override
  bool get isLoading => _isLoading;

  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  @override
  Future<String?> login({required String email, required String password}) async {
    return loginReturnValue;
  }

  @override
  Future<String?> loginWithGoogle() async {
    return googleLoginReturnValue;
  }

  @override
  Future<String?> resetPassword({required String email}) async {
    return resetPasswordReturnValue;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeAuthService fakeAuthService;

  setUp(() {
    fakeAuthService = FakeAuthService();
  });

  // Helper widget builder to set up Provider and GoRouter configuration
  Widget buildTestableWidget(GoRouter router) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: fakeAuthService),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  Finder findFieldByHint(String hint) {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == hint,
    );
  }

  group('Widget Test Halaman Login', () {
    testWidgets('Tampilan awal halaman login memuat semua komponen utama', (WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        ],
      );

      await tester.pumpWidget(buildTestableWidget(router));
      await tester.pumpAndSettle();

      // Memverifikasi adanya field Email dan Password
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(findFieldByHint('Email'), findsOneWidget);
      expect(findFieldByHint('Password'), findsOneWidget);

      // Memverifikasi tombol Login
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);

      // Memverifikasi tombol Lupa Password
      expect(find.text('Lupa Password?'), findsOneWidget);
    });

    testWidgets('Validasi form: field kosong menampilkan pesan error', (WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        ],
      );

      await tester.pumpWidget(buildTestableWidget(router));
      await tester.pumpAndSettle();

      // Klik tombol login tanpa mengisi apa-apa
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      // Verifikasi pesan error validasi muncul
      expect(find.text('Email tidak boleh kosong'), findsOneWidget);
      expect(find.text('Password tidak boleh kosong'), findsOneWidget);
    });

    testWidgets('Validasi form: email dengan format salah menampilkan pesan error', (WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        ],
      );

      await tester.pumpWidget(buildTestableWidget(router));
      await tester.pumpAndSettle();

      // Masukkan format email yang salah
      await tester.enterText(findFieldByHint('Email'), 'budi-salah');
      await tester.enterText(findFieldByHint('Password'), 'password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      expect(find.text('Format email tidak valid'), findsOneWidget);
      expect(find.text('Email tidak boleh kosong'), findsNothing);
    });

    testWidgets('Login gagal menampilkan pesan error dari sistem', (WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        ],
      );

      // Set return value login agar mengembalikan error
      fakeAuthService.loginReturnValue = 'Email atau password salah.';

      await tester.pumpWidget(buildTestableWidget(router));
      await tester.pumpAndSettle();

      await tester.enterText(findFieldByHint('Email'), 'budi@example.com');
      await tester.enterText(findFieldByHint('Password'), 'password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      // Verifikasi banner error muncul dengan teks error yang sesuai
      expect(find.text('Email atau password salah.'), findsOneWidget);
    });

    testWidgets('Login sukses sebagai Customer berhasil mengalihkan ke /home', (WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
          GoRoute(path: '/home', builder: (context, state) => const Scaffold(body: Text('Customer Home Screen'))),
        ],
      );

      // Set user yang sukses login sebagai Customer
      fakeAuthService.loginReturnValue = null; // null artinya tidak ada error/sukses
      fakeAuthService.setCurrentUser(const UserModel(
        uid: 'cust123',
        nama: 'Budi Customer',
        email: 'budi@example.com',
        role: UserRole.customer,
      ));

      await tester.pumpWidget(buildTestableWidget(router));
      await tester.pumpAndSettle();

      await tester.enterText(findFieldByHint('Email'), 'budi@example.com');
      await tester.enterText(findFieldByHint('Password'), 'password123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      // Verifikasi halaman berpindah ke Customer Home Screen
      expect(find.text('Customer Home Screen'), findsOneWidget);
    });

    testWidgets('Login sukses sebagai Admin berhasil mengalihkan ke /admin/dashboard', (WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
          GoRoute(path: '/admin/dashboard', builder: (context, state) => const Scaffold(body: Text('Admin Dashboard Screen'))),
        ],
      );

      // Set user yang sukses login sebagai Admin
      fakeAuthService.loginReturnValue = null;
      fakeAuthService.setCurrentUser(const UserModel(
        uid: 'admin123',
        nama: 'Min Pet Admin',
        email: 'admin@petpoint.com',
        role: UserRole.admin,
      ));

      await tester.pumpWidget(buildTestableWidget(router));
      await tester.pumpAndSettle();

      await tester.enterText(findFieldByHint('Email'), 'admin@petpoint.com');
      await tester.enterText(findFieldByHint('Password'), 'admin123');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      // Verifikasi halaman berpindah ke Admin Dashboard Screen
      expect(find.text('Admin Dashboard Screen'), findsOneWidget);
    });

    testWidgets('Dialog Lupa Password muncul dan memicu reset password saat diklik', (WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        ],
      );

      fakeAuthService.resetPasswordReturnValue = null; // sukses kirim link

      await tester.pumpWidget(buildTestableWidget(router));
      await tester.pumpAndSettle();

      // Tap tombol Lupa Password?
      await tester.tap(find.text('Lupa Password?'));
      await tester.pumpAndSettle();

      // Verifikasi dialog Lupa Password muncul
      expect(find.text('Lupa Password?'), findsNWidgets(2)); // Satu di background, satu di dialog title
      expect(find.text('Masukkan email Anda yang terdaftar untuk menerima link reset password.'), findsOneWidget);

      // Isi email di dialog
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: findFieldByHint('Email'),
        ),
        'budi@example.com',
      );
      
      
      // Klik Kirim Link
      await tester.tap(find.widgetWithText(ElevatedButton, 'Kirim Link'));
      await tester.pumpAndSettle();

      // Verifikasi dialog tertutup (hanya tersisa 1 teks Lupa Password? di background)
      expect(find.text('Masukkan email Anda yang terdaftar untuk menerima link reset password.'), findsNothing);
    });
  });
}
