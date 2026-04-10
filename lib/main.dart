import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'utils/session_manager.dart';
import 'screens/customer/home_screen.dart';
import 'screens/restaurant/dashboard_screen.dart';
import 'screens/rider/dashboard_screen.dart';
import 'screens/admin/dashboard_screen.dart';

void main() {
  runApp(const MharApp());
}

class MharApp extends StatelessWidget {
  const MharApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MharRuengSang',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    await Future.delayed(const Duration(seconds: 1));
    final loggedIn = await SessionManager.isLoggedIn();
    if (!mounted) return;
    if (!loggedIn) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    final role = await SessionManager.getUserRole();
    if (!mounted) return;
    Widget dest;
    switch (role) {
      case 'RESTAURANT':
        dest = const RestaurantDashboardScreen();
        break;
      case 'RIDER':
        dest = const RiderDashboardScreen();
        break;
      case 'ADMIN':
        dest = const AdminDashboardScreen();
        break;
      default:
        dest = const CustomerHomeScreen();
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => dest));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant, size: 80, color: Colors.orange),
          SizedBox(height: 16),
          Text('MharRuengSang',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          SizedBox(height: 24),
          CircularProgressIndicator(color: Colors.orange),
        ],
      )),
    );
  }
}
