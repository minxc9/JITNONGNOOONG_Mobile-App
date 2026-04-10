import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/order.dart';
import '../../models/restaurant.dart';
import '../../services/api_service.dart';
import '../../utils/session_manager.dart';

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
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : order == null
              ? const Center(child: Text('Order not found'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: ListTile(
                        title: Text(
                          order.orderNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(order.restaurantName ?? 'Restaurant'),
                        trailing: Chip(label: Text(order.status)),
                      ),
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pickup Details',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                                restaurant?.name ?? order.restaurantName ?? ''),
                            if (restaurant?.address?.isNotEmpty == true) ...[
                              const SizedBox(height: 6),
                              Text(restaurant!.address!),
                            ],
                            if (restaurant?.phoneNumber?.isNotEmpty ==
                                true) ...[
                              const SizedBox(height: 6),
                              Text(
                                  'Restaurant phone: ${restaurant!.phoneNumber!}'),
                            ],
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
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
                          ],
                        ),
                      ),
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Drop-off Address',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(order.deliveryAddress ?? 'No address'),
                            if (order.deliveryLatitude != null &&
                                order.deliveryLongitude != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'GPS: ${order.deliveryLatitude}, ${order.deliveryLongitude}',
                              ),
                            ],
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
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
                                  icon:
                                      const Icon(Icons.contact_phone_outlined),
                                  label: const Text('Customer Contact'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
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
                            ...order.orderItems.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.menuItemName.isNotEmpty ? item.menuItemName : 'Item #${item.id}'} x${item.quantity}',
                                      ),
                                    ),
                                    Text(
                                      '฿${item.totalPrice.toStringAsFixed(2)}',
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            order.status == 'DELIVERED' ? null : _markDelivered,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon:
                            const Icon(Icons.check_circle, color: Colors.white),
                        label: Text(
                          order.status == 'DELIVERED'
                              ? 'Already Delivered'
                              : 'Confirm Delivery',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
