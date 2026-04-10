import 'package:flutter/material.dart';
import '../../models/restaurant.dart';
import '../../services/api_service.dart';
import 'cart_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Restaurant restaurant;
  const RestaurantDetailScreen({super.key, required this.restaurant});
  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  List<MenuItem> _menuItems = [];
  final Map<int, int> _cart = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    try {
      final items = await ApiService.fetchMenuItems(widget.restaurant.id);
      setState(() {
        _menuItems = items.where((item) => item.isAvailable).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  int get _totalItems => _cart.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurant.name),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.orange.withValues(alpha: 0.08),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.restaurant.cuisineType?.isNotEmpty == true)
                        Text(widget.restaurant.cuisineType!,
                            style: TextStyle(color: Colors.grey[700])),
                      if (widget.restaurant.description?.isNotEmpty ==
                          true) ...[
                        const SizedBox(height: 8),
                        Text(widget.restaurant.description!),
                      ],
                      if (widget.restaurant.deliveryFee != null ||
                          widget.restaurant.estimatedDeliveryTime != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          [
                            if (widget.restaurant.deliveryFee != null)
                              'Delivery ฿${widget.restaurant.deliveryFee!.toStringAsFixed(0)}',
                            if (widget.restaurant.estimatedDeliveryTime != null)
                              '${widget.restaurant.estimatedDeliveryTime} mins',
                          ].join(' • '),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: _menuItems.isEmpty
                      ? const Center(child: Text('No menu items available'))
                      : ListView.builder(
                          itemCount: _menuItems.length,
                          itemBuilder: (_, i) {
                            final item = _menuItems[i];
                            final qty = _cart[item.id] ?? 0;
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                title: Text(item.name),
                                subtitle: Text(
                                  [
                                    if (item.category?.isNotEmpty == true)
                                      item.category!,
                                    '฿${item.price.toStringAsFixed(0)}',
                                    if (item.description?.isNotEmpty == true)
                                      item.description!,
                                  ].join(' • '),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                      onPressed: qty > 0
                                          ? () => setState(() {
                                                if (qty == 1) {
                                                  _cart.remove(item.id);
                                                } else {
                                                  _cart[item.id] = qty - 1;
                                                }
                                              })
                                          : null,
                                    ),
                                    Text(
                                      '$qty',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        color: Colors.orange,
                                      ),
                                      onPressed: () => setState(
                                        () => _cart[item.id] = qty + 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: _totalItems > 0
          ? FloatingActionButton.extended(
              backgroundColor: Colors.orange,
              label: Text('View Cart ($_totalItems)'),
              icon: const Icon(Icons.shopping_cart),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CartScreen(
                          restaurant: widget.restaurant,
                          cart: _cart,
                          menuItems: _menuItems))))
          : null,
    );
  }
}
