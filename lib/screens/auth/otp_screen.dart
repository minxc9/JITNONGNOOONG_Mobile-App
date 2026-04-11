import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/session_manager.dart';
import '../customer/home_screen.dart';
import '../restaurant/dashboard_screen.dart';
import '../rider/dashboard_screen.dart';
import '../admin/dashboard_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter 6-digit OTP')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.verifyOtp(widget.email, otp);
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'];
        final user = data['user'];
        await SessionManager.saveToken(data['token']);
        await SessionManager.saveUser(
          id: user['id'],
          name: user['name'],
          email: user['email'],
          role: user['role'],
        );
        if (!mounted) return;
        Widget dest;
        switch (user['role']) {
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
        Navigator.pushAndRemoveUntil(
            context, MaterialPageRoute(builder: (_) => dest), (_) => false);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid OTP, try again')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter OTP')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 46,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'OTP sent to ${widget.email}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _otpController,
                      decoration: const InputDecoration(
                        labelText: '6-digit OTP',
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Verify',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
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
