import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import 'otp_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  Timer? _snackTimer;

  static const _demoAccounts = [
    (
      label: 'Customer',
      email: 'customer@foodexpress.com',
      password: 'customer123',
    ),
    (
      label: 'Restaurant',
      email: 'restaurant@foodexpress.com',
      password: 'restaurant123',
    ),
    (
      label: 'Rider',
      email: 'rider@foodexpress.com',
      password: 'rider123',
    ),
    (
      label: 'Admin',
      email: 'admin@foodexpress.com',
      password: 'admin123',
    ),
  ];

  @override
  void dispose() {
    _snackTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemoCredentials(String email, String password, String label) {
    _emailController.text = email;
    _passwordController.text = password;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('$label account filled. Tap Sign In to continue.')),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.login(email, password);
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpScreen(email: email)),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(body['message'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surfaceContainerLowest,
                const Color(0xFFFFF1E3),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 590),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB347), Color(0xFFFF8A1D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFF8A1D).withValues(alpha: 0.28),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.ramen_dining,
                        size: 34,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                        children: [
                          TextSpan(
                            text: 'Food',
                            style: TextStyle(color: Color(0xFF1B2232)),
                          ),
                          TextSpan(
                            text: 'Express',
                            style: TextStyle(color: Color(0xFFFF8A1D)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Sign in to your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6C7588),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email Address',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475067),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                hintText: 'you@example.com',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Password',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475067),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                hintText: 'Enter your password',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text('Sign In'),
                              ),
                            ),
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(color: Colors.grey.shade300),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text(
                                    'Demo Accounts',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(color: Colors.grey.shade300),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 10,
                                runSpacing: 10,
                                children: _demoAccounts.map((account) {
                                  return ActionChip(
                                    avatar: const Icon(
                                      Icons.flash_on,
                                      size: 18,
                                    ),
                                    label: Text(account.label),
                                    onPressed: () => _fillDemoCredentials(
                                      account.email,
                                      account.password,
                                      account.label,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'Tap a demo account to auto-fill credentials',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                ),
                                child: const Text(
                                  'New customer? Create an account',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '© 2026 FoodExpress · All rights reserved',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
