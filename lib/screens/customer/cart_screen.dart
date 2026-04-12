import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/restaurant.dart';
import '../../services/api_service.dart';
import '../../utils/session_manager.dart';
import '../../widgets/shared_ui.dart';

class CartScreen extends StatefulWidget {
  final Restaurant restaurant;
  final Map<int, int> cart;
  final List<MenuItem> menuItems;

  const CartScreen({
    super.key,
    required this.restaurant,
    required this.cart,
    required this.menuItems,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = 'CREDIT_CARD';
  bool _placingOrder = false;

  List<MapEntry<int, int>> get _cartItems =>
      widget.cart.entries.where((entry) => entry.value > 0).toList();

  double get _subtotal {
    double total = 0;
    for (final entry in _cartItems) {
      final item =
          widget.menuItems.firstWhere((menuItem) => menuItem.id == entry.key);
      total += item.price * entry.value;
    }
    return total;
  }

  double get _deliveryFee => _subtotal >= 300 ? 0 : 35;

  double get _grandTotal => _subtotal + _deliveryFee;

  Future<void> _placeOrder() async {
    final userId = await SessionManager.getUserId();
    if (userId == null) return;
    if (!mounted) return;

    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a delivery address.')),
      );
      return;
    }

    setState(() => _placingOrder = true);

    final items = _cartItems.map((entry) {
      final item =
          widget.menuItems.firstWhere((menuItem) => menuItem.id == entry.key);
      return {
        'menuItemId': item.id,
        'menuItemName': item.name,
        'quantity': entry.value,
        'unitPrice': item.price,
      };
    }).toList();

    try {
      final paymentResponse = await ApiService.processPayment({
        'orderId': 0,
        'paymentMethod': _paymentMethod,
        'amount': _grandTotal,
      });
      final paymentBody = jsonDecode(paymentResponse.body);
      if (paymentResponse.statusCode >= 400 || paymentBody['success'] != true) {
        throw Exception(paymentBody['message']);
      }

      final response = await ApiService.createOrder({
        'customerId': userId,
        'restaurantId': widget.restaurant.id,
        'deliveryAddress': _addressController.text.trim(),
        'deliveryLatitude': 13.7563,
        'deliveryLongitude': 100.5018,
        'specialInstructions': _notesController.text.trim(),
        'orderItems': items,
        'totalAmount': _grandTotal,
      });
      final body = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode < 400 && body['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        throw Exception(body['message']);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to place order. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.orange,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Order',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._cartItems.map((entry) {
                    final item = widget.menuItems
                        .firstWhere((menuItem) => menuItem.id == entry.key);
                    final quantity = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 64,
                              height: 64,
                              child: AppRemoteImageBox(
                                imageUrl: item.imageUrl,
                                fallbackIcon: Icons.fastfood,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Qty: $quantity',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                Text(
                                  '฿${item.price.toStringAsFixed(2)} each',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '฿${(item.price * quantity).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delivery Address',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Enter your delivery address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Special instructions',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Method',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'CREDIT_CARD',
                        label: Text('Credit Card'),
                        icon: Icon(Icons.credit_card),
                      ),
                      ButtonSegment<String>(
                        value: 'BANK_TRANSFER_QR',
                        label: Text('QR / PromptPay'),
                        icon: Icon(Icons.qr_code_2),
                      ),
                    ],
                    selected: {_paymentMethod},
                    selectedIcon: const Icon(Icons.check),
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor:
                          Colors.orange.withValues(alpha: 0.15),
                      selectedForegroundColor: Colors.orange[900],
                    ),
                    onSelectionChanged: (values) =>
                        setState(() => _paymentMethod = values.first),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _paymentMethod == 'CREDIT_CARD'
                        ? 'Use your saved card'
                        : 'Scan a QR code to pay',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _summaryRow('Subtotal', _subtotal),
                  const SizedBox(height: 8),
                  _summaryRow(
                    _deliveryFee == 0 ? 'Delivery Fee (Free)' : 'Delivery Fee',
                    _deliveryFee,
                  ),
                  const Divider(height: 24),
                  _summaryRow('Total', _grandTotal, emphasize: true),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _placingOrder ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _placingOrder
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Place Order',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool emphasize = false}) {
    final style = TextStyle(
      fontSize: emphasize ? 18 : 15,
      fontWeight: emphasize ? FontWeight.bold : FontWeight.w500,
      color: emphasize ? Colors.orange : null,
    );
    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text('฿${value.toStringAsFixed(2)}', style: style),
      ],
    );
  }
}
