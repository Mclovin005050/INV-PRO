import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';

void main() async {
  // 1. Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase with current platform options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  runApp(const InventoryApp());
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          primary: const Color(0xFF2563EB),
          secondary: const Color(0xFF64748B),
          surface: Colors.white,
          error: const Color(0xFFEF4444),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1E293B),
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            side: BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
        ),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: Color(0xFF0F172A),
          selectedIconTheme: IconThemeData(color: Colors.white, size: 28),
          unselectedIconTheme: IconThemeData(color: Color(0xFF94A3B8), size: 24),
          selectedLabelTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelTextStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          indicatorColor: Color(0xFF1E293B),
        ),
        inputDecorationTheme: const InputDecorationThemeData(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(color: Color(0xFF475569)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
