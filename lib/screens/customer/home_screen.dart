import 'package:flutter/material.dart';
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
        backgroundColor: Colors.orange,
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
                    padding: const EdgeInsets.all(12),
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search restaurants, cuisine, or area',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                      const SizedBox(height: 12),
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
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Icon(
                                  Icons.restaurant,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                r.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  if (r.cuisineType?.isNotEmpty == true)
                                    r.cuisineType,
                                  if (r.address?.isNotEmpty == true) r.address,
                                ].whereType<String>().join(' • '),
                              ),
                              trailing: r.rating != null
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                        Text(r.rating!.toStringAsFixed(1)),
                                      ],
                                    )
                                  : null,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RestaurantDetailScreen(restaurant: r),
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}
