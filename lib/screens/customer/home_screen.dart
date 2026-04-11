import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/restaurant.dart';
import '../../services/api_service.dart';
import '../../utils/session_manager.dart';
import '../../screens/auth/login_screen.dart';
import 'restaurant_detail_screen.dart';
import 'order_history_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});
  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  List<Restaurant> _restaurants = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    try {
      final restaurants = await ApiService.fetchRestaurants();
      setState(() {
        _restaurants =
            restaurants.where((restaurant) => restaurant.isActive).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await SessionManager.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  List<Restaurant> get _filteredRestaurants {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _restaurants;
    return _restaurants.where((restaurant) {
      final haystack = [
        restaurant.name,
        restaurant.cuisineType,
        restaurant.address,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleRestaurants = _filteredRestaurants;

    void openOrders() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF9B2F), Color(0xFFF26A21)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: openOrders,
            icon: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
            label: const Text(
              'My Orders',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _restaurants.isEmpty
              ? RefreshIndicator(
                  onRefresh: _loadRestaurants,
                  child: ListView(
                    children: const [
                      SizedBox(height: 140),
                      Center(child: Text('No restaurants available right now')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRestaurants,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFF0DE), Color(0xFFFFFAF5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFF4DFC8)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF8A1D),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.lunch_dining,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Find your next meal',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Fresh local favorites, quick delivery, and bright flavors.',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            TextField(
                              decoration: InputDecoration(
                                hintText:
                                    'Search restaurants, cuisine, or area',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        onPressed: () =>
                                            setState(() => _searchQuery = ''),
                                        icon: const Icon(Icons.close),
                                      )
                                    : null,
                              ),
                              onChanged: (value) =>
                                  setState(() => _searchQuery = value),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Text(
                            'Popular Restaurants',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${visibleRestaurants.length} places',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (visibleRestaurants.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 80),
                          child: Center(
                            child: Text('No restaurants match your search'),
                          ),
                        )
                      else
                        ...visibleRestaurants.map((r) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 18),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RestaurantDetailScreen(restaurant: r),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 176,
                                    width: double.infinity,
                                    child: _imageBox(
                                      imageUrl: r.imageUrl,
                                      fallbackIcon: Icons.restaurant,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                r.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                            if (r.rating != null)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber
                                                      .withValues(alpha: 0.18),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.star,
                                                      color: Colors.amber,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      r.rating!
                                                          .toStringAsFixed(1),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            if (r.cuisineType?.isNotEmpty ==
                                                true)
                                              Chip(label: Text(r.cuisineType!)),
                                            if (r.estimatedDeliveryTime != null)
                                              Chip(
                                                label: Text(
                                                  '${r.estimatedDeliveryTime} mins',
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          r.address ?? 'Address unavailable',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }

  Widget _imageBox({
    required String? imageUrl,
    required IconData fallbackIcon,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.orange.withValues(alpha: 0.12),
        child: Center(
          child: Icon(fallbackIcon, size: 48, color: Colors.orange),
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
        color: Colors.orange.withValues(alpha: 0.12),
        child: Center(
          child: Icon(fallbackIcon, size: 48, color: Colors.orange),
        ),
      ),
    );
  }
}
