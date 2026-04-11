import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/api_service.dart';
import '../../utils/session_manager.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Order? _order;
  bool _isLoading = true;
  Timer? _trackingTimer;
  _TrackingSnapshot? _trackingSnapshot;
  int _trackingStep = 0;
  bool _arrivalPromptShown = false;

  static const _statusOrder = [
    'PENDING',
    'CONFIRMED',
    'PREPARING',
    'READY_FOR_PICKUP',
    'PICKED_UP',
    'DELIVERED',
  ];

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    try {
      final order = await ApiService.fetchOrder(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _isLoading = false;
      });
      _syncTracking(order);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load this order right now.')),
      );
    }
  }

  void _syncTracking(Order order) {
    if (order.status == 'PICKED_UP') {
      _trackingSnapshot = _buildTrackingSnapshot(order, _trackingStep);
      _trackingTimer ??= Timer.periodic(const Duration(seconds: 5), (_) {
        final currentOrder = _order;
        if (currentOrder == null || currentOrder.status != 'PICKED_UP') return;
        setState(() {
          _trackingStep = (_trackingStep + 1).clamp(0, 8);
          _trackingSnapshot =
              _buildTrackingSnapshot(currentOrder, _trackingStep);
        });
        if (_trackingSnapshot?.arrived == true && !_arrivalPromptShown) {
          _arrivalPromptShown = true;
          _showArrivalPrompt();
        }
      });
    } else if (order.status == 'DELIVERED') {
      _trackingTimer?.cancel();
      _trackingTimer = null;
      _trackingSnapshot = _buildTrackingSnapshot(order, 8, delivered: true);
    } else {
      _trackingTimer?.cancel();
      _trackingTimer = null;
      _trackingStep = 0;
      _trackingSnapshot = null;
      _arrivalPromptShown = false;
    }
  }

  _TrackingSnapshot _buildTrackingSnapshot(
    Order order,
    int step, {
    bool delivered = false,
  }) {
    final customer = _Point(
      order.deliveryLatitude ?? 13.7683,
      order.deliveryLongitude ?? 100.5128,
    );

    final seed = order.id % 4;
    final restaurant = _Point(
      customer.lat - (0.026 + seed * 0.003),
      customer.lng - (0.015 + seed * 0.0022),
    );

    if (delivered) {
      return _TrackingSnapshot(
        restaurant: restaurant,
        customer: customer,
        rider: customer,
        remainingKm: 0,
        etaMinutes: 0,
        arrived: true,
        phaseLabel: 'Delivered',
      );
    }

    const totalSteps = 8;
    final progress = (step / totalSteps).clamp(0.0, 1.0);
    final rider = _Point(
      restaurant.lat + ((customer.lat - restaurant.lat) * progress),
      restaurant.lng + ((customer.lng - restaurant.lng) * progress),
    );
    final remainingKm = _distanceKm(rider, customer);
    final etaMinutes = math.max((remainingKm / 0.65).ceil(), 1);
    final arrived = remainingKm <= 0.15;
    final phaseLabel = arrived
        ? 'Rider arrived'
        : progress >= 0.75
            ? 'Rider is nearby'
            : progress >= 0.2
                ? 'Rider is on the way'
                : 'Pickup completed';

    return _TrackingSnapshot(
      restaurant: restaurant,
      customer: customer,
      rider: rider,
      remainingKm: remainingKm,
      etaMinutes: arrived ? 0 : etaMinutes,
      arrived: arrived,
      phaseLabel: phaseLabel,
    );
  }

  double _distanceKm(_Point start, _Point end) {
    const earthRadiusKm = 6371;
    final dLat = _degToRad(end.lat - start.lat);
    final dLng = _degToRad(end.lng - start.lng);
    final lat1 = _degToRad(start.lat);
    final lat2 = _degToRad(end.lat);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLng / 2) *
            math.sin(dLng / 2) *
            math.cos(lat1) *
            math.cos(lat2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double degrees) => degrees * math.pi / 180;

  Future<void> _showArrivalPrompt() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rider Arrived'),
        content: const Text(
          'The rider has reached your delivery location. The UI now treats the order as arrived.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder() async {
    final order = _order;
    if (order == null) return;

    try {
      final response = await ApiService.cancelOrder(order.id);
      if (response.statusCode >= 400) {
        throw Exception();
      }
      await _loadOrder();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to cancel this order.')),
      );
    }
  }

  Future<void> _showRestaurantReviewDialog() async {
    final order = _order;
    final customerId = await SessionManager.getUserId();
    if (order == null || customerId == null) return;
    if (!mounted) return;

    int rating = order.restaurantRating ?? 5;
    final controller = TextEditingController(
      text: order.restaurantReviewText ?? '',
    );

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Rate Restaurant'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 4,
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      return IconButton(
                        onPressed: () => setState(() => rating = value),
                        icon: Icon(
                          value <= rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                      );
                    }),
                  ),
                  TextField(
                    controller: controller,
                    minLines: 3,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Review',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (submitted != true) return;

    try {
      final response = await ApiService.submitRestaurantReview(
        order.restaurantId,
        {
          'orderId': order.id,
          'customerId': customerId,
          'rating': rating,
          'reviewText': controller.text.trim(),
        },
      );
      if (response.statusCode >= 400) throw Exception();
      await _loadOrder();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant review submitted.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to submit your review.')),
      );
    }
  }

  String _statusLabel(String status) {
    return status.replaceAll('_', ' ');
  }

  int _progressIndex(String status) {
    final index = _statusOrder.indexOf(status);
    return index < 0 ? 0 : index;
  }

  String _deliveryStatusMessage(String status) {
    switch (status) {
      case 'PENDING':
        return 'Your order has been placed and is waiting for restaurant confirmation.';
      case 'CONFIRMED':
        return 'The restaurant confirmed your order.';
      case 'PREPARING':
        return 'The restaurant is preparing your food.';
      case 'READY_FOR_PICKUP':
        return 'Your order is ready and waiting for a rider.';
      case 'PICKED_UP':
        return _trackingSnapshot?.arrived == true
            ? 'The rider has reached your area.'
            : 'A rider picked up your order and is on the way.';
      case 'DELIVERED':
        return 'Your order has been delivered.';
      case 'CANCELLED':
        return 'This order was cancelled.';
      default:
        return 'Order status updated.';
    }
  }

  String _trackingStatusLabel(Order order) {
    if (order.status == 'PICKED_UP' && _trackingSnapshot?.arrived == true) {
      return 'Arrived';
    }
    return _statusLabel(order.status);
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final tracking = _trackingSnapshot;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            )
          : order == null
              ? const Center(child: Text('Order not found'))
              : RefreshIndicator(
                  onRefresh: _loadOrder,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.orderNumber,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(order.restaurantName ?? 'Restaurant'),
                              const SizedBox(height: 16),
                              LinearProgressIndicator(
                                value: order.status == 'CANCELLED'
                                    ? 0
                                    : (_progressIndex(order.status) + 1) /
                                        _statusOrder.length,
                                backgroundColor: Colors.grey[200],
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _statusOrder.map((status) {
                                  final reached =
                                      _progressIndex(order.status) >=
                                          _progressIndex(status);
                                  return Chip(
                                    backgroundColor: reached
                                        ? Colors.orange.withValues(alpha: 0.12)
                                        : Colors.grey[100],
                                    label: Text(_statusLabel(status)),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          leading: const Icon(
                            Icons.delivery_dining,
                            color: Colors.orange,
                          ),
                          title: const Text('Delivery Status'),
                          subtitle: Text(_deliveryStatusMessage(order.status)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (tracking != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _trackingStatCard(
                                'Status',
                                _trackingStatusLabel(order),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _trackingStatCard(
                                'Ordered At',
                                order.createdAt ?? '-',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _trackingStatCard(
                                'ETA',
                                tracking.arrived
                                    ? '0 min'
                                    : '${tracking.etaMinutes} min',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _trackingStatCard(
                                'Route Distance',
                                '${tracking.remainingKm.toStringAsFixed(2)} km',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _MockTrackingMap(snapshot: tracking),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _gpsCard(
                                'Restaurant GPS',
                                tracking.restaurant,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _gpsCard(
                                'Rider GPS',
                                tracking.rider,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _gpsCard(
                                'Destination GPS',
                                tracking.customer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Delivery Details',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_outlined),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      order.deliveryAddress ??
                                          'No delivery address provided',
                                    ),
                                  ),
                                ],
                              ),
                              if (order.specialInstructions != null &&
                                  order.specialInstructions!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.sticky_note_2_outlined),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(order.specialInstructions!),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Items',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...order.orderItems.map((item) {
                                final name = item.menuItemName.isNotEmpty
                                    ? item.menuItemName
                                    : 'Item #${item.id}';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text('$name x${item.quantity}'),
                                      ),
                                      Text(
                                        '฿${item.totalPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const Divider(),
                              Row(
                                children: [
                                  const Text('Delivery Fee'),
                                  const Spacer(),
                                  Text(
                                    '฿${order.deliveryFee.toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Text(
                                    'Total',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '฿${order.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (order.status == 'PENDING' ||
                          order.status == 'CONFIRMED')
                        Padding(
                          padding: const EdgeInsets.only(top: 18, bottom: 14),
                          child: OutlinedButton.icon(
                            onPressed: _cancelOrder,
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancel Order'),
                          ),
                        ),
                      if (order.status == 'DELIVERED' &&
                          order.restaurantReviewId == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 18, bottom: 14),
                          child: ElevatedButton.icon(
                            onPressed: _showRestaurantReviewDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            icon: const Icon(
                              Icons.storefront,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Rate Restaurant',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      if (order.status == 'DELIVERED') const SizedBox.shrink(),
                      if (order.restaurantReviewId != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Card(
                            color: Colors.green.withValues(alpha: 0.08),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(Icons.reviews_outlined),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Restaurant rating: ${order.restaurantRating ?? 0}/5',
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          order.restaurantReviewText ??
                                              'No comment',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _trackingStatCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gpsCard(String title, _Point point) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${point.lat.toStringAsFixed(4)}, ${point.lng.toStringAsFixed(4)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockTrackingMap extends StatelessWidget {
  final _TrackingSnapshot snapshot;

  const _MockTrackingMap({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Tracking Map',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Updates every 5 seconds with simulated GPS coordinates',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: snapshot.arrived ? Colors.green : Colors.teal,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    snapshot.phaseLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                const height = 320.0;
                const restaurantOffset = Offset(0.22, 0.74);
                const customerOffset = Offset(0.74, 0.28);
                final riderProgress = snapshot.totalDistanceKm == 0
                    ? 1.0
                    : 1 -
                        (snapshot.remainingKm / snapshot.totalDistanceKm)
                            .clamp(0.0, 1.0);
                final riderOffset = Offset(
                  restaurantOffset.dx +
                      ((customerOffset.dx - restaurantOffset.dx) *
                          riderProgress),
                  restaurantOffset.dy +
                      ((customerOffset.dy - restaurantOffset.dy) *
                          riderProgress),
                );

                Offset pixel(Offset normalized) =>
                    Offset(normalized.dx * width, normalized.dy * height);

                return Container(
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF8FBFF), Color(0xFFEFF5FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _GridPainter(),
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _RoutePainter(
                            restaurant: pixel(restaurantOffset),
                            rider: pixel(riderOffset),
                            customer: pixel(customerOffset),
                          ),
                        ),
                      ),
                      _marker(
                        pixel(restaurantOffset),
                        Colors.amber,
                        Icons.storefront,
                        'Restaurant',
                        textColor: Colors.black87,
                      ),
                      _marker(
                        pixel(customerOffset),
                        const Color(0xFFEF3A5D),
                        Icons.location_on,
                        'Your Address',
                      ),
                      _marker(
                        pixel(riderOffset),
                        const Color(0xFF4FB2FF),
                        Icons.two_wheeler,
                        'Rider',
                        textColor: Colors.black87,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _marker(
    Offset position,
    Color color,
    IconData icon,
    String label, {
    Color textColor = Colors.white,
  }) {
    return Positioned(
      left: position.dx - 34,
      top: position.dy - 28,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: textColor, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueGrey.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    const gap = 32.0;
    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoutePainter extends CustomPainter {
  final Offset restaurant;
  final Offset rider;
  final Offset customer;

  _RoutePainter({
    required this.restaurant,
    required this.rider,
    required this.customer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final completed = Paint()
      ..color = Colors.green
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(restaurant, rider, completed);

    final dashPaint = Paint()
      ..color = const Color(0xFFBBD0FF)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const dash = 10.0;
    const gap = 8.0;
    final dx = customer.dx - rider.dx;
    final dy = customer.dy - rider.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance == 0) return;
    final unitX = dx / distance;
    final unitY = dy / distance;
    double drawn = 0;
    while (drawn < distance) {
      final start = drawn;
      final end = math.min(drawn + dash, distance);
      canvas.drawLine(
        Offset(rider.dx + unitX * start, rider.dy + unitY * start),
        Offset(rider.dx + unitX * end, rider.dy + unitY * end),
        dashPaint,
      );
      drawn += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.rider != rider;
  }
}

class _TrackingSnapshot {
  final _Point restaurant;
  final _Point customer;
  final _Point rider;
  final double remainingKm;
  final int etaMinutes;
  final bool arrived;
  final String phaseLabel;

  const _TrackingSnapshot({
    required this.restaurant,
    required this.customer,
    required this.rider,
    required this.remainingKm,
    required this.etaMinutes,
    required this.arrived,
    required this.phaseLabel,
  });

  double get totalDistanceKm {
    const earthRadiusKm = 6371;
    final dLat = (customer.lat - restaurant.lat) * math.pi / 180;
    final dLng = (customer.lng - restaurant.lng) * math.pi / 180;
    final lat1 = restaurant.lat * math.pi / 180;
    final lat2 = customer.lat * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLng / 2) *
            math.sin(dLng / 2) *
            math.cos(lat1) *
            math.cos(lat2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }
}

class _Point {
  final double lat;
  final double lng;

  const _Point(this.lat, this.lng);
}
