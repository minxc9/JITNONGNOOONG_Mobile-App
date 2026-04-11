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

const _brandOrange = Color(0xFFFF8A1D);
const _brandOrangeDeep = Color(0xFFF26A21);
const _brandOrangeSoft = Color(0xFFFFF1E3);
const _brandCream = Color(0xFFFFFAF5);
const _brandText = Color(0xFF2F241B);

class MharApp extends StatelessWidget {
  const MharApp({super.key});
  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _brandOrange,
      brightness: Brightness.light,
      primary: _brandOrange,
      secondary: const Color(0xFFFFB347),
      surface: Colors.white,
    );

    return MaterialApp(
      title: 'MharRuengSang',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: _brandCream,
        cardColor: Colors.white,
        dividerColor: const Color(0xFFF0DDC9),
        appBarTheme: const AppBarTheme(
          backgroundColor: _brandOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFF3E3D4)),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _brandOrange,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _brandOrangeDeep,
            side: const BorderSide(color: Color(0xFFFFC28F)),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _brandOrangeDeep,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          hintStyle: TextStyle(color: Colors.brown.shade300),
          labelStyle: TextStyle(color: Colors.brown.shade500),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFF0DDC9)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFF0DDC9)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _brandOrange, width: 1.6),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: _brandOrangeSoft,
          selectedColor: const Color(0xFFFFD0A7),
          labelStyle: const TextStyle(
            color: _brandText,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide.none,
          ),
        ),
        tabBarTheme: TabBarThemeData(
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          labelColor: _brandOrangeDeep,
          unselectedLabelColor: Colors.white,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          labelPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          splashBorderRadius: const BorderRadius.all(Radius.circular(18)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _brandOrange,
          foregroundColor: Colors.white,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: _brandText,
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: _brandText,
              displayColor: _brandText,
            ),
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_brandCream, _brandOrangeSoft],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: 32),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 34, vertical: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: _brandOrangeSoft,
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 38,
                      color: _brandOrange,
                    ),
                  ),
                  SizedBox(height: 18),
                  Text(
                    'MharRuengSang',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Fresh meals, quick delivery, one bright app.',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(color: _brandOrange),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
