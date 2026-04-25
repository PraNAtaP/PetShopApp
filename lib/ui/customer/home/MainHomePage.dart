import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/customer/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF003F87),
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const PetShopApp());
}

class PetShopApp extends StatelessWidget {
  const PetShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetShop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF4F7FC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003F87),
          primary: const Color(0xFF003F87),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
