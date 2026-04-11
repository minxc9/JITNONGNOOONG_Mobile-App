import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/api_service.dart';
import '../../utils/session_manager.dart';
import '../auth/login_screen.dart';
import 'delivery_screen.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  List<Order> _availableOrders = [];
  List<Order> _myOrders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final riderId = await SessionManager.getUserId();
    if (riderId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final available = await ApiService.fetchAvailableOrders();
      final mine = await ApiService.fetchRiderOrders(riderId);
      if (!mounted) return;
      setState(() {
        _availableOrders = available;
        _myOrders = mine;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load rider orders right now.')),
      );
    }
  }

  Future<void> _acceptOrder(int orderId) async {
    final riderId = await SessionManager.getUserId();
    if (riderId == null) return;
    try {
      await ApiService.acceptOrder(riderId, orderId);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order accepted.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to accept this order.')),
      );
    }
  }

  Future<void> _logout() async {
    await SessionManager.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rider Dashboard'),
          backgroundColor: Colors.orange,
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: Container(
                height: 54,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const TabBar(
                  tabs: [
                    Tab(text: 'Available'),
                    Tab(text: 'My Deliveries'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
            : TabBarView(
                children: [
                  _ordersList(
                    orders: _availableOrders,
                    emptyMessage: 'No orders waiting for pickup',
                    actionLabel: 'Accept',
                    actionColor: Colors.orange,
                    onAction: (order) => _acceptOrder(order.id),
                  ),
                  _ordersList(
                    orders: _myOrders,
                    emptyMessage: 'No deliveries assigned yet',
                    actionLabel: 'View Delivery',
                    actionColor: Colors.green,
                    onAction: (order) async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeliveryScreen(orderId: order.id),
                        ),
                      );
                      _loadData();
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget _ordersList({
    required List<Order> orders,
    required String emptyMessage,
    required String actionLabel,
    required Color actionColor,
    required ValueChanged<Order> onAction,
  }) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          children: [
            const SizedBox(height: 140),
            Center(child: Text(emptyMessage)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        itemCount: orders.length,
        itemBuilder: (_, index) {
          final order = orders[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(order.restaurantName ?? 'Restaurant'),
                  const SizedBox(height: 4),
                  Text(order.deliveryAddress ?? 'No address'),
                  const SizedBox(height: 4),
                  Text('Status: ${order.status}'),
                  const SizedBox(height: 4),
                  Text('Total: ฿${order.totalAmount.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => onAction(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: actionColor,
                      ),
                      child: Text(
                        actionLabel,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
