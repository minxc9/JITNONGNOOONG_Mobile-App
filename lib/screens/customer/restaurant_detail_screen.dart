import 'package:flutter/material.dart';
import '../../models/restaurant.dart';
import '../../services/api_service.dart';
import '../../widgets/shared_ui.dart';
import 'cart_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Restaurant restaurant;
  const RestaurantDetailScreen({super.key, required this.restaurant});
  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  static const _sortMostRecent = 'Most Recent';
  static const _sortHighestRated = 'Highest Rated';
  static const _sortLowestRated = 'Lowest Rated';

  List<MenuItem> _menuItems = [];
  List<RestaurantReview> _reviews = [];
  final Map<int, int> _cart = {};
  bool _isLoading = true;
  String _selectedReviewSort = _sortMostRecent;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final results = await Future.wait([
        ApiService.fetchMenuItems(widget.restaurant.id),
        ApiService.fetchRestaurantReviews(widget.restaurant.id),
      ]);
      final items = results[0] as List<MenuItem>;
      final reviews = results[1] as List<RestaurantReview>;
      setState(() {
        _menuItems = items.where((item) => item.isAvailable).toList();
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  int get _totalItems => _cart.values.fold(0, (a, b) => a + b);
  double get _cartTotal => _cart.entries.fold(0, (total, entry) {
        final item = _menuItems
            .where((menuItem) => menuItem.id == entry.key)
            .cast<MenuItem?>()
            .firstWhere((menuItem) => menuItem != null, orElse: () => null);
        if (item == null) return total;
        return total + (item.price * entry.value);
      });

  List<RestaurantReview> get _sortedReviews {
    final reviews = List<RestaurantReview>.from(_reviews);

    switch (_selectedReviewSort) {
      case _sortHighestRated:
        reviews.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _sortLowestRated:
        reviews.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case _sortMostRecent:
      default:
        reviews
            .sort((a, b) => _reviewSortDate(b).compareTo(_reviewSortDate(a)));
        break;
    }

    return reviews;
  }

  void _updateQuantity(MenuItem item, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cart.remove(item.id);
      } else {
        _cart[item.id] = quantity;
      }
    });
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          restaurant: widget.restaurant,
          cart: _cart,
          menuItems: _menuItems,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurant.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: 'Open cart',
                  onPressed: _openCart,
                  icon: const Icon(Icons.shopping_bag_outlined),
                ),
                if (_totalItems > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$_totalItems',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const AppLoadingView()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeroImage()),
                SliverToBoxAdapter(child: _buildRestaurantSummary()),
                _menuItems.isEmpty ? _buildEmptyMenuState() : _buildMenuList(),
                SliverToBoxAdapter(child: _buildReviewsSection()),
              ],
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ElevatedButton.icon(
          onPressed: _menuItems.isEmpty && _totalItems == 0 ? null : _openCart,
          icon: const Icon(Icons.shopping_cart_checkout),
          label: Text(
            _totalItems > 0
                ? 'Open Cart ($_totalItems) • ฿${_cartTotal.toStringAsFixed(0)}'
                : 'Open Cart',
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    return SizedBox(
      width: double.infinity,
      height: 220,
      child: AppRemoteImageBox(
        imageUrl: widget.restaurant.imageUrl,
        fallbackIcon: Icons.restaurant_menu,
        fallbackIconSize: 42,
      ),
    );
  }

  Widget _buildRestaurantSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
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
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No menu items available',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    final theme = Theme.of(context);
    final reviewCount = _reviews.length;
    final reviews = _sortedReviews;
    final averageRating = reviewCount == 0
        ? (widget.restaurant.rating ?? 0)
        : _reviews
                .map((review) => review.rating)
                .reduce((sum, rating) => sum + rating) /
            reviewCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Reviews',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                runSpacing: 12,
                spacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF0A500),
                        size: 26,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        reviewCount == 1 ? '1 review' : '$reviewCount reviews',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  _buildReviewSortDropdown(),
                ],
              ),
              const SizedBox(height: 14),
              if (reviews.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F7F4),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'No customer comments yet.',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                )
              else
                ...reviews.map(_buildReviewCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedReviewSort,
          borderRadius: BorderRadius.circular(18),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: const [
            DropdownMenuItem(
              value: _sortMostRecent,
              child: Text('Most Recent'),
            ),
            DropdownMenuItem(
              value: _sortHighestRated,
              child: Text('Highest Rated'),
            ),
            DropdownMenuItem(
              value: _sortLowestRated,
              child: Text('Lowest Rated'),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedReviewSort = value);
          },
        ),
      ),
    );
  }

  Widget _buildReviewCard(RestaurantReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              _buildRatingPill(review.rating),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ...List.generate(
                5,
                (index) => Icon(
                  index < review.rating
                      ? Icons.star_rounded
                      : Icons.star_border,
                  size: 18,
                  color: const Color(0xFFF0A500),
                ),
              ),
              if (_reviewDate(review) != null) ...[
                const SizedBox(width: 8),
                Text(
                  _reviewDate(review)!,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ],
          ),
          if (review.reviewText?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              review.reviewText!.trim(),
              style: TextStyle(color: Colors.grey[850], height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingPill(int rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$rating/5',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String? _reviewDate(RestaurantReview review) {
    final raw = review.createdAt;
    if (raw == null || raw.isEmpty) return null;

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    return '$day/$month/$year';
  }

  DateTime _reviewSortDate(RestaurantReview review) {
    final parsed = DateTime.tryParse(review.createdAt ?? '');
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
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
                child: AppRemoteImageBox(
                  imageUrl: item.imageUrl,
                  fallbackIcon: Icons.fastfood,
                  fallbackIconSize: 42,
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
                        ),
                        color: Theme.of(context).colorScheme.primary,
                        onPressed: () => _updateQuantity(item, quantity + 1),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Add to cart',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
}
