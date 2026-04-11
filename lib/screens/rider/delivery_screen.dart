import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/order.dart';
import '../../models/restaurant.dart';
import '../../services/api_service.dart';
import '../../utils/session_manager.dart';
import '../../widgets/shared_ui.dart';

class DeliveryScreen extends StatefulWidget {
  final int orderId;

  const DeliveryScreen({super.key, required this.orderId});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  Order? _order;
  Restaurant? _restaurant;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final order = await ApiService.fetchOrder(widget.orderId);
      final restaurant = await ApiService.fetchRestaurant(order.restaurantId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _restaurant = restaurant;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _markDelivered() async {
    final riderId = await SessionManager.getUserId();
    final order = _order;
    if (riderId == null || order == null) return;

    try {
      await ApiService.confirmDelivery(riderId, order.id);
      await _loadOrder();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery confirmed.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to confirm delivery.')),
      );
    }
  }

  Future<void> _openMap({
    required String label,
    required double? latitude,
    required double? longitude,
    String? query,
  }) async {
    final String url;
    if (latitude != null && longitude != null) {
      url =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    } else if (query != null && query.trim().isNotEmpty) {
      url =
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No map location available for $label.')),
      );
      return;
    }

    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open Google Maps for $label.')),
      );
    }
  }

  Future<void> _showCustomerContact() async {
    final order = _order;
    if (order == null) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customer Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order.customerName ?? 'Customer'),
            const SizedBox(height: 8),
            Text(order.customerPhoneNumber?.isNotEmpty == true
                ? order.customerPhoneNumber!
                : 'Phone number not available'),
            if (order.deliveryAddress?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(order.deliveryAddress!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _orderItemLabel(OrderItem item) {
    final itemName =
        item.menuItemName.isNotEmpty ? item.menuItemName : 'Item #${item.id}';
    return '$itemName x${item.quantity}';
  }

  Widget _buildHeaderCard(Order order) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        title: Text(
          order.orderNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(order.restaurantName ?? 'Restaurant'),
        trailing: Chip(label: Text(order.status)),
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required List<Widget> details,
    required List<Widget> actions,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            ...details,
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Items',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...order.orderItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(child: Text(_orderItemLabel(item))),
                    Text('฿${item.totalPrice.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryButton(Order order) {
    final delivered = order.status == 'DELIVERED';
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: delivered ? null : _markDelivered,
        style: ElevatedButton.styleFrom(
          backgroundColor: delivered ? Colors.grey.shade300 : Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: const Icon(Icons.check_circle, color: Colors.white),
        label: Text(
          delivered ? 'Already Delivered' : 'Confirm Delivery',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final restaurant = _restaurant;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Details'),
        backgroundColor: Colors.orange,
      ),
      body: _loading
          ? const AppLoadingView()
          : order == null
              ? const Center(child: Text('Order not found'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  children: [
                    _buildHeaderCard(order),
                    const SizedBox(height: 16),
                    _buildDetailCard(
                      title: 'Pickup Details',
                      details: [
                        Text(restaurant?.name ?? order.restaurantName ?? ''),
                        if (restaurant?.address?.isNotEmpty == true) ...[
                          const SizedBox(height: 6),
                          Text(restaurant!.address!),
                        ],
                        if (restaurant?.phoneNumber?.isNotEmpty == true) ...[
                          const SizedBox(height: 6),
                          Text('Restaurant phone: ${restaurant!.phoneNumber!}'),
                        ],
                      ],
                      actions: [
                        OutlinedButton.icon(
                          onPressed: () => _openMap(
                            label: 'restaurant',
                            latitude: restaurant?.latitude,
                            longitude: restaurant?.longitude,
                            query: restaurant?.address,
                          ),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Open Restaurant Map'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailCard(
                      title: 'Drop-off Address',
                      details: [
                        Text(order.deliveryAddress ?? 'No address'),
                        if (order.deliveryLatitude != null &&
                            order.deliveryLongitude != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'GPS: ${order.deliveryLatitude}, ${order.deliveryLongitude}',
                          ),
                        ],
                      ],
                      actions: [
                        OutlinedButton.icon(
                          onPressed: () => _openMap(
                            label: 'customer',
                            latitude: order.deliveryLatitude,
                            longitude: order.deliveryLongitude,
                            query: order.deliveryAddress,
                          ),
                          icon: const Icon(Icons.place_outlined),
                          label: const Text('Open Customer Map'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _showCustomerContact,
                          icon: const Icon(Icons.contact_phone_outlined),
                          label: const Text('Customer Contact'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildItemsCard(order),
                    const SizedBox(height: 18),
                    _buildDeliveryButton(order),
                  ],
                ),
    );
  }
}
