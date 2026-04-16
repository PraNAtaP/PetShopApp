import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await NotificationService.initialize();
  // Request notification permissions
  NotificationService.instance.requestPermission();

  final authService = AuthService();
  await authService.initializeAuth();

  runApp(PetPointApp(authService: authService));
}


/// Root widget for the Pet Point application.
class PetPointApp extends StatefulWidget {
  final AuthService authService;

  const PetPointApp({super.key, required this.authService});

  @override
  State<PetPointApp> createState() => _PetPointAppState();
}

class _PetPointAppState extends State<PetPointApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.router(widget.authService);
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
