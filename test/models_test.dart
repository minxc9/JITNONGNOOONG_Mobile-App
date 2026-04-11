import 'package:flutter_test/flutter_test.dart';
import 'package:mhar_rueng_sang/models/admin_stats.dart';
import 'package:mhar_rueng_sang/models/order.dart';
import 'package:mhar_rueng_sang/models/promotion.dart';
import 'package:mhar_rueng_sang/models/restaurant.dart';
import 'package:mhar_rueng_sang/models/user.dart';

void main() {
  group('Model parsing tests', () {
    test('Order.fromJson supports snake_case and nested items', () {
      final order = Order.fromJson({
        'id': 19,
        'order_number': 'MR1775833569712',
        'customer_id': 12,
        'customer_name': 'Natnicha',
        'customer_phone_number': '+66 80 000 0000',
        'restaurant_id': 3,
        'restaurant_name': 'Bangkok Street Food',
        'status': 'DELIVERED',
        'total_amount': 240,
        'delivery_fee': 35,
        'delivery_address': '123456',
        'special_instructions': 'No chili',
        'restaurant_review_id': 55,
        'restaurant_rating': 5,
        'restaurant_review_text': 'Very good',
        'order_items': [
          {
            'id': 1,
            'menu_item_name': 'Pad Thai',
            'quantity': 2,
            'unit_price': 120,
            'total_price': 240,
          },
        ],
      });

      expect(order.orderNumber, 'MR1775833569712');
      expect(order.customerName, 'Natnicha');
      expect(order.deliveryAddress, '123456');
      expect(order.restaurantRating, 5);
      expect(order.orderItems.single.menuItemName, 'Pad Thai');
    });

    test('Order.fromJson handles missing items and camelCase coordinates', () {
      final order = Order.fromJson({
        'id': 21,
        'orderNumber': 'ORD-021',
        'customerId': 3,
        'restaurantId': 8,
        'status': 'PICKED_UP',
        'totalAmount': 99.0,
        'deliveryFee': 10.0,
        'deliveryLatitude': 13.75,
        'deliveryLongitude': 100.5,
        'specialInstructions': 'Less sugar',
      });

      expect(order.orderItems, isEmpty);
      expect(order.deliveryLatitude, 13.75);
      expect(order.deliveryLongitude, 100.5);
      expect(order.specialInstructions, 'Less sugar');
    });

    test('Restaurant.fromJson supports mixed backend keys', () {
      final restaurant = Restaurant.fromJson({
        'id': 7,
        'name': 'Sushi Shop',
        'cuisine_type': 'Japanese',
        'phone_number': '+66 81 111 1111',
        'owner_id': 15,
        'image_url': 'https://example.com/sushi.png',
        'average_rating': 4.7,
        'delivery_fee': 25,
        'minimum_order_amount': 150,
        'estimated_delivery_time': 30,
        'is_active': false,
      });

      expect(restaurant.cuisineType, 'Japanese');
      expect(restaurant.phoneNumber, '+66 81 111 1111');
      expect(restaurant.imageUrl, 'https://example.com/sushi.png');
      expect(restaurant.rating, 4.7);
      expect(restaurant.isActive, false);
    });

    test('MenuItem and RestaurantReview parse backend payloads', () {
      final menuItem = MenuItem.fromJson({
        'id': 2,
        'name': 'Tom Yum',
        'price': 95,
        'category_id': 4,
        'category_name': 'Soups',
        'image_url': 'https://example.com/tomyum.png',
        'is_available': false,
      });
      final review = RestaurantReview.fromJson({
        'id': 3,
        'restaurant_id': 7,
        'order_id': 9,
        'customer_id': 5,
        'customer_name': 'Mint',
        'rating': 4,
        'review_text': 'Nice food',
        'created_at': '2026-04-11',
      });

      expect(menuItem.categoryId, 4);
      expect(menuItem.category, 'Soups');
      expect(menuItem.imageUrl, 'https://example.com/tomyum.png');
      expect(menuItem.isAvailable, false);
      expect(review.customerName, 'Mint');
      expect(review.createdAt, '2026-04-11');
    });

    test('MenuCategory and Promotion toJson preserve values', () {
      const category = MenuCategory(
        id: 1,
        restaurantId: 9,
        name: 'Noodles',
        description: 'Stir-fried noodles',
        displayOrder: 2,
        isLocalOnly: true,
      );
      const promo = Promotion(
        id: 'PROMO1',
        title: 'New User',
        description: 'Half price',
        code: 'NEW50',
        discountPercent: 50,
        maxUses: 100,
        currentUses: 10,
        validFrom: '2026-04-01',
        validUntil: '2026-04-30',
        targetGroup: 'new',
        active: true,
      );

      expect(category.toJson()['name'], 'Noodles');
      expect(category.toJson()['isLocalOnly'], true);
      expect(promo.toJson()['code'], 'NEW50');
      expect(
          promo.copyWith(const PromotionChanges(active: false)).active, false);
      expect(promo.copyWith().active, true);
    });

    test('User and admin stats parse defaults safely', () {
      final user = User.fromJson({
        'id': 4,
        'name': 'Admin',
        'email': 'admin@foodexpress.com',
        'role': 'ADMIN',
        'enabled': true,
      });
      final orderStats = OrderStats.fromJson({'todayOrders': 8});
      final restaurantStats = RestaurantStats.fromJson({});

      expect(user.isActive, true);
      expect(orderStats.monthRevenue, 0);
      expect(restaurantStats.activeRestaurants, 0);
    });
  });
}
