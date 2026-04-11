import 'package:flutter_test/flutter_test.dart';
import 'package:mhar_rueng_sang/models/promotion.dart';
import 'package:mhar_rueng_sang/models/restaurant.dart';
import 'package:mhar_rueng_sang/models/user.dart';
import 'package:mhar_rueng_sang/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalStorageService tests', () {
    test('returns seeded admin promotions when storage is empty', () async {
      final promotions = await LocalStorageService.getAdminPromotions();

      expect(promotions.length, 2);
      expect(promotions.first.code, 'NEWUSER50');
      expect(promotions.last.code, 'WEEKEND20');
      expect(promotions.last.active, true);
    });

    test('saves and reloads admin promotions', () async {
      const promotions = [
        Promotion(
          id: 'ADM1',
          title: 'Admin Promo',
          description: 'For testing',
          code: 'ADMIN10',
          discountPercent: 10,
          maxUses: 500,
          currentUses: 1,
          validFrom: '2026-04-01',
          validUntil: '2026-04-30',
          targetGroup: 'all',
          active: false,
        ),
      ];

      await LocalStorageService.saveAdminPromotions(promotions);
      final loaded = await LocalStorageService.getAdminPromotions();

      expect(loaded.single.code, 'ADMIN10');
      expect(loaded.single.active, false);
    });

    test('saves and reloads admin users', () async {
      final users = [
        User(
          id: 20,
          name: 'Test Customer',
          email: 'test@example.com',
          role: 'CUSTOMER',
          phoneNumber: '+66 88 888 8888',
          isActive: true,
        ),
      ];

      await LocalStorageService.saveAdminUsers(users);
      final loaded = await LocalStorageService.getAdminUsers();

      expect(loaded, hasLength(1));
      expect(loaded.single.email, 'test@example.com');
      expect(loaded.single.phoneNumber, '+66 88 888 8888');
    });

    test('returns seeded admin users when storage is empty', () async {
      final users = await LocalStorageService.getAdminUsers();

      expect(users.length, 4);
      expect(users.first.role, 'CUSTOMER');
      expect(users[1].role, 'RESTAURANT');
      expect(users[2].role, 'RIDER');
      expect(users.last.isActive, false);
    });

    test('saves and reloads restaurant promotions', () async {
      const promotions = [
        Promotion(
          id: 'REST1',
          title: 'Lunch Deal',
          description: 'Discount at noon',
          code: 'LUNCH20',
          discountPercent: 20,
          maxUses: 200,
          currentUses: 5,
          validFrom: '2026-04-01',
          validUntil: '2026-04-30',
          targetGroup: 'all',
          active: true,
        ),
      ];

      await LocalStorageService.saveRestaurantPromotions(9, promotions);
      final loaded = await LocalStorageService.getRestaurantPromotions(9);

      expect(loaded.single.title, 'Lunch Deal');
      expect(loaded.single.discountPercent, 20);
    });

    test('saves and reloads local categories', () async {
      const categories = [
        MenuCategory(
          id: 99,
          restaurantId: 5,
          name: 'Desserts',
          description: 'Sweet dishes',
          isLocalOnly: true,
        ),
      ];

      await LocalStorageService.saveLocalCategories(5, categories);
      final loaded = await LocalStorageService.getLocalCategories(5);

      expect(loaded.single.name, 'Desserts');
      expect(loaded.single.isLocalOnly, true);
    });

    test('empty restaurant storage returns empty lists', () async {
      final promotions = await LocalStorageService.getRestaurantPromotions(99);
      final categories = await LocalStorageService.getLocalCategories(99);

      expect(promotions, isEmpty);
      expect(categories, isEmpty);
    });
  });
}
