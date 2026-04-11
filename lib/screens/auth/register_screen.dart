import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final cardNumber = _cardNumberController.text.trim();
    final expiry = _expiryController.text.trim();
    final cvv = _cvvController.text.trim();

    if ([
      firstName,
      lastName,
      email,
      phone,
      address,
      password,
      confirmPassword,
      cardNumber,
      expiry,
      cvv,
    ].any((value) => value.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.register({
        'name': '$firstName $lastName'.trim(),
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'phoneNumber': phone,
        'deliveryAddress': address,
        'address': address,
        'role': 'CUSTOMER',
        'paymentInfo': {
          'cardNumber': cardNumber,
          'expiryDate': expiry,
          'cvv': cvv,
        },
      });
      final body = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 && body['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registered! Please login.')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(body['message'] ?? 'Registration failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Registration')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer Registration',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Create your account to start ordering',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _textField(
                            _firstNameController,
                            'First Name *',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _textField(
                            _lastNameController,
                            'Last Name *',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _textField(
                      _emailController,
                      'Email *',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _textField(
                      _phoneController,
                      'Mobile Number *',
                      hintText: '+66 XX XXX XXXX',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Required for account verification and order updates',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _textField(
                      _addressController,
                      'Delivery Address *',
                      hintText: 'Street, District, City',
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Account Security',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _textField(
                      _passwordController,
                      'Password *',
                      obscureText: true,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Must be updated every month',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _textField(
                      _confirmPasswordController,
                      'Confirm Password *',
                      obscureText: true,
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Payment Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _textField(
                      _cardNumberController,
                      'Credit Card Number *',
                      hintText: '1234 5678 9012 3456',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _textField(
                            _expiryController,
                            'Expiry Date *',
                            hintText: 'MM/YY',
                            keyboardType: TextInputType.datetime,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _textField(
                            _cvvController,
                            'CVV *',
                            hintText: '123',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Register',
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

  Widget _textField(
    TextEditingController controller,
    String label, {
    String? hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
      ),
    );
  }
}
