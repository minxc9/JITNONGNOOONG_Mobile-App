import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/api_service.dart';
import '../../utils/session_manager.dart';
import 'order_tracking_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final userId = await SessionManager.getUserId();
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final orders = await ApiService.fetchOrdersForCustomer(userId);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load your orders right now.')),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'READY_FOR_PICKUP':
      case 'PICKED_UP':
        return Colors.purple;
      case 'PREPARING':
        return Colors.deepOrange;
      case 'PENDING':
      case 'CONFIRMED':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            )
          : _orders.isEmpty
              ? RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView(
                    children: const [
                      SizedBox(height: 140),
                      Center(child: Text('No orders yet')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    itemCount: _orders.length,
                    itemBuilder: (_, index) {
                      final order = _orders[index];
                      final color = _statusColor(order.status);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    OrderTrackingScreen(orderId: order.id),
                              ),
                            );
                            _loadOrders();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        order.orderNumber,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: Text(
                                        order.status,
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(order.restaurantName ?? 'Restaurant'),
                                const SizedBox(height: 4),
                                Text(
                                  'Total ฿${order.totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (order.createdAt != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    order.createdAt!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => OrderTrackingScreen(
                                            orderId: order.id,
                                          ),
                                        ),
                                      );
                                      _loadOrders();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    icon: const Icon(Icons.visibility_outlined),
                                    label: const Text(
                                      'View Order Details',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
