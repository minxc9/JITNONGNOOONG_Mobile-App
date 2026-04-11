import 'package:flutter/material.dart';

import '../../models/admin_stats.dart';
import '../../models/promotion.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/local_storage_service.dart';
import '../../utils/session_manager.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  OrderStats? _orderStats;
  RestaurantStats? _restaurantStats;
  List<User> _users = [];
  List<Promotion> _promotions = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.fetchAdminOrderStats(),
        ApiService.fetchAdminRestaurantStats(),
        LocalStorageService.getAdminUsers(),
        LocalStorageService.getAdminPromotions(),
      ]);

      if (!mounted) return;
      setState(() {
        _orderStats = results[0] as OrderStats;
        _restaurantStats = results[1] as RestaurantStats;
        _users = results[2] as List<User>;
        _promotions = results[3] as List<Promotion>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load admin data right now.')),
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

  Future<void> _toggleUser(User user) async {
    final updated = _users
        .map((item) => item.id == user.id
            ? User(
                id: item.id,
                name: item.name,
                email: item.email,
                role: item.role,
                phoneNumber: item.phoneNumber,
                isActive: !(item.isActive ?? true),
              )
            : item)
        .toList();
    await LocalStorageService.saveAdminUsers(updated);
    setState(() => _users = updated);
  }

  Future<void> _showPromotionDialog() async {
    final codeController = TextEditingController();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final discountController = TextEditingController();
    final maxUsesController = TextEditingController();
    final fromController = TextEditingController();
    final untilController = TextEditingController();
    String targetGroup = 'all';

    final save = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create Promotion'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _textField(codeController, 'Code'),
                    const SizedBox(height: 10),
                    _textField(titleController, 'Title'),
                    const SizedBox(height: 10),
                    _textField(descriptionController, 'Description'),
                    const SizedBox(height: 10),
                    _textField(
                      discountController,
                      'Discount %',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    _textField(
                      maxUsesController,
                      'Max Uses',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    _textField(fromController, 'Valid From (YYYY-MM-DD)'),
                    const SizedBox(height: 10),
                    _textField(untilController, 'Valid Until (YYYY-MM-DD)'),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: targetGroup,
                      decoration: const InputDecoration(
                        labelText: 'Target Group',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('All Users')),
                        DropdownMenuItem(
                            value: 'new', child: Text('New Users')),
                        DropdownMenuItem(
                            value: 'vip', child: Text('VIP Members')),
                      ],
                      onChanged: (value) =>
                          setState(() => targetGroup = value ?? 'all'),
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
                    'Create',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (save != true) return;

    final promotion = Promotion(
      id: 'promo_${DateTime.now().millisecondsSinceEpoch}',
      code: codeController.text.trim().toUpperCase(),
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      discountPercent: double.tryParse(discountController.text.trim()) ?? 0,
      maxUses: int.tryParse(maxUsesController.text.trim()) ?? 0,
      currentUses: 0,
      validFrom: fromController.text.trim(),
      validUntil: untilController.text.trim(),
      targetGroup: targetGroup,
      active: true,
    );

    final updated = [..._promotions, promotion];
    await LocalStorageService.saveAdminPromotions(updated);
    setState(() => _promotions = updated);
  }

  Future<void> _togglePromotion(Promotion promotion) async {
    final updated = _promotions
        .map((item) => item.id == promotion.id
            ? item.copyWith(active: !item.active)
            : item)
        .toList();
    await LocalStorageService.saveAdminPromotions(updated);
    setState(() => _promotions = updated);
  }

  Future<void> _deletePromotion(String id) async {
    final updated =
        _promotions.where((promotion) => promotion.id != id).toList();
    await LocalStorageService.saveAdminPromotions(updated);
    setState(() => _promotions = updated);
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users.where((user) {
      final query = _search.toLowerCase();
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.role.toLowerCase().contains(query);
    }).toList();

    final customers = _users.where((user) => user.role == 'CUSTOMER').length;
    final activeRiders = _users
        .where((user) => user.role == 'RIDER' && (user.isActive ?? true))
        .length;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
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
                    Tab(text: 'Overview'),
                    Tab(text: 'Accounts'),
                    Tab(text: 'Promotions'),
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
                  RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      children: [
                        _metricCard(
                          'Today\'s Orders',
                          '${_orderStats?.todayOrders ?? 0}',
                          Icons.shopping_bag_outlined,
                        ),
                        _metricCard(
                          'Month Revenue',
                          '฿${(_orderStats?.monthRevenue ?? 0).toStringAsFixed(2)}',
                          Icons.paid_outlined,
                        ),
                        _metricCard(
                          'Active Restaurants',
                          '${_restaurantStats?.activeRestaurants ?? 0}',
                          Icons.storefront_outlined,
                        ),
                        _metricCard(
                          'Active Riders',
                          '$activeRiders',
                          Icons.delivery_dining_outlined,
                        ),
                        _metricCard(
                          'Customers',
                          '$customers',
                          Icons.people_outline,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (value) => setState(() => _search = value),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Search accounts',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.builder(
                              itemCount: filteredUsers.length,
                              itemBuilder: (_, index) {
                                final user = filteredUsers[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 8,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.orange,
                                      child: Text(
                                        user.name.isEmpty
                                            ? '?'
                                            : user.name[0].toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                    title: Text(user.name),
                                    subtitle:
                                        Text('${user.email} • ${user.role}'),
                                    trailing: Switch(
                                      activeThumbColor: Colors.orange,
                                      value: user.isActive ?? true,
                                      onChanged: (_) => _toggleUser(user),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showPromotionDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            icon: const Icon(Icons.add_circle,
                                color: Colors.white),
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
                                  horizontal: 20,
                                ),
                                itemCount: _promotions.length,
                                itemBuilder: (_, index) {
                                  final promotion = _promotions[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
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
                                          const SizedBox(height: 6),
                                          Text(
                                              '${promotion.code} • ${promotion.targetGroup}'),
                                          const SizedBox(height: 6),
                                          Text(promotion.description),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Discount ${promotion.discountPercent.toStringAsFixed(0)}% • ${promotion.currentUses}/${promotion.maxUses} uses',
                                          ),
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
                                                    _deletePromotion(
                                                  promotion.id,
                                                ),
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

  Widget _textField(
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
}
