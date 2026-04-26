import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/admin_stats.dart';
import '../../models/promotion.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/local_storage_service.dart';
import '../../utils/session_manager.dart';
import '../../widgets/shared_ui.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

enum _AdminAccountFilter {
  customers,
  restaurants,
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const _webOverviewOrderStats = OrderStats(
    todayOrders: 892,
    monthOrders: 0,
    totalOrders: 0,
    todayRevenue: 125430,
    monthRevenue: 3456789,
  );
  static const _webOverviewRestaurantStats = RestaurantStats(
    totalRestaurants: 456,
    activeRestaurants: 456,
  );
  static const _webFallbackCustomerCount = 15234;
  static const _webFallbackActiveRiderCount = 234;

  OrderStats? _orderStats;
  RestaurantStats? _restaurantStats;
  List<User> _users = [];
  List<Promotion> _promotions = [];
  int? _customerCountOverride;
  int? _activeRiderCountOverride;
  bool _usingFallbackUsers = false;
  bool _loading = true;
  String _search = '';
  _AdminAccountFilter _accountFilter = _AdminAccountFilter.customers;

  static const _weeklyRevenuePoints = [
    45000.0,
    52000.0,
    48000.0,
    61000.0,
    72000.0,
    95000.0,
    88000.0,
  ];
  static const _weeklyRevenueLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  List<User> _webFallbackUsers() {
    return [
      User(
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
        role: 'CUSTOMER',
        phoneNumber: '+66 81 234 5678',
        isActive: true,
      ),
      User(
        id: 2,
        name: 'Sarah Wilson',
        email: 'sarah@example.com',
        role: 'CUSTOMER',
        phoneNumber: '+66 82 345 6789',
        isActive: true,
      ),
      User(
        id: 3,
        name: 'Michael Brown',
        email: 'michael@example.com',
        role: 'CUSTOMER',
        phoneNumber: '+66 83 456 7890',
        isActive: false,
      ),
      User(
        id: 101,
        name: 'Bangkok Street Food',
        email: 'bangkok.street@example.com',
        role: 'RESTAURANT',
        phoneNumber: '+66 81 111 1111',
        isActive: true,
      ),
      User(
        id: 102,
        name: 'Sushi Master',
        email: 'sushi.master@example.com',
        role: 'RESTAURANT',
        phoneNumber: '+66 82 222 2222',
        isActive: true,
      ),
      User(
        id: 103,
        name: 'Pizza Paradise',
        email: 'pizza.paradise@example.com',
        role: 'RESTAURANT',
        phoneNumber: '+66 83 333 3333',
        isActive: true,
      ),
      User(
        id: 104,
        name: 'Green Garden',
        email: 'green.garden@example.com',
        role: 'RESTAURANT',
        phoneNumber: '+66 84 444 4444',
        isActive: false,
      ),
      User(
        id: 105,
        name: 'Ramen House',
        email: 'ramen.house@example.com',
        role: 'RESTAURANT',
        phoneNumber: '+66 85 555 5555',
        isActive: true,
      ),
      User(
        id: 106,
        name: 'Burger Bistro',
        email: 'burger.bistro@example.com',
        role: 'RESTAURANT',
        phoneNumber: '+66 86 666 6666',
        isActive: true,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    var hadError = false;
    const orderStats = _webOverviewOrderStats;
    const restaurantStats = _webOverviewRestaurantStats;
    var users = <User>[];
    var promotions = <Promotion>[];
    var customerCountOverride = _webFallbackCustomerCount;
    var activeRiderCountOverride = _webFallbackActiveRiderCount;
    var usingFallbackUsers = false;

    try {
      users = await ApiService.fetchUsers();
      if (users.isEmpty) {
        users = _webFallbackUsers();
        usingFallbackUsers = true;
      }
    } catch (_) {
      users = _webFallbackUsers();
      usingFallbackUsers = true;
    }

    try {
      promotions = await LocalStorageService.getAdminPromotions();
    } catch (_) {
      hadError = true;
    }

    if (!mounted) return;
    setState(() {
      _orderStats = orderStats;
      _restaurantStats = restaurantStats;
      _users = users;
      _promotions = promotions;
      _customerCountOverride = customerCountOverride;
      _activeRiderCountOverride = activeRiderCountOverride;
      _usingFallbackUsers = usingFallbackUsers;
      _loading = false;
    });

    if (hadError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Some admin data could not load.')),
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
    final isActive = !(user.isActive ?? true);
    final updated = _users
        .map((item) => item.id == user.id
            ? User(
                id: item.id,
                name: item.name,
                email: item.email,
                role: item.role,
                phoneNumber: item.phoneNumber,
                isActive: isActive,
              )
            : item)
        .toList();
    final previous = _users;
    setState(() => _users = updated);
    if (_usingFallbackUsers) return;
    try {
      final response = await ApiService.updateUserStatus(user.id, isActive);
      if (response.statusCode >= 400) {
        throw Exception('Unable to update user status');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _users = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update account right now.')),
      );
    }
  }

  void _deleteUser(User user) {
    setState(() {
      _users = _users.where((item) => item.id != user.id).toList();
    });
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
            ? item.copyWith(PromotionChanges(active: !item.active))
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

  List<User> get _filteredUsers {
    final query = _search.toLowerCase();
    final filterRole = _accountFilter == _AdminAccountFilter.customers
        ? 'CUSTOMER'
        : 'RESTAURANT';
    return _users.where((user) {
      if (user.role != filterRole) return false;
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.role.toLowerCase().contains(query);
    }).toList();
  }

  int get _customerCount =>
      _customerCountOverride ??
      _users.where((user) => user.role == 'CUSTOMER').length;

  int get _activeRiderCount {
    if (_activeRiderCountOverride != null) return _activeRiderCountOverride!;
    return _users
        .where((user) => user.role == 'RIDER' && (user.isActive ?? true))
        .length;
  }

  String _formatCount(int value) {
    final text = value.toString();
    return text.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
  }

  String _formatBaht(num value) => '฿${_formatCount(value.round())}';

  String _formatBahtThousands(num value) {
    return '฿${(value / 1000).toStringAsFixed(1)}K';
  }

  String _accountSectionTitle() {
    return _accountFilter == _AdminAccountFilter.customers
        ? 'Customer Accounts'
        : 'Restaurant Accounts';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.orange,
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(80),
            child: DashboardTabBarContainer(
              child: TabBar(
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Accounts'),
                  Tab(text: 'Promotions'),
                ],
              ),
            ),
          ),
        ),
        body: _loading
            ? const AppLoadingView()
            : TabBarView(
                children: [
                  _buildOverviewTab(),
                  _buildAccountsTab(),
                  _buildPromotionsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = width >= 1100 ? 3 : 2;
          final childAspectRatio = width >= 1100 ? 2.1 : 1.75;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
                children: [
                  _AdminOverviewMetricCard(
                    title: 'Daily Revenue',
                    value: _formatBaht(_orderStats?.todayRevenue ?? 0),
                    icon: Icons.attach_money,
                    accentColor: const Color(0xFF34A853),
                  ),
                  _AdminOverviewMetricCard(
                    title: 'Monthly Revenue',
                    value: _formatBahtThousands(_orderStats?.monthRevenue ?? 0),
                    icon: Icons.trending_up,
                    accentColor: const Color(0xFF5B8DEF),
                  ),
                  _AdminOverviewMetricCard(
                    title: 'Active Customers',
                    value: _formatCount(_customerCount),
                    icon: Icons.group_outlined,
                    accentColor: const Color(0xFF8B5CF6),
                  ),
                  _AdminOverviewMetricCard(
                    title: 'Active Restaurants',
                    value:
                        _formatCount(_restaurantStats?.activeRestaurants ?? 0),
                    icon: Icons.storefront_outlined,
                    accentColor: const Color(0xFFF97316),
                  ),
                  _AdminOverviewMetricCard(
                    title: 'Active Riders',
                    value: _formatCount(_activeRiderCount),
                    icon: Icons.delivery_dining_outlined,
                    accentColor: const Color(0xFF6366F1),
                  ),
                  _AdminOverviewMetricCard(
                    title: 'Today\'s Orders',
                    value: _formatCount(_orderStats?.todayOrders ?? 0),
                    icon: Icons.shopping_cart_outlined,
                    accentColor: const Color(0xFFEC4899),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _AdminRevenueChartCard(
                values: _weeklyRevenuePoints,
                labels: _weeklyRevenueLabels,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAccountsTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: (value) => setState(() => _search = value),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search accounts',
              filled: true,
              fillColor: const Color(0xFFF7F8FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAccountFilterChip(
                  label: 'Customers',
                  filter: _AdminAccountFilter.customers,
                ),
                const SizedBox(width: 8),
                _buildAccountFilterChip(
                  label: 'Restaurants',
                  filter: _AdminAccountFilter.restaurants,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _accountSectionTitle(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: _filteredUsers.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(
                          child: Text(
                            'No accounts found',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (_, index) =>
                          _buildUserCard(_filteredUsers[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountFilterChip({
    required String label,
    required _AdminAccountFilter filter,
  }) {
    final selected = _accountFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _accountFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? const Color(0xFF111827) : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final isRestaurant = user.role == 'RESTAURANT';
    final isActive = user.isActive ?? true;
    final badgeLabel = _statusBadgeLabel(
      isRestaurant: isRestaurant,
      isActive: isActive,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      color: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF111827)
                              : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badgeLabel,
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF374151),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._accountDetails(user),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      activeThumbColor: Colors.white,
                      activeTrackColor: const Color(0xFF111827),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFFD1D5DB),
                      value: isActive,
                      onChanged: (_) => _toggleUser(user),
                    ),
                    Text(
                      isActive ? 'Enabled' : 'Disabled',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => _deleteUser(user),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: const Color(0xFFFCA5A5).withValues(alpha: 0.7),
                        ),
                        minimumSize: const Size(46, 46),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusBadgeLabel({
    required bool isRestaurant,
    required bool isActive,
  }) {
    if (isRestaurant) {
      return isActive ? 'active' : 'suspended';
    }
    return isActive ? 'Active' : 'Suspended';
  }

  List<Widget> _accountDetails(User user) {
    if (user.role == 'RESTAURANT') {
      final restaurantMeta = _restaurantMetadata[user.name];
      return [
        Text(
          'Cuisine: ${restaurantMeta?.cuisine ?? 'Mixed'}',
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 15),
        ),
        const SizedBox(height: 6),
        Text(
          'Rating: ${restaurantMeta?.rating ?? '4.5'} ${String.fromCharCode(0x2B50)}',
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 15),
        ),
        const SizedBox(height: 6),
        Text(
          'Distance: ${restaurantMeta?.distanceKm ?? '1.0'} km',
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 15),
        ),
      ];
    }

    final customerMeta = _customerMetadata[user.email];
    return [
      Text(
        user.email,
        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 15),
      ),
      if (user.phoneNumber != null) ...[
        const SizedBox(height: 6),
        Text(
          user.phoneNumber!,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 15),
        ),
      ],
      const SizedBox(height: 10),
      Text(
        'Total Orders: ${customerMeta?.totalOrders ?? 0}',
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ];
  }

  Map<String, _RestaurantAccountMeta> get _restaurantMetadata => {
        'Bangkok Street Food': const _RestaurantAccountMeta(
          cuisine: 'Thai',
          rating: '4.5',
          distanceKm: '0.8',
        ),
        'Sushi Master': const _RestaurantAccountMeta(
          cuisine: 'Japanese',
          rating: '4.8',
          distanceKm: '1.2',
        ),
        'Pizza Paradise': const _RestaurantAccountMeta(
          cuisine: 'Western',
          rating: '4.3',
          distanceKm: '2.5',
        ),
        'Green Garden': const _RestaurantAccountMeta(
          cuisine: 'Thai',
          rating: '4.6',
          distanceKm: '1.8',
        ),
        'Ramen House': const _RestaurantAccountMeta(
          cuisine: 'Japanese',
          rating: '4.7',
          distanceKm: '3.0',
        ),
        'Burger Bistro': const _RestaurantAccountMeta(
          cuisine: 'Western',
          rating: '4.4',
          distanceKm: '0.5',
        ),
      };

  Map<String, _CustomerAccountMeta> get _customerMetadata => {
        'john@example.com': const _CustomerAccountMeta(totalOrders: 24),
        'sarah@example.com': const _CustomerAccountMeta(totalOrders: 15),
        'michael@example.com': const _CustomerAccountMeta(totalOrders: 8),
      };

  Widget _buildPromotionsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showPromotionDialog,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              icon: const Icon(Icons.add_circle, color: Colors.white),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _promotions.length,
                  itemBuilder: (_, index) =>
                      _buildPromotionCard(_promotions[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildPromotionCard(Promotion promotion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  label: Text(promotion.active ? 'Active' : 'Inactive'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('${promotion.code} • ${promotion.targetGroup}'),
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
                    onPressed: () => _togglePromotion(promotion),
                    child: Text(
                      promotion.active ? 'Deactivate' : 'Activate',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _deletePromotion(promotion.id),
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

class _CustomerAccountMeta {
  final int totalOrders;

  const _CustomerAccountMeta({required this.totalOrders});
}

class _RestaurantAccountMeta {
  final String cuisine;
  final String rating;
  final String distanceKm;

  const _RestaurantAccountMeta({
    required this.cuisine,
    required this.rating,
    required this.distanceKm,
  });
}

class _AdminOverviewMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _AdminOverviewMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppDashboardMetricCard(
      title: title,
      value: value,
      icon: icon,
      accentColor: accentColor,
      iconContainerSize: 44,
      iconSize: 22,
      valueFontSize: 21,
      padding: const EdgeInsets.all(18),
    );
  }
}

class _AdminRevenueChartCard extends StatelessWidget {
  final List<double> values;
  final List<String> labels;

  const _AdminRevenueChartCard({
    required this.values,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return AppOutlinedCard(
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Revenue Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 320,
            child: CustomPaint(
              painter: _RevenueChartPainter(
                values: values,
                labels: labels,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;

  _RevenueChartPainter({
    required this.values,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || labels.length != values.length) return;

    const leftPadding = 54.0;
    const topPadding = 12.0;
    const rightPadding = 16.0;
    const bottomPadding = 42.0;

    final chartRect = Rect.fromLTWH(
      leftPadding,
      topPadding,
      size.width - leftPadding - rightPadding,
      size.height - topPadding - bottomPadding,
    );

    const minY = 0.0;
    final maxY = math.max(100000.0, values.reduce(math.max));
    const guideSteps = 4;

    final gridPaint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xFF6B7280)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final fillPaint = Paint()
      ..color = const Color(0xFF8AB4F8).withValues(alpha: 0.58)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = const Color(0xFF4F83F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pointStep =
        labels.length > 1 ? chartRect.width / (labels.length - 1) : 0.0;
    final points = <Offset>[];

    double yForValue(double value) {
      final normalized = (value - minY) / (maxY - minY);
      return chartRect.bottom - (normalized * chartRect.height);
    }

    for (var i = 0; i <= guideSteps; i++) {
      final value = minY + ((maxY - minY) / guideSteps) * i;
      final y = yForValue(value);
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
      final label = value.toInt().toString();
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 11,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(0, y - painter.height / 2));
    }

    for (var i = 0; i < labels.length; i++) {
      final x = chartRect.left + pointStep * i;
      canvas.drawLine(
        Offset(x, chartRect.top),
        Offset(x, chartRect.bottom),
        gridPaint,
      );
      final painter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 11,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(x - painter.width / 2, chartRect.bottom + 10),
      );
      points.add(Offset(x, yForValue(values[i])));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final controlX = (previous.dx + current.dx) / 2;
      linePath.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    final fillPath = Path.from(linePath)
      ..lineTo(chartRect.right, chartRect.bottom)
      ..lineTo(chartRect.left, chartRect.bottom)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);
    canvas.drawLine(
      Offset(chartRect.left, chartRect.bottom),
      Offset(chartRect.right, chartRect.bottom),
      axisPaint,
    );
    canvas.drawLine(
      Offset(chartRect.left, chartRect.top),
      Offset(chartRect.left, chartRect.bottom),
      axisPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RevenueChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.labels != labels;
  }
}
