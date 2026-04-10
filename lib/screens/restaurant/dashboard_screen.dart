import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../models/promotion.dart';
import '../../models/restaurant.dart';
import '../../services/api_service.dart';
import '../../services/local_storage_service.dart';
import '../../utils/session_manager.dart';
import '../auth/login_screen.dart';

class RestaurantDashboardScreen extends StatefulWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  State<RestaurantDashboardScreen> createState() =>
      _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends State<RestaurantDashboardScreen> {
  Restaurant? _restaurant;
  List<Order> _orders = [];
  List<MenuItem> _menuItems = [];
  List<MenuCategory> _categories = [];
  List<RestaurantReview> _reviews = [];
  List<Promotion> _promotions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final ownerId = await SessionManager.getUserId();
    if (ownerId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final restaurant = await ApiService.fetchOwnedRestaurant(ownerId);
      final results = await Future.wait([
        ApiService.fetchOrdersForRestaurant(restaurant.id),
        ApiService.fetchMenuItems(restaurant.id),
        ApiService.fetchCategories(restaurant.id),
        ApiService.fetchRestaurantReviews(restaurant.id),
        LocalStorageService.getRestaurantPromotions(restaurant.id),
        LocalStorageService.getLocalCategories(restaurant.id),
      ]);

      final remoteCategories = results[2] as List<MenuCategory>;
      final localCategories = results[5] as List<MenuCategory>;

      if (!mounted) return;
      setState(() {
        _restaurant = restaurant;
        _orders = results[0] as List<Order>;
        _menuItems = results[1] as List<MenuItem>;
        _categories = [...remoteCategories, ...localCategories];
        _reviews = results[3] as List<RestaurantReview>;
        _promotions = results[4] as List<Promotion>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load restaurant dashboard right now.'),
        ),
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

  Future<void> _updateOrderStatus(Order order, String status) async {
    try {
      await ApiService.updateOrderStatus(order.id, status);
      await _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update order status.')),
      );
    }
  }

  Future<void> _showMenuItemDialog({MenuItem? existing}) async {
    final restaurant = _restaurant;
    if (restaurant == null) return;

    final nameController = TextEditingController(text: existing?.name ?? '');
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');
    final priceController = TextEditingController(
      text: existing?.price.toStringAsFixed(2) ?? '',
    );
    final remoteCategories =
        _categories.where((category) => !category.isLocalOnly).toList();
    int? categoryId = existing?.categoryId ??
        (remoteCategories.isNotEmpty ? remoteCategories.first.id : null);
    bool isAvailable = existing?.isAvailable ?? true;

    final save = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title:
                  Text(existing == null ? 'Add Menu Item' : 'Edit Menu Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _field(nameController, 'Name'),
                    const SizedBox(height: 10),
                    _field(descriptionController, 'Description'),
                    const SizedBox(height: 10),
                    _field(
                      priceController,
                      'Price',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: _categories
                              .any((category) => category.id == categoryId)
                          ? categoryId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: remoteCategories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category.id,
                              child: Text(category.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => categoryId = value),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      value: isAvailable,
                      activeThumbColor: Colors.orange,
                      title: const Text('Available'),
                      onChanged: (value) => setState(() => isAvailable = value),
                    ),
                  ],
                ),
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
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (save != true || categoryId == null) return;

    final payload = {
      'name': nameController.text.trim(),
      'description': descriptionController.text.trim(),
      'price': double.tryParse(priceController.text.trim()) ?? 0,
      'categoryId': categoryId,
      'isAvailable': isAvailable,
    };

    try {
      if (existing == null) {
        await ApiService.addMenuItem(restaurant.id, payload);
      } else {
        await ApiService.updateMenuItem(restaurant.id, existing.id, payload);
      }
      await _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save menu item.')),
      );
    }
  }

  Future<void> _deleteMenuItem(MenuItem item) async {
    final restaurant = _restaurant;
    if (restaurant == null) return;
    try {
      await ApiService.deleteMenuItem(restaurant.id, item.id);
      await _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete this menu item.')),
      );
    }
  }

  Future<void> _showCategoryDialog() async {
    final restaurant = _restaurant;
    if (restaurant == null) return;

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Mobile Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(nameController, 'Name'),
            const SizedBox(height: 10),
            _field(descriptionController, 'Description'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (save != true || nameController.text.trim().isEmpty) return;

    final localCategories =
        _categories.where((item) => item.isLocalOnly).toList()
          ..add(
            MenuCategory(
              id: DateTime.now().millisecondsSinceEpoch,
              restaurantId: restaurant.id,
              name: nameController.text.trim(),
              description: descriptionController.text.trim(),
              isLocalOnly: true,
            ),
          );

    await LocalStorageService.saveLocalCategories(
        restaurant.id, localCategories);
    await _loadData();
  }

  Future<void> _removeLocalCategory(MenuCategory category) async {
    final restaurant = _restaurant;
    if (restaurant == null) return;
    final localCategories = _categories
        .where((item) => item.isLocalOnly && item.id != category.id)
        .toList();
    await LocalStorageService.saveLocalCategories(
        restaurant.id, localCategories);
    await _loadData();
  }

  Future<void> _showPromotionDialog() async {
    final restaurant = _restaurant;
    if (restaurant == null) return;

    final titleController = TextEditingController();
    final codeController = TextEditingController();
    final descriptionController = TextEditingController();
    final discountController = TextEditingController();

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Promotion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(titleController, 'Title'),
            const SizedBox(height: 10),
            _field(codeController, 'Code'),
            const SizedBox(height: 10),
            _field(descriptionController, 'Description'),
            const SizedBox(height: 10),
            _field(
              discountController,
              'Discount %',
              keyboardType: TextInputType.number,
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (save != true) return;

    final updated = [
      ..._promotions,
      Promotion(
        id: 'rest_${DateTime.now().millisecondsSinceEpoch}',
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        code: codeController.text.trim().toUpperCase(),
        discountPercent: double.tryParse(discountController.text.trim()) ?? 0,
        maxUses: 1000,
        currentUses: 0,
        validFrom: DateTime.now().toIso8601String().split('T').first,
        validUntil: DateTime.now()
            .add(const Duration(days: 30))
            .toIso8601String()
            .split('T')
            .first,
        targetGroup: 'all',
        active: true,
      ),
    ];

    await LocalStorageService.saveRestaurantPromotions(restaurant.id, updated);
    setState(() => _promotions = updated);
  }

  Future<void> _togglePromotion(Promotion promotion) async {
    final restaurant = _restaurant;
    if (restaurant == null) return;
    final updated = _promotions
        .map((item) => item.id == promotion.id
            ? item.copyWith(active: !item.active)
            : item)
        .toList();
    await LocalStorageService.saveRestaurantPromotions(restaurant.id, updated);
    setState(() => _promotions = updated);
  }

  Future<void> _deletePromotion(Promotion promotion) async {
    final restaurant = _restaurant;
    if (restaurant == null) return;
    final updated =
        _promotions.where((item) => item.id != promotion.id).toList();
    await LocalStorageService.saveRestaurantPromotions(restaurant.id, updated);
    setState(() => _promotions = updated);
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = _restaurant;
    final pendingOrders =
        _orders.where((order) => order.status != 'DELIVERED').length;
    final completedOrders =
        _orders.where((order) => order.status == 'DELIVERED').length;
    final revenue = _orders
        .where((order) => order.status == 'DELIVERED')
        .fold<double>(0, (sum, order) => sum + order.totalAmount);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(restaurant?.name ?? 'Restaurant Dashboard'),
          backgroundColor: Colors.orange,
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Orders'),
              Tab(text: 'Menu'),
              Tab(text: 'Categories'),
              Tab(text: 'Promotions'),
            ],
          ),
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
            : TabBarView(
                children: [
                  RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _metricCard('Pending Orders', '$pendingOrders',
                            Icons.receipt_long_outlined),
                        _metricCard('Delivered Orders', '$completedOrders',
                            Icons.check_circle_outline),
                        _metricCard('Revenue', '฿${revenue.toStringAsFixed(2)}',
                            Icons.payments_outlined),
                        _metricCard('Reviews', '${_reviews.length}',
                            Icons.star_border_outlined),
                        if (_reviews.isNotEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Recent Reviews',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ..._reviews.take(3).map((review) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: Text(
                                          '${review.customerName}: ${review.rating}/5 ${review.reviewText ?? ''}',
                                        ),
                                      )),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _orders.length,
                      itemBuilder: (_, index) {
                        final order = _orders[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.orderNumber,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text('Status: ${order.status}'),
                                Text(
                                  'Total: ฿${order.totalAmount.toStringAsFixed(2)}',
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (order.status == 'PENDING')
                                      _statusButton(
                                        'Confirm',
                                        Colors.orange,
                                        () => _updateOrderStatus(
                                          order,
                                          'CONFIRMED',
                                        ),
                                      ),
                                    if (order.status == 'CONFIRMED')
                                      _statusButton(
                                        'Preparing',
                                        Colors.deepOrange,
                                        () => _updateOrderStatus(
                                          order,
                                          'PREPARING',
                                        ),
                                      ),
                                    if (order.status == 'PREPARING')
                                      _statusButton(
                                        'Ready for Pickup',
                                        Colors.green,
                                        () => _updateOrderStatus(
                                          order,
                                          'READY_FOR_PICKUP',
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _categories
                                    .where((category) => !category.isLocalOnly)
                                    .isEmpty
                                ? null
                                : () => _showMenuItemDialog(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text(
                              'Add Menu Item',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _menuItems.length,
                          itemBuilder: (_, index) {
                            final item = _menuItems[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text(item.name),
                                subtitle: Text(
                                  '${item.category ?? 'No category'} • ฿${item.price.toStringAsFixed(2)}',
                                ),
                                trailing: Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      onPressed: () =>
                                          _showMenuItemDialog(existing: item),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteMenuItem(item),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
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
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showCategoryDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text(
                              'Add Category',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _categories.length,
                          itemBuilder: (_, index) {
                            final category = _categories[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text(category.name),
                                subtitle: Text(
                                  category.description?.isNotEmpty == true
                                      ? category.description!
                                      : category.isLocalOnly
                                          ? 'Local mobile category'
                                          : 'Server category',
                                ),
                                trailing: category.isLocalOnly
                                    ? IconButton(
                                        onPressed: () =>
                                            _removeLocalCategory(category),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                      )
                                    : const Icon(Icons.cloud_done_outlined),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showPromotionDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            icon:
                                const Icon(Icons.campaign, color: Colors.white),
                            label: const Text(
                              'Create Promotion',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _promotions.isEmpty
                            ? const Center(child: Text('No promotions yet'))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: _promotions.length,
                                itemBuilder: (_, index) {
                                  final promotion = _promotions[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  promotion.title,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              Chip(
                                                label: Text(
                                                  promotion.active
                                                      ? 'Active'
                                                      : 'Inactive',
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                              '${promotion.code} • ${promotion.discountPercent.toStringAsFixed(0)}% off'),
                                          const SizedBox(height: 6),
                                          Text(promotion.description),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: () =>
                                                      _togglePromotion(
                                                          promotion),
                                                  child: Text(
                                                    promotion.active
                                                        ? 'Deactivate'
                                                        : 'Activate',
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              IconButton(
                                                onPressed: () =>
                                                    _deletePromotion(promotion),
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
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
                ],
              ),
      ),
    );
  }

  Widget _metricCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withValues(alpha: 0.15),
          child: Icon(icon, color: Colors.orange),
        ),
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _statusButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: color),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}
