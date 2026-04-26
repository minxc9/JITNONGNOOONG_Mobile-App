import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/api_service.dart';
import '../../utils/session_manager.dart';
import '../../widgets/shared_ui.dart';
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
  String _riderName = 'Rider';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final riderId = await SessionManager.getUserId();
    final riderName = await SessionManager.getUserName();
    if (riderId == null) {
      setState(() {
        _riderName =
            riderName?.trim().isNotEmpty == true ? riderName!.trim() : 'Rider';
        _loading = false;
      });
      return;
    }

    try {
      final available = await ApiService.fetchAvailableOrders();
      final mine = await ApiService.fetchRiderOrders(riderId);
      if (!mounted) return;
      setState(() {
        _availableOrders = available;
        _myOrders = mine;
        _riderName =
            riderName?.trim().isNotEmpty == true ? riderName!.trim() : 'Rider';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _riderName =
            riderName?.trim().isNotEmpty == true ? riderName!.trim() : 'Rider';
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load rider orders right now.')),
      );
    }
  }

  Future<void> _acceptOrder(Order order) async {
    final riderId = await SessionManager.getUserId();
    if (riderId == null) return;
    try {
      await ApiService.acceptOrder(riderId, order.id);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order accepted.')),
      );
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DeliveryScreen(orderId: order.id)),
      );
      _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to accept this order.')),
      );
    }
  }

  Future<void> _openDelivery(Order order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DeliveryScreen(orderId: order.id)),
    );
    _loadData();
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

  Order? get _activeDelivery {
    for (final order in _myOrders) {
      if (const {'PICKED_UP', 'OUT_FOR_DELIVERY', 'ON_THE_WAY'}
          .contains(order.status)) {
        return order;
      }
    }
    return null;
  }

  double get _todayEarnings {
    final today = DateTime.now();
    return _myOrders
        .where((order) =>
            order.status == 'DELIVERED' && _isSameDay(order.createdAt, today))
        .fold<double>(0, (sum, order) => sum + order.deliveryFee);
  }

  int get _completedTodayCount {
    final today = DateTime.now();
    return _myOrders
        .where((order) =>
            order.status == 'DELIVERED' && _isSameDay(order.createdAt, today))
        .length;
  }

  bool _isSameDay(String? timestamp, DateTime reference) {
    final parsed = DateTime.tryParse(timestamp ?? '');
    if (parsed == null) return false;
    final local = parsed.toLocal();
    return local.year == reference.year &&
        local.month == reference.month &&
        local.day == reference.day;
  }

  String _restaurantLabel(Order order) {
    final name = order.restaurantName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Restaurant #${order.restaurantId}';
  }

  String _customerLabel(Order order) {
    final name = order.customerName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Customer #${order.customerId}';
  }

  String _orderNumberLabel(Order order) {
    if (order.orderNumber.isNotEmpty) return '#${order.orderNumber}';
    return '#${order.id}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.orange,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Rider Portal',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _riderName,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Exit'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF8FAFC),
        child: _loading
            ? const AppLoadingView()
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                  children: [
                    _buildStatsSection(),
                    if (_activeDelivery != null) ...[
                      const SizedBox(height: 20),
                      _buildActiveDeliveryCard(_activeDelivery!),
                    ],
                    const SizedBox(height: 20),
                    _buildAvailableOrdersCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useThreeColumns = constraints.maxWidth >= 900;
        final useTwoColumns = constraints.maxWidth >= 600;
        final columns = useThreeColumns ? 3 : (useTwoColumns ? 2 : 1);
        final width = (constraints.maxWidth - ((columns - 1) * 16)) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _statCard(
              title: "Today's Earnings",
              value: '฿${_todayEarnings.toStringAsFixed(0)}',
              icon: Icons.attach_money_rounded,
              accentColor: const Color(0xFF16A34A),
              width: width,
            ),
            _statCard(
              title: 'Completed Today',
              value: '$_completedTodayCount',
              icon: Icons.inventory_2_outlined,
              accentColor: const Color(0xFF2563EB),
              width: width,
            ),
            _statCard(
              title: 'Active Delivery',
              value: _activeDelivery == null ? '0' : '1',
              icon: Icons.access_time_rounded,
              accentColor: const Color(0xFFF97316),
              width: width,
            ),
          ],
        );
      },
    );
  }

  Widget _buildActiveDeliveryCard(Order order) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFF97316), width: 2),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text(
                    'Active Delivery',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF97316),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'In Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Order ${_orderNumberLabel(order)}',
              style: TextStyle(
                color: Colors.blueGrey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _restaurantLabel(order),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Customer',
              style: TextStyle(
                color: Colors.blueGrey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _customerLabel(order),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            if (order.deliveryAddress?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_outlined,
                      color: Colors.blueGrey[500], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.deliveryAddress!,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openDelivery(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF07031A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'View Delivery Details',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableOrdersCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Orders Nearby',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            if (_availableOrders.isEmpty)
              _buildAvailableOrdersEmpty()
            else
              ..._availableOrders.map(_buildAvailableOrderItem),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableOrdersEmpty() {
    return SizedBox(
      width: double.infinity,
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 54,
              color: Colors.blueGrey[200],
            ),
            const SizedBox(height: 12),
            Text(
              'No available orders at the moment',
              style: TextStyle(
                color: Colors.blueGrey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'New orders will appear here',
              style: TextStyle(color: Colors.blueGrey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableOrderItem(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _restaurantLabel(order),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order ${_orderNumberLabel(order)}',
                      style: TextStyle(
                        color: Colors.blueGrey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Customer: ${_customerLabel(order)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '฿${order.deliveryFee.toStringAsFixed(0)} delivery fee',
                  style: const TextStyle(
                    color: Color(0xFF15803D),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (order.deliveryAddress?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined,
                    color: Colors.blueGrey[500], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.deliveryAddress!,
                    style: TextStyle(color: Colors.blueGrey[700]),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _acceptOrder(order),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF07031A),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Accept Order',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.blueGrey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
