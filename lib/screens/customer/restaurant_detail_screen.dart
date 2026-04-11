import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  void _updateQuantity(MenuItem item, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cart.remove(item.id);
      } else {
        _cart[item.id] = quantity;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurant.name),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeroImage()),
                SliverToBoxAdapter(child: _buildRestaurantSummary()),
                _menuItems.isEmpty ? _buildEmptyMenuState() : _buildMenuList(),
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

  Widget _buildHeroImage() {
    return SizedBox(
      width: double.infinity,
      height: 220,
      child: _imageBox(
        imageUrl: widget.restaurant.imageUrl,
        fallbackIcon: Icons.restaurant_menu,
      ),
    );
  }

  Widget _buildRestaurantSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.orange.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.restaurant.cuisineType?.isNotEmpty == true)
            Text(
              widget.restaurant.cuisineType!,
              style: TextStyle(color: Colors.grey[700]),
            ),
          if (widget.restaurant.description?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(widget.restaurant.description!),
          ],
          if (_restaurantMetaText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_restaurantMetaText),
          ],
          const SizedBox(height: 14),
          const Text(
            'Menu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String get _restaurantMetaText {
    final details = <String>[
      if (widget.restaurant.deliveryFee != null)
        'Delivery ฿${widget.restaurant.deliveryFee!.toStringAsFixed(0)}',
      if (widget.restaurant.estimatedDeliveryTime != null)
        '${widget.restaurant.estimatedDeliveryTime} mins',
    ];
    return details.join(' • ');
  }

  Widget _buildEmptyMenuState() {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(child: Text('No menu items available')),
    );
  }

  Widget _buildMenuList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      sliver: SliverList.builder(
        itemCount: _menuItems.length,
        itemBuilder: (_, index) => _buildMenuItemCard(_menuItems[index]),
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    final quantity = _cart[item.id] ?? 0;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 92,
                height: 92,
                child: _imageBox(
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
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(_menuItemSummary(item)),
                  if (item.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: quantity > 0
                            ? () => _updateQuantity(item, quantity - 1)
                            : null,
                      ),
                      Text(
                        '$quantity',
                        style: const TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.orange,
                        ),
                        onPressed: () => _updateQuantity(item, quantity + 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _menuItemSummary(MenuItem item) {
    final details = <String>[
      if (item.category?.isNotEmpty == true) item.category!,
      '฿${item.price.toStringAsFixed(0)}',
    ];
    return details.join(' • ');
  }

  Widget _imageBox({
    required String? imageUrl,
    required IconData fallbackIcon,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.orange.withValues(alpha: 0.10),
        child: Center(
          child: Icon(fallbackIcon, size: 42, color: Colors.orange),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        color: Colors.orange.withValues(alpha: 0.08),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        color: Colors.orange.withValues(alpha: 0.10),
        child: Center(
          child: Icon(fallbackIcon, size: 42, color: Colors.orange),
        ),
      ),
    );
  }
}
