import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/promotion.dart';
import '../models/restaurant.dart';
import '../models/user.dart';

class LocalStorageService {
  static const _adminPromotionsKey = 'admin_promotions';
  static const _adminUsersKey = 'admin_users';
  static String _restaurantPromotionsKey(int restaurantId) =>
      'restaurant_promotions_$restaurantId';
  static String _restaurantCategoriesKey(int restaurantId) =>
      'restaurant_categories_$restaurantId';

  static Future<List<Promotion>> getAdminPromotions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_adminPromotionsKey);
    if (raw == null || raw.isEmpty) {
      return const [
        Promotion(
          id: 'SYSPROMO001',
          code: 'NEWUSER50',
          title: 'New User Welcome',
          description: 'Get 50% off your first order',
          discountPercent: 50,
          maxUses: 1000,
          currentUses: 342,
          validFrom: '2026-03-01',
          validUntil: '2026-03-31',
          targetGroup: 'new',
          active: true,
        ),
        Promotion(
          id: 'SYSPROMO002',
          code: 'WEEKEND20',
          title: 'Weekend Discount',
          description: '20% off on all orders during weekends',
          discountPercent: 20,
          maxUses: 5000,
          currentUses: 1823,
          validFrom: '2026-03-06',
          validUntil: '2026-03-07',
          targetGroup: 'all',
          active: true,
        ),
      ];
    }
    return (jsonDecode(raw) as List<dynamic>)
        .map((item) => Promotion.fromJson(item))
        .toList();
  }

  static Future<void> saveAdminPromotions(List<Promotion> promotions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _adminPromotionsKey,
      jsonEncode(promotions.map((promo) => promo.toJson()).toList()),
    );
  }

  static Future<List<User>> getAdminUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_adminUsersKey);
    if (raw == null || raw.isEmpty) {
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
          name: 'Bangkok Bites',
          email: 'restaurant@example.com',
          role: 'RESTAURANT',
          phoneNumber: '+66 82 345 6789',
          isActive: true,
        ),
        User(
          id: 3,
          name: 'Fast Rider',
          email: 'rider@example.com',
          role: 'RIDER',
          phoneNumber: '+66 83 456 7890',
          isActive: true,
        ),
        User(
          id: 4,
          name: 'Nina Customer',
          email: 'nina@example.com',
          role: 'CUSTOMER',
          phoneNumber: '+66 84 567 8901',
          isActive: false,
        ),
      ];
    }
    return (jsonDecode(raw) as List<dynamic>)
        .map((item) => User.fromJson(item))
        .toList();
  }

  static Future<void> saveAdminUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _adminUsersKey,
      jsonEncode(users.map((user) => user.toJson()).toList()),
    );
  }

  static Future<List<Promotion>> getRestaurantPromotions(
      int restaurantId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_restaurantPromotionsKey(restaurantId));
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((item) => Promotion.fromJson(item))
        .toList();
  }

  static Future<void> saveRestaurantPromotions(
    int restaurantId,
    List<Promotion> promotions,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _restaurantPromotionsKey(restaurantId),
      jsonEncode(promotions.map((promo) => promo.toJson()).toList()),
    );
  }

  static Future<List<MenuCategory>> getLocalCategories(int restaurantId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_restaurantCategoriesKey(restaurantId));
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((item) => MenuCategory.fromJson(item))
        .toList();
  }

  static Future<void> saveLocalCategories(
    int restaurantId,
    List<MenuCategory> categories,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _restaurantCategoriesKey(restaurantId),
      jsonEncode(categories.map((category) => category.toJson()).toList()),
    );
  }
}
