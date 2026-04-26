import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mhar_rueng_sang/models/restaurant.dart';
import 'package:mhar_rueng_sang/screens/auth/login_screen.dart';
import 'package:mhar_rueng_sang/screens/auth/otp_screen.dart';
import 'package:mhar_rueng_sang/screens/auth/register_screen.dart';
import 'package:mhar_rueng_sang/screens/customer/home_screen.dart';
import 'package:mhar_rueng_sang/screens/customer/cart_screen.dart';
import 'package:mhar_rueng_sang/screens/customer/order_history_screen.dart';
import 'package:mhar_rueng_sang/screens/customer/order_tracking_screen.dart';
import 'package:mhar_rueng_sang/screens/customer/restaurant_detail_screen.dart';
import 'package:mhar_rueng_sang/screens/admin/dashboard_screen.dart';
import 'package:mhar_rueng_sang/screens/rider/dashboard_screen.dart';
import 'package:mhar_rueng_sang/screens/rider/delivery_screen.dart';
import 'package:mhar_rueng_sang/screens/restaurant/dashboard_screen.dart';
import 'package:mhar_rueng_sang/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    ApiService.resetHttpClient();
  });

  testWidgets('LoginScreen renders sign in form and demo accounts', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Sign in to your account'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });

  testWidgets('RegisterScreen renders customer registration sections', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    expect(find.text('Customer Registration'), findsNWidgets(2));
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Account Security'), findsOneWidget);
    expect(find.text('Payment Information'), findsOneWidget);
  });

  testWidgets('OtpScreen renders email and verify action', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: OtpScreen(email: 'customer@foodexpress.com')),
    );

    expect(find.text('Enter OTP'), findsOneWidget);
    expect(find.textContaining('customer@foodexpress.com'), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
  });

  testWidgets('CustomerHomeScreen renders fetched restaurants', (tester) async {
    ApiService.setHttpClient(
      MockClient((request) async {
        if (request.url.path.endsWith('/restaurants')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'content': [
                  {
                    'id': 1,
                    'name': 'Bangkok Street Food',
                    'cuisine_type': 'Thai',
                    'address': 'Sukhumvit',
                    'estimated_delivery_time': 25,
                    'is_active': true,
                  },
                ],
              },
            }),
            200,
          );
        }
        return http.Response('{"success":false}', 404);
      }),
    );

    await tester.pumpWidget(const MaterialApp(home: CustomerHomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Popular Restaurants'), findsOneWidget);
    expect(find.text('Bangkok Street Food'), findsOneWidget);
    expect(find.textContaining('25 mins'), findsOneWidget);
  });

  testWidgets('RestaurantDetailScreen renders fetched menu items', (
    tester,
  ) async {
    ApiService.setHttpClient(
      MockClient((request) async {
        if (request.url.path.endsWith('/restaurants/1/menu')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'content': [
                  {
                    'id': 10,
                    'name': 'Pad Thai',
                    'price': 120,
                    'category_name': 'Noodles',
                    'description': 'Classic Thai noodles',
                    'is_available': true,
                  },
                ],
              },
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/restaurants/1/reviews')) {
          return http.Response(
            '{"success":true,"data":[]}',
            200,
          );
        }
        return http.Response('{"success":false}', 404);
      }),
    );

    final restaurant = Restaurant(
      id: 1,
      name: 'Bangkok Street Food',
      cuisineType: 'Thai',
      description: 'Street food',
      isActive: true,
    );

    await tester.pumpWidget(
      MaterialApp(home: RestaurantDetailScreen(restaurant: restaurant)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('Pad Thai'), findsOneWidget);
    expect(find.textContaining('Noodles'), findsOneWidget);
  });

  testWidgets('CartScreen renders checkout summary', (tester) async {
    final restaurant = Restaurant(
      id: 1,
      name: 'Bangkok Street Food',
      isActive: true,
    );
    final menuItems = [
      MenuItem(
        id: 10,
        name: 'Pad Thai',
        price: 120,
        category: 'Noodles',
        isAvailable: true,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: CartScreen(
          restaurant: restaurant,
          cart: const {10: 2},
          menuItems: menuItems,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Checkout'), findsOneWidget);
    expect(find.text('Your Order'), findsOneWidget);
    expect(find.text('Pad Thai'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Place Order'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Place Order'), findsOneWidget);
  });

  testWidgets('OrderHistoryScreen renders customer orders', (tester) async {
    SharedPreferences.setMockInitialValues({'user_id': 5});
    ApiService.setHttpClient(
      MockClient((request) async {
        if (request.url.path.endsWith('/orders/customer/5')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'content': [
                  {
                    'id': 90,
                    'orderNumber': 'ORD-090',
                    'customerId': 5,
                    'restaurantId': 1,
                    'restaurantName': 'Bangkok Street Food',
                    'status': 'DELIVERED',
                    'totalAmount': 240.0,
                    'deliveryFee': 35.0,
                    'orderItems': [],
                  },
                ],
              },
            }),
            200,
          );
        }
        return http.Response('{"success":false}', 404);
      }),
    );

    await tester.pumpWidget(const MaterialApp(home: OrderHistoryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('My Orders'), findsOneWidget);
    expect(find.text('ORD-090'), findsOneWidget);
    expect(find.text('View Order Details'), findsOneWidget);
  });

  testWidgets('OrderTrackingScreen renders delivery status details', (
    tester,
  ) async {
    ApiService.setHttpClient(
      MockClient((request) async {
        if (request.url.path.endsWith('/orders/1')) {
          return http.Response(
              jsonEncode(_orderPayload(status: 'DELIVERED')), 200);
        }
        return http.Response('{"success":false}', 404);
      }),
    );

    await tester.pumpWidget(
      const MaterialApp(home: OrderTrackingScreen(orderId: 1)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delivery Status'), findsOneWidget);
    expect(find.text('MR1775833569712'), findsOneWidget);
    expect(find.text('DELIVERED'), findsWidgets);
    expect(find.text('Order Tracking'), findsOneWidget);
  });

  testWidgets('OrderTrackingScreen shows live tracking for picked up orders', (
    tester,
  ) async {
    ApiService.setHttpClient(
      MockClient((request) async {
        if (request.url.path.endsWith('/orders/2')) {
          return http.Response(
            jsonEncode(_orderPayload(status: 'PICKED_UP')),
            200,
          );
        }
        return http.Response('{"success":false}', 404);
      }),
    );

    await tester.pumpWidget(
      const MaterialApp(home: OrderTrackingScreen(orderId: 2)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Live Tracking Map'), findsOneWidget);
    expect(
      find.text('Updates every 5 seconds with simulated GPS coordinates'),
      findsOneWidget,
    );
    expect(find.text('Delivered'), findsNothing);
  });

  testWidgets('OrderTrackingScreen shows cancel action for pending orders', (
    tester,
  ) async {
    ApiService.setHttpClient(
      MockClient((request) async {
        if (request.url.path.endsWith('/orders/3') && request.method == 'GET') {
          return http.Response(
            jsonEncode(_orderPayload(status: 'PENDING')),
            200,
          );
        }
        return http.Response('{"success":false}', 404);
      }),
    );

    await tester.pumpWidget(
      const MaterialApp(home: OrderTrackingScreen(orderId: 3)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Cancel Order'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Cancel Order'), findsOneWidget);
  });

  testWidgets('DeliveryScreen renders pickup and drop-off details', (
    tester,
  ) async {
    ApiService.setHttpClient(
      MockClient((request) async {
        if (request.url.path.endsWith('/orders/1')) {
          return http.Response(
              jsonEncode(_orderPayload(status: 'DELIVERED')), 200);
        }
        if (request.url.path.endsWith('/restaurants/1')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 1,
                'name': 'Bangkok Street Food',
                'address': '123 Sukhumvit',
                'phone_number': '+66812345678',
                'isActive': true,
              },
            }),
            200,
          );
        }
        return http.Response('{"success":false}', 404);
      }),
    );

    await tester
        .pumpWidget(const MaterialApp(home: DeliveryScreen(orderId: 1)));
    await tester.pumpAndSettle();

    expect(find.text('Pickup Details'), findsOneWidget);
    expect(find.text('Drop-off Address'), findsOneWidget);
    expect(find.text('Customer Contact'), findsOneWidget);
  });

  testWidgets('RiderDashboardScreen renders available deliveries tab', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(
        {'user_id': 6, 'user_name': 'Mike Chen'});
    ApiService.setHttpClient(
      MockClient((request) async {
        if (request.url.path.endsWith('/orders/rider/available') ||
            request.url.path.endsWith('/orders/rider/6')) {
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
                    'restaurantName': 'Bangkok Street Food',
                    'status': 'READY_FOR_PICKUP',
                    'totalAmount': 99.0,
                    'deliveryFee': 20.0,
                    'deliveryAddress': '123 Street',
                    'orderItems': [],
                  },
                ],
              },
            }),
            200,
          );
        }
        return http.Response('{"success":false}', 404);
      }),
    );

    await tester.pumpWidget(const MaterialApp(home: RiderDashboardScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Rider Portal'), findsOneWidget);
    expect(find.text('Mike Chen'), findsOneWidget);
    expect(find.text("Today's Earnings"), findsOneWidget);
    expect(find.text('Available Orders Nearby'), findsOneWidget);
    expect(find.text('Bangkok Street Food'), findsWidgets);
    expect(find.text('Accept Order'), findsOneWidget);
  });

  testWidgets('AdminDashboardScreen renders overview metrics', (tester) async {
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
        if (request.url.path.endsWith('/admin/users')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 1,
                  'name': 'Customer One',
                  'email': 'customer@example.com',
                  'role': 'CUSTOMER',
                  'enabled': true,
                },
                {
                  'id': 2,
                  'name': 'Rider One',
                  'email': 'rider@example.com',
                  'role': 'RIDER',
                  'enabled': true,
                },
              ],
            }),
            200,
          );
        }
        return http.Response('{"success":false}', 404);
      }),
    );

    await tester.pumpWidget(const MaterialApp(home: AdminDashboardScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Admin Dashboard'), findsOneWidget);
    expect(find.text('Daily Revenue'), findsOneWidget);
    expect(find.text('฿125,430'), findsOneWidget);
    expect(find.text('Monthly Revenue'), findsOneWidget);
    expect(find.text('฿3456.8K'), findsOneWidget);
    expect(find.text('Active Customers'), findsOneWidget);
    expect(find.text('15,234'), findsOneWidget);
    expect(find.text('Active Restaurants'), findsOneWidget);
    expect(find.text('456'), findsOneWidget);
    expect(find.text('Active Riders'), findsOneWidget);
    expect(find.text('234'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Today\'s Orders'), findsOneWidget);
    expect(find.text('892'), findsOneWidget);
  });

  testWidgets('AdminDashboardScreen uses web fallback when user endpoint fails',
      (tester) async {
    ApiService.setHttpClient(
      MockClient((request) async {
        if (request.url.path.endsWith('/orders/admin/stats')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'todayOrders': 9,
                'monthOrders': 15,
                'totalOrders': 16,
                'todayRevenue': 710.0,
                'monthRevenue': 1330.0,
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
        if (request.url.path.endsWith('/admin/users')) {
          return http.Response('Cannot GET /api/v1/admin/users', 404);
        }
        return http.Response('{"success":false}', 404);
      }),
    );

    await tester.pumpWidget(const MaterialApp(home: AdminDashboardScreen()));
    await tester.pumpAndSettle();

    expect(find.text('฿125,430'), findsOneWidget);
    expect(find.text('฿3456.8K'), findsOneWidget);
    expect(find.text('456'), findsOneWidget);
    expect(find.text('234'), findsOneWidget);
    expect(find.text('15,234'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('892'), findsOneWidget);
    expect(find.text('Some admin data could not load.'), findsNothing);
  });

  testWidgets(
      'AdminDashboardScreen account tab falls back to web demo accounts',
      (tester) async {
    ApiService.setHttpClient(
      MockClient((request) async {
        if (request.url.path.endsWith('/admin/users')) {
          return http.Response('Cannot GET /api/v1/admin/users', 404);
        }
        return http.Response('{"success":false}', 404);
      }),
    );

    await tester.pumpWidget(const MaterialApp(home: AdminDashboardScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Accounts'));
    await tester.pumpAndSettle();

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Customer Accounts'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Search accounts'),
      'Sarah',
    );
    await tester.pumpAndSettle();

    expect(find.text('Sarah Wilson'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(find.text('Unable to update account right now.'), findsNothing);

    await tester.tap(find.text('Restaurants'));
    await tester.pumpAndSettle();
    expect(find.text('Restaurant Accounts'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Search accounts'),
      'Sushi',
    );
    await tester.pumpAndSettle();
    expect(find.text('Sushi Master'), findsOneWidget);
  });

  testWidgets('RestaurantDashboardScreen renders overview data', (
    tester,
  ) async {
    final todayIso = DateTime.now().toUtc().toIso8601String();
    final yesterdayIso = DateTime.now()
        .toUtc()
        .subtract(const Duration(days: 1))
        .toIso8601String();
    SharedPreferences.setMockInitialValues({'user_id': 15});
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
                    'createdAt': todayIso,
                    'status': 'PENDING',
                    'totalAmount': 80.0,
                    'deliveryFee': 20.0,
                    'orderItems': [],
                  },
                  {
                    'id': 2,
                    'orderNumber': 'ORD-2',
                    'customerId': 3,
                    'restaurantId': 1,
                    'status': 'DELIVERED',
                    'totalAmount': 120.0,
                    'deliveryFee': 20.0,
                    'createdAt': todayIso,
                    'orderItems': [],
                  },
                  {
                    'id': 3,
                    'orderNumber': 'ORD-3',
                    'customerId': 4,
                    'restaurantId': 1,
                    'status': 'DELIVERED',
                    'totalAmount': 90.0,
                    'deliveryFee': 20.0,
                    'createdAt': yesterdayIso,
                    'orderItems': [],
                  },
                ],
              },
            }),
            200,
          );
        }
        if (path.endsWith('/restaurants/1/menu')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'content': [
                  {
                    'id': 10,
                    'name': 'Pad Thai',
                    'price': 120,
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
                {'id': 1, 'restaurant_id': 1, 'name': 'Noodles'},
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
        return http.Response('{"success":false}', 404);
      }),
    );

    await tester
        .pumpWidget(const MaterialApp(home: RestaurantDashboardScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Bangkok Street Food'), findsOneWidget);
    expect(find.text('Pending Orders'), findsOneWidget);
    expect(find.text("Today's Revenue"), findsOneWidget);
    expect(find.text('Menu Items'), findsOneWidget);
    expect(find.text('Completed Today'), findsOneWidget);
    expect(find.text('฿200'), findsOneWidget);
  });
}

Map<String, dynamic> _orderPayload({required String status}) {
  return {
    'success': true,
    'data': {
      'id': 1,
      'orderNumber': 'MR1775833569712',
      'customerId': 5,
      'customerName': 'Customer',
      'customerPhoneNumber': '+66810000000',
      'restaurantId': 1,
      'restaurantName': 'Bangkok Street Food',
      'status': status,
      'totalAmount': 240.0,
      'deliveryFee': 35.0,
      'deliveryAddress': '123456',
      'deliveryLatitude': 13.75,
      'deliveryLongitude': 100.5,
      'restaurantReviewId': 10,
      'restaurantRating': 5,
      'restaurantReviewText': 'No comment',
      'orderItems': [
        {
          'id': 1,
          'menuItemName': 'Pad Thai',
          'quantity': 2,
          'unitPrice': 120.0,
          'totalPrice': 240.0,
        },
      ],
      'createdAt': '2026-04-10T15:06:09.000Z',
    },
  };
}
