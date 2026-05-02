import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'meal_booking_screen.dart';
import 'meal_pass_screen.dart';
import 'meal_history_screen.dart';
import 'profile_screen.dart';
import 'feedback_screen.dart';
import 'registration_screen.dart';
import 'auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isLoggedIn = await AuthService.isLoggedIn();
  runApp(CMSApp(isLoggedIn: isLoggedIn));
}

class CMSApp extends StatelessWidget {
  final bool isLoggedIn;
  const CMSApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hostel Mess CMS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF944A00)),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/meal-booking': (context) => const MealBookingScreen(),
        '/meal-pass': (context) => const MealPassScreen(),
        '/history': (context) => const MealHistoryScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/feedback': (context) => const FeedbackScreen(),
        '/register': (context) => const RegistrationScreen(),
      },
    );
  }
}
