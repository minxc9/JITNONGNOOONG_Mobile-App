import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mhar_rueng_sang/models/user.dart';
import 'package:mhar_rueng_sang/screens/admin/dashboard_screen.dart';
import 'package:mhar_rueng_sang/screens/auth/otp_screen.dart';
import 'package:mhar_rueng_sang/screens/restaurant/dashboard_screen.dart';
import 'package:mhar_rueng_sang/services/api_service.dart';
import 'package:mhar_rueng_sang/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    ApiService.resetHttpClient();
  });

  testWidgets(
    'RestaurantDashboardScreen covers tabs, dialogs, and order actions',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'user_id': 15,
        'user_role': 'RESTAURANT',
        'user_email': 'restaurant@foodexpress.com',
        'user_name': 'Bangkok Street Food',
      });

      var orderStatusUpdated = false;
      var menuSaved = false;
      await LocalStorageService.saveRestaurantPromotions(1, []);
      await LocalStorageService.saveLocalCategories(1, []);

      ApiService.setHttpClient(
        MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/restaurants/owner/15')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'id': 1,
                  'name': 'Bangkok Street Food',
                  'ownerId': 15,
                  'email': 'restaurant@foodexpress.com',
                  'isActive': true,
                },
              }),
              200,
            );
          }
          if (path.endsWith('/orders/restaurant/1')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'content': [
                    {
                      'id': 1,
                      'orderNumber': 'ORD-1',
                      'customerId': 2,
                      'restaurantId': 1,
                      'status': 'PENDING',
                      'totalAmount': 120.0,
                      'deliveryFee': 20.0,
                      'orderItems': [],
                    },
                    {
                      'id': 2,
                      'orderNumber': 'ORD-2',
                      'customerId': 2,
                      'restaurantId': 1,
                      'status': 'CONFIRMED',
                      'totalAmount': 130.0,
                      'deliveryFee': 20.0,
                      'orderItems': [],
                    },
                    {
                      'id': 3,
                      'orderNumber': 'ORD-3',
                      'customerId': 2,
                      'restaurantId': 1,
                      'status': 'PREPARING',
                      'totalAmount': 140.0,
                      'deliveryFee': 20.0,
                      'orderItems': [],
                    },
                    {
                      'id': 4,
                      'orderNumber': 'ORD-4',
                      'customerId': 2,
                      'restaurantId': 1,
                      'status': 'DELIVERED',
                      'totalAmount': 150.0,
                      'deliveryFee': 20.0,
                      'orderItems': [],
                    },
                  ],
                },
              }),
              200,
            );
          }
          if (path.endsWith('/restaurants/1/menu') && request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'content': [
                    {
                      'id': 10,
                      'name': 'Pad Thai',
                      'price': 120,
                      'category': 'Noodles',
                      'categoryId': 1,
                      'description': 'Classic Thai noodles',
                      'is_available': true,
                    },
                  ],
                },
              }),
              200,
            );
          }
          if (path.endsWith('/restaurants/1/categories')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': [
                  {
                    'id': 1,
                    'restaurant_id': 1,
                    'name': 'Noodles',
                    'description': 'Noodle dishes',
                  },
                ],
              }),
              200,
            );
          }
          if (path.endsWith('/restaurants/1/reviews')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': [
                  {
                    'id': 1,
                    'restaurant_id': 1,
                    'order_id': 1,
                    'customer_id': 2,
                    'customer_name': 'Mint',
                    'rating': 5,
                    'review_text': 'Great',
                  },
                ],
              }),
              200,
            );
          }
          if (path.endsWith('/orders/1/status') && request.method == 'PUT') {
            orderStatusUpdated = true;
            return http.Response('{"success":true}', 200);
          }
          if (path.endsWith('/restaurants/1/menu') &&
              request.method == 'POST') {
            menuSaved = true;
            return http.Response('{"success":true}', 200);
          }
          if (path.endsWith('/restaurants/1/menu/10') &&
              request.method == 'PUT') {
            return http.Response('{"success":true}', 200);
          }
          if (path.endsWith('/restaurants/1/menu/10') &&
              request.method == 'DELETE') {
            return http.Response('{"success":true}', 200);
          }
          return http.Response('{"success":false}', 404);
        }),
      );

      await tester.pumpWidget(
        const MaterialApp(home: RestaurantDashboardScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pending Orders'), findsOneWidget);
      expect(find.text('Recent Reviews'), findsOneWidget);

      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Preparing'), findsOneWidget);
      expect(find.text('Ready for Pickup'), findsOneWidget);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(orderStatusUpdated, isTrue);

      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Add Menu Item'), findsOneWidget);
      expect(find.text('Pad Thai'), findsOneWidget);

      await tester.tap(find.text('Add Menu Item'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Tom Yum');
      await tester.enterText(
        find.widgetWithText(TextField, 'Description'),
        'Spicy soup',
      );
      await tester.enterText(find.widgetWithText(TextField, 'Price'), '99');
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();
      expect(menuSaved, isTrue);

      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();
      expect(find.text('Edit Menu Item'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Category'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Name'), 'Desserts');
      await tester.enterText(
        find.widgetWithText(TextField, 'Description'),
        'Sweet menu',
      );
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();
      expect(find.text('Desserts'), findsOneWidget);

      await tester.tap(find.text('Promotions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Promotion'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Title'), 'Lunch Deal');
      await tester.enterText(find.widgetWithText(TextField, 'Code'), 'LUNCH10');
      await tester.enterText(
        find.widgetWithText(TextField, 'Description'),
        'Save at lunch',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Discount %'),
        '10',
      );
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();
      expect(find.text('Lunch Deal'), findsOneWidget);
    },
  );

  testWidgets(
    'AdminDashboardScreen covers accounts and promotions interactions',
    (tester) async {
      ApiService.setHttpClient(
        MockClient((request) async {
          if (request.url.path.endsWith('/orders/admin/stats')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'todayOrders': 4,
                  'monthOrders': 20,
                  'totalOrders': 50,
                  'todayRevenue': 400.0,
                  'monthRevenue': 2000.0,
                },
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/restaurants/stats')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {'totalRestaurants': 10, 'activeRestaurants': 8},
              }),
              200,
            );
          }
          return http.Response('{"success":false}', 404);
        }),
      );

      await LocalStorageService.saveAdminUsers([
        User(
          id: 1,
          name: 'Alice Admin',
          email: 'alice@example.com',
          role: 'CUSTOMER',
          phoneNumber: '+66 1',
          isActive: true,
        ),
      ]);
      await LocalStorageService.saveAdminPromotions([]);

      await tester.pumpWidget(const MaterialApp(home: AdminDashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Today\'s Orders'), findsOneWidget);

      await tester.tap(find.text('Accounts'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Search accounts'),
        'Alice',
      );
      await tester.pumpAndSettle();
      expect(find.text('Alice Admin'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Promotions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Promotion'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Code'), 'ADMIN20');
      await tester.enterText(
          find.widgetWithText(TextField, 'Title'), 'Admin Promo');
      await tester.enterText(
        find.widgetWithText(TextField, 'Description'),
        'Promotion from admin',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Discount %'),
        '20',
      );
      await tester.enterText(find.widgetWithText(TextField, 'Max Uses'), '50');
      await tester.enterText(
        find.widgetWithText(TextField, 'Valid From (YYYY-MM-DD)'),
        '2026-04-01',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Valid Until (YYYY-MM-DD)'),
        '2026-04-30',
      );
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Admin Promo'), findsOneWidget);
      await tester.tap(find.text('Deactivate'));
      await tester.pumpAndSettle();
      expect(find.text('Activate'), findsOneWidget);
    },
  );

  testWidgets('OtpScreen validates invalid input before API call', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: OtpScreen(email: 'customer@foodexpress.com')),
    );

    await tester.enterText(find.byType(TextField), '123');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(find.text('Enter 6-digit OTP'), findsOneWidget);
  });

  testWidgets('OtpScreen routes admin users after successful verification', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    ApiService.setHttpClient(
      MockClient((request) async {
        if (request.url.path.endsWith('/auth/otp')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'token': 'token-123',
                'user': {
                  'id': 9,
                  'name': 'Admin',
                  'email': 'admin@foodexpress.com',
                  'role': 'ADMIN',
                },
              },
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/orders/admin/stats')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'todayOrders': 1,
                'monthRevenue': 99.0,
              },
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/restaurants/stats')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'activeRestaurants': 1},
            }),
            200,
          );
        }
        return http.Response('{"success":false}', 404);
      }),
    );

    await tester.pumpWidget(
      const MaterialApp(home: OtpScreen(email: 'admin@foodexpress.com')),
    );

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(find.text('Admin Dashboard'), findsOneWidget);
    expect(find.text('Today\'s Orders'), findsOneWidget);
  });
}
