import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mhar_rueng_sang/models/restaurant.dart';
import 'package:mhar_rueng_sang/models/user.dart';
import 'package:mhar_rueng_sang/screens/admin/dashboard_screen.dart';
import 'package:mhar_rueng_sang/screens/auth/login_screen.dart';
import 'package:mhar_rueng_sang/screens/auth/otp_screen.dart';
import 'package:mhar_rueng_sang/screens/auth/register_screen.dart';
import 'package:mhar_rueng_sang/screens/customer/cart_screen.dart';
import 'package:mhar_rueng_sang/screens/customer/home_screen.dart';
import 'package:mhar_rueng_sang/screens/customer/order_history_screen.dart';
import 'package:mhar_rueng_sang/screens/customer/restaurant_detail_screen.dart';
import 'package:mhar_rueng_sang/screens/rider/dashboard_screen.dart';
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

  testWidgets(
      'LoginScreen covers demo fill, validation, failure, and register navigation',
      (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.tap(find.text('Customer'));
    await tester.pumpAndSettle();
    expect(find.text('Customer account filled. Tap Sign In to continue.'),
        findsOneWidget);
    expect(find.text('customer@foodexpress.com'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('New customer? Create an account'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('New customer? Create an account'));
    await tester.pumpAndSettle();
    expect(find.text('Customer Registration'), findsWidgets);
  });

  testWidgets('LoginScreen handles empty, failed, and successful login flows', (
    tester,
  ) async {
    ApiService.setHttpClient(
      MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (body['password'] == 'customer123') {
          return http.Response('{"success":true}', 200);
        }
        return http.Response(
            '{"success":false,"message":"Bad credentials"}', 401);
      }),
    );

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('Please fill all fields'), findsOneWidget);

    await tester.enterText(
        find.byType(TextField).at(0), 'customer@foodexpress.com');
    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Enter OTP'), findsNothing);

    await tester.enterText(find.byType(TextField).at(1), 'customer123');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('Enter OTP'), findsOneWidget);
  });

  testWidgets('LoginScreen shows connection errors and loading state', (
    tester,
  ) async {
    final completer = Completer<http.Response>();
    ApiService.setHttpClient(
      MockClient((request) => completer.future),
    );

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.enterText(
      find.byType(TextField).at(0),
      'customer@foodexpress.com',
    );
    await tester.enterText(find.byType(TextField).at(1), 'customer123');
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.completeError(Exception('offline'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Connection error:'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('RegisterScreen covers validation and successful registration', (
    tester,
  ) async {
    Map<String, dynamic>? registeredBody;
    ApiService.setHttpClient(
      MockClient((request) async {
        registeredBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('{"success":true}', 200);
      }),
    );

    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    final registerButton = find.widgetWithText(ElevatedButton, 'Register');

    Future<void> submitRegister() async {
      await tester.ensureVisible(registerButton);
      final button = tester.widget<ElevatedButton>(registerButton);
      button.onPressed!.call();
      await tester.pumpAndSettle();
    }

    Finder registerField(String label) {
      return find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == label,
      );
    }

    void setRegisterField(String label, String value) {
      final field = tester.widget<TextField>(registerField(label));
      field.controller!.text = value;
    }

    await submitRegister();
    expect(find.text('Please complete all required fields.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    setRegisterField('First Name *', 'Mint');
    setRegisterField('Last Name *', 'Ploy');
    setRegisterField('Email *', 'mint@example.com');
    setRegisterField('Mobile Number *', '+66 81 111 1111');
    setRegisterField('Delivery Address *', 'Bangkok');
    setRegisterField('Password *', 'secret123');
    setRegisterField('Confirm Password *', 'wrong123');
    setRegisterField('Credit Card Number *', '1234567890123456');
    setRegisterField('Expiry Date *', '12/30');
    setRegisterField('CVV *', '123');
    await tester.pump();
    await submitRegister();
    expect(find.text('Passwords do not match.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    setRegisterField('Confirm Password *', 'secret123');
    await tester.pump();
    await submitRegister();
    expect(registeredBody?['role'], 'CUSTOMER');
    expect(registeredBody?['deliveryAddress'], 'Bangkok');
    expect(
      registeredBody?['paymentInfo']['cardNumber'],
      '1234567890123456',
    );
  });

  testWidgets('RegisterScreen shows failure and connection error messages', (
    tester,
  ) async {
    var requestCount = 0;
    ApiService.setHttpClient(
      MockClient((request) async {
        requestCount += 1;
        if (requestCount == 1) {
          return http.Response(
            '{"success":false,"message":"Email already exists"}',
            400,
          );
        }
        throw Exception('server unavailable');
      }),
    );

    Future<void> fillRequiredFields() async {
      Finder registerField(String label) {
        return find.byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.decoration?.labelText == label,
        );
      }

      void setRegisterField(String label, String value) {
        final field = tester.widget<TextField>(registerField(label));
        field.controller!.text = value;
      }

      setRegisterField('First Name *', 'Mint');
      setRegisterField('Last Name *', 'Ploy');
      setRegisterField('Email *', 'mint@example.com');
      setRegisterField('Mobile Number *', '+66 81 111 1111');
      setRegisterField('Delivery Address *', 'Bangkok');
      setRegisterField('Password *', 'secret123');
      setRegisterField('Confirm Password *', 'secret123');
      setRegisterField('Credit Card Number *', '1234567890123456');
      setRegisterField('Expiry Date *', '12/30');
      setRegisterField('CVV *', '123');
      await tester.pump();
    }

    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    final registerButton = find.widgetWithText(ElevatedButton, 'Register');

    Future<void> submitRegister() async {
      await tester.ensureVisible(registerButton);
      final button = tester.widget<ElevatedButton>(registerButton);
      button.onPressed!.call();
      await tester.pumpAndSettle();
    }

    await fillRequiredFields();
    await submitRegister();
    expect(find.text('Email already exists'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await submitRegister();
    expect(requestCount, 2);
  });

  testWidgets(
      'CustomerHomeScreen covers search filtering and empty search state', (
    tester,
  ) async {
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
                    'rating': 4.8,
                  },
                  {
                    'id': 2,
                    'name': 'Burger Town',
                    'cuisine_type': 'American',
                    'address': 'Silom',
                    'estimated_delivery_time': 30,
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

    await tester.enterText(find.byType(TextField), 'burger');
    await tester.pumpAndSettle();
    expect(find.text('Burger Town'), findsOneWidget);
    expect(find.text('Bangkok Street Food'), findsNothing);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Bangkok Street Food'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No restaurants match your search'), findsOneWidget);
  });

  testWidgets(
    'CustomerHomeScreen covers empty state, logout, and orders navigation',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'token',
        'user_id': 7,
        'user_role': 'CUSTOMER',
        'user_email': 'customer@foodexpress.com',
      });

      var restaurantsCallCount = 0;
      ApiService.setHttpClient(
        MockClient((request) async {
          if (request.url.path.endsWith('/restaurants')) {
            restaurantsCallCount += 1;
            return http.Response(
              '{"success":true,"data":{"content":[]}}',
              200,
            );
          }
          return http.Response('{"success":false}', 404);
        }),
      );

      await tester.pumpWidget(const MaterialApp(home: CustomerHomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('No restaurants available right now'), findsOneWidget);

      await tester.fling(
        find.byType(ListView),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(restaurantsCallCount, greaterThan(1));

      await tester.tap(find.text('My Orders'));
      await tester.pumpAndSettle();
      expect(find.text('No orders yet'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();
      expect(find.text('Sign in to your account'), findsOneWidget);
    },
  );

  testWidgets('CustomerHomeScreen opens restaurant details on tap',
      (tester) async {
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
                    'estimated_delivery_time': 25,
                    'delivery_fee': 30,
                    'is_active': true,
                  },
                ],
              },
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/restaurants/1/menu')) {
          return http.Response(
            '{"success":true,"data":{"content":[]}}',
            200,
          );
        }
        return http.Response('{"success":false}', 404);
      }),
    );

    await tester.pumpWidget(const MaterialApp(home: CustomerHomeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bangkok Street Food'));
    await tester.pumpAndSettle();

    expect(find.text('No menu items available'), findsOneWidget);
  });

  testWidgets(
      'RestaurantDetailScreen covers empty state and cart quantity flow', (
    tester,
  ) async {
    var menuRequestCount = 0;
    ApiService.setHttpClient(
      MockClient((request) async {
        if (request.url.path.endsWith('/restaurants/1/menu')) {
          menuRequestCount += 1;
          if (menuRequestCount == 1) {
            return http.Response(
              '{"success":true,"data":{"content":[]}}',
              200,
            );
          }
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
        return http.Response('{"success":false}', 404);
      }),
    );

    final restaurant = Restaurant(
      id: 1,
      name: 'Bangkok Street Food',
      cuisineType: 'Thai',
      description: 'Street food',
      estimatedDeliveryTime: 25,
      deliveryFee: 30,
      isActive: true,
    );

    await tester.pumpWidget(
      MaterialApp(home: RestaurantDetailScreen(restaurant: restaurant)),
    );
    await tester.pumpAndSettle();
    expect(find.text('No menu items available'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: RestaurantDetailScreen(
          key: const ValueKey('loaded-detail'),
          restaurant: restaurant,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delivery ฿30 • 25 mins'), findsOneWidget);
    expect(find.text('Pad Thai'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
    expect(find.text('View Cart (1)'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();
    expect(find.text('View Cart (1)'), findsNothing);
  });

  testWidgets(
    'RestaurantDetailScreen filters unavailable items and opens checkout',
    (tester) async {
      ApiService.setHttpClient(
        MockClient((request) async {
          if (request.url.path.endsWith('/restaurants/2/menu')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'content': [
                    {
                      'id': 21,
                      'name': 'Green Curry',
                      'price': 140,
                      'category_name': 'Curry',
                      'is_available': true,
                    },
                    {
                      'id': 22,
                      'name': 'Hidden Item',
                      'price': 80,
                      'is_available': false,
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

      final restaurant = Restaurant(
        id: 2,
        name: 'Curry House',
        estimatedDeliveryTime: 20,
        deliveryFee: 25,
        isActive: true,
      );

      await tester.pumpWidget(
        MaterialApp(home: RestaurantDetailScreen(restaurant: restaurant)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Green Curry'), findsOneWidget);
      expect(find.text('Hidden Item'), findsNothing);
      expect(find.text('Delivery ฿25 • 20 mins'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View Cart (1)'));
      await tester.pumpAndSettle();

      expect(find.byType(CartScreen), findsOneWidget);
      expect(find.text('Checkout'), findsOneWidget);
    },
  );

  testWidgets(
    'RestaurantDetailScreen handles load failures with empty menu state',
    (tester) async {
      ApiService.setHttpClient(
        MockClient((request) async {
          throw Exception('menu failed');
        }),
      );

      final restaurant = Restaurant(
        id: 3,
        name: 'Failed Bistro',
        cuisineType: 'Fusion',
        description: 'Will retry later',
        isActive: true,
      );

      await tester.pumpWidget(
        MaterialApp(home: RestaurantDetailScreen(restaurant: restaurant)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fusion'), findsOneWidget);
      expect(find.text('Will retry later'), findsOneWidget);
      expect(find.text('No menu items available'), findsOneWidget);
    },
  );
}
