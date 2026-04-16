import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'core/router/customer_router.dart';
import 'core/router/admin_router.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // For Web, if options are missing, this throws an error.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Only initialize notifications on mobile since Web lacks firebase-messaging-sw.js and local notifications.
    if (!kIsWeb) {
      await NotificationService.initialize();
      NotificationService.instance.requestPermission();
    }

    final authService = AuthService();
    await authService.initializeAuth();

    if (kIsWeb) {
      runApp(AdminApp(authService: authService));
    } else {
      runApp(CustomerApp(authService: authService));
    }
  } catch (e) {
    // Prevent silent blank screen by rendering the error
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Initialization Failed:\n$e\n\n'
                'Jika ini di Web, Anda mungkin belum mengonfigurasi Firebase Web (firebase_options.dart).',
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


/// Root widget for the Web Admin Application.
class AdminApp extends StatefulWidget {
  final AuthService authService;

  const AdminApp({super.key, required this.authService});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AdminRouter.router(widget.authService);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.authService,
      child: MaterialApp.router(
        title: 'Pet Point Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
      ),
    );
  }
}

/// Root widget for the Mobile Customer Application.
class CustomerApp extends StatefulWidget {
  final AuthService authService;

  const CustomerApp({super.key, required this.authService});

  @override
  State<CustomerApp> createState() => _CustomerAppState();
}

class _CustomerAppState extends State<CustomerApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = CustomerRouter.router(widget.authService);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.authService,
      child: MaterialApp.router(
        title: 'Pet Point',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
      ),
    );
  }
}
