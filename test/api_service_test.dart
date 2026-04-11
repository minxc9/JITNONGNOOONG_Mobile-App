import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mhar_rueng_sang/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    ApiService.resetHttpClient();
  });

  group('ApiService request tests', () {
    test('authorized endpoints include bearer token header when saved',
        () async {
      SharedPreferences.setMockInitialValues({'jwt_token': 'abc123'});
      late Map<String, String> capturedHeaders;

      ApiService.setHttpClient(
        MockClient((request) async {
          capturedHeaders = request.headers;
          return http.Response('{"success":true,"data":{"content":[]}}', 200);
        }),
      );

      await ApiService.getRestaurants();

      expect(capturedHeaders['Authorization'], 'Bearer abc123');
      expect(capturedHeaders['Content-Type'], 'application/json');
    });

    test('login posts credentials to auth endpoint', () async {
      late Uri capturedUri;
      late Map<String, String> capturedHeaders;
      late Map<String, dynamic> capturedBody;

      ApiService.setHttpClient(
        MockClient((request) async {
          capturedUri = request.url;
          capturedHeaders = request.headers;
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{"success":true,"data":{}}', 200);
        }),
      );

      final response = await ApiService.login('user@example.com', 'secret123');

      expect(response.statusCode, 200);
      expect(capturedUri.toString(), '${ApiService.baseUrl}/auth/login');
      expect(capturedHeaders['Content-Type'], 'application/json');
      expect(
        capturedBody,
        {'email': 'user@example.com', 'password': 'secret123'},
      );
    });

    test('updateOrderStatus sends optional notes and updater fields', () async {
      late Map<String, dynamic> capturedBody;

      ApiService.setHttpClient(
        MockClient((request) async {
          expect(
            request.url.toString(),
            '${ApiService.baseUrl}/orders/17/status',
          );
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{"success":true,"data":{}}', 200);
        }),
      );

      final response = await ApiService.updateOrderStatus(
        17,
        'DELIVERED',
        updatedBy: 5,
        notes: 'Customer received order',
      );

      expect(response.statusCode, 200);
      expect(
        capturedBody,
        {
          'newStatus': 'DELIVERED',
          'updatedBy': 5,
          'notes': 'Customer received order',
        },
      );
    });

    test('fetchOrdersForCustomer returns decoded order list', () async {
      ApiService.setHttpClient(
        MockClient((request) async {
          expect(
            request.url.toString(),
            '${ApiService.baseUrl}/orders/customer/11',
          );
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'content': [
                  {
                    'id': 10,
                    'orderNumber': 'ORD-001',
                    'customerId': 11,
                    'restaurantId': 30,
                    'status': 'PENDING',
                    'totalAmount': 155.0,
                    'deliveryFee': 35.0,
                    'orderItems': [
                      {
                        'id': 1,
                        'menuItemName': 'Pad Thai',
                        'quantity': 2,
                        'unitPrice': 60.0,
                        'totalPrice': 120.0,
                      },
                    ],
                  },
                ],
              },
            }),
            200,
          );
        }),
      );

      final orders = await ApiService.fetchOrdersForCustomer(11);

      expect(orders, hasLength(1));
      expect(orders.first.orderNumber, 'ORD-001');
      expect(orders.first.orderItems.first.menuItemName, 'Pad Thai');
      expect(orders.first.totalAmount, 155.0);
    });

    test('fetchRestaurants supports paged payload structure', () async {
      ApiService.setHttpClient(
        MockClient((request) async {
          expect(request.url.toString(), '${ApiService.baseUrl}/restaurants');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'content': [
                  {
                    'id': 8,
                    'name': 'Bangkok Street Food',
                    'cuisine_type': 'Thai',
                    'average_rating': 4.8,
                    'is_active': true,
                  },
                ],
              },
            }),
            200,
          );
        }),
      );

      final restaurants = await ApiService.fetchRestaurants();

      expect(restaurants, hasLength(1));
      expect(restaurants.first.name, 'Bangkok Street Food');
      expect(restaurants.first.cuisineType, 'Thai');
      expect(restaurants.first.rating, 4.8);
    });

    test('fetchOwnedRestaurant falls back to restaurant list matching email',
        () async {
      SharedPreferences.setMockInitialValues({
        'user_email': 'sushi@foodexpress.com',
        'user_name': 'Sushi Shop',
      });

      ApiService.setHttpClient(
        MockClient((request) async {
          if (request.url.toString() ==
              '${ApiService.baseUrl}/restaurants/owner/77') {
            return http.Response(
              '{"success":false,"message":"Owner route unavailable"}',
              500,
            );
          }

          if (request.url.toString() == '${ApiService.baseUrl}/restaurants') {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'content': [
                    {
                      'id': 5,
                      'name': 'Sushi Shop',
                      'email': 'sushi@foodexpress.com',
                      'ownerId': 99,
                      'isActive': true,
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

      final restaurant = await ApiService.fetchOwnedRestaurant(77);

      expect(restaurant.id, 5);
      expect(restaurant.name, 'Sushi Shop');
      expect(restaurant.email, 'sushi@foodexpress.com');
    });

    test('fetchOrder throws when backend reports failure', () async {
      ApiService.setHttpClient(
        MockClient(
          (_) async => http.Response(
            '{"success":false,"message":"Order not found"}',
            404,
          ),
        ),
      );

      expect(
        () => ApiService.fetchOrder(999),
        throwsA(isA<Exception>()),
      );
    });

    test('fetchOrder returns decoded order on success', () async {
      ApiService.setHttpClient(
        MockClient(
          (_) async => http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 20,
                'orderNumber': 'ORD-020',
                'customerId': 2,
                'restaurantId': 7,
                'status': 'DELIVERED',
                'totalAmount': 240.0,
                'deliveryFee': 35.0,
                'orderItems': [],
              },
            }),
            200,
          ),
        ),
      );

      final order = await ApiService.fetchOrder(20);

      expect(order.id, 20);
      expect(order.orderNumber, 'ORD-020');
      expect(order.status, 'DELIVERED');
    });

    test('raw backend endpoint helpers use the expected HTTP routes', () async {
      final requests = <String, String>{};

      ApiService.setHttpClient(
        MockClient((request) async {
          requests['${request.method} ${request.url.path}'] = request.body;
          return http.Response('{"success":true,"data":{"content":[]}}', 200);
        }),
      );

      await ApiService.verifyOtp('user@example.com', '123456');
      await ApiService.register({'role': 'CUSTOMER'});
      await ApiService.getMenu(8);
      await ApiService.getRestaurantByOwner(2);
      await ApiService.getRestaurantById(8);
      await ApiService.getRestaurantCategories(8);
      await ApiService.getRestaurantReviews(8);
      await ApiService.addMenuItem(8, {'name': 'Pad Thai'});
      await ApiService.updateMenuItem(8, 4, {'name': 'Tom Yum'});
      await ApiService.deleteMenuItem(8, 4);
      await ApiService.submitRestaurantReview(8, {'rating': 5});
      await ApiService.createOrder({'customerId': 1});
      await ApiService.getRestaurantOrders(8);
      await ApiService.getAvailableOrders();
      await ApiService.getRiderOrders(6);
      await ApiService.acceptOrder(6, 40);
      await ApiService.confirmDelivery(6, 40);
      await ApiService.cancelOrder(40);
      await ApiService.processPayment({'amount': 240});
      await ApiService.getAllUsers();
      await ApiService.updateUserStatus(4, false);
      await ApiService.getAdminOrderStats();
      await ApiService.getAdminRestaurantStats();

      expect(requests.keys, contains('POST /api/v1/auth/otp'));
      expect(requests.keys, contains('POST /api/v1/auth/register'));
      expect(requests.keys, contains('GET /api/v1/restaurants/8/menu'));
      expect(requests.keys, contains('GET /api/v1/restaurants/owner/2'));
      expect(requests.keys, contains('GET /api/v1/restaurants/8'));
      expect(requests.keys, contains('GET /api/v1/restaurants/8/categories'));
      expect(requests.keys, contains('GET /api/v1/restaurants/8/reviews'));
      expect(requests.keys, contains('POST /api/v1/restaurants/8/menu'));
      expect(requests.keys, contains('PUT /api/v1/restaurants/8/menu/4'));
      expect(requests.keys, contains('DELETE /api/v1/restaurants/8/menu/4'));
      expect(requests.keys, contains('POST /api/v1/restaurants/8/reviews'));
      expect(requests.keys, contains('POST /api/v1/orders'));
      expect(requests.keys, contains('GET /api/v1/orders/restaurant/8'));
      expect(requests.keys, contains('GET /api/v1/orders/rider/available'));
      expect(requests.keys, contains('GET /api/v1/orders/rider/6'));
      expect(requests.keys, contains('PUT /api/v1/orders/40/status'));
      expect(requests.keys, contains('DELETE /api/v1/orders/40'));
      expect(requests.keys, contains('POST /api/v1/payments/process'));
      expect(requests.keys, contains('GET /api/v1/admin/users'));
      expect(requests.keys, contains('PUT /api/v1/admin/users/4/status'));
      expect(requests.keys, contains('GET /api/v1/orders/admin/stats'));
      expect(requests.keys, contains('GET /api/v1/restaurants/stats'));
      expect(
        jsonDecode(requests['PUT /api/v1/orders/40/status']!)
            as Map<String, dynamic>,
        containsPair('newStatus', 'DELIVERED'),
      );
    });

    test(
        'fetch helpers decode restaurant, menu, category, review, user, and stats payloads',
        () async {
      ApiService.setHttpClient(
        MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/restaurants/5/menu')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'content': [
                    {
                      'id': 1,
                      'name': 'Pad Thai',
                      'price': 120,
                      'category_name': 'Noodles',
                      'is_available': true,
                    },
                  ],
                },
              }),
              200,
            );
          }
          if (path.endsWith('/restaurants/5/categories')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': [
                  {'id': 10, 'restaurant_id': 5, 'name': 'Noodles'},
                ],
              }),
              200,
            );
          }
          if (path.endsWith('/restaurants/5/reviews')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': [
                  {
                    'id': 4,
                    'restaurant_id': 5,
                    'order_id': 20,
                    'customer_id': 8,
                    'customer_name': 'Mint',
                    'rating': 5,
                    'review_text': 'Excellent',
                  },
                ],
              }),
              200,
            );
          }
          if (path.endsWith('/admin/users')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': [
                  {
                    'id': 7,
                    'name': 'Rider One',
                    'email': 'rider@example.com',
                    'role': 'RIDER',
                  },
                ],
              }),
              200,
            );
          }
          if (path.endsWith('/orders/admin/stats')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'todayOrders': 9,
                  'monthOrders': 60,
                  'totalOrders': 100,
                  'todayRevenue': 999.0,
                  'monthRevenue': 4567.0,
                },
              }),
              200,
            );
          }
          if (path.endsWith('/restaurants/stats')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'totalRestaurants': 20,
                  'activeRestaurants': 16,
                },
              }),
              200,
            );
          }
          return http.Response('{"success":false}', 404);
        }),
      );

      final menuItems = await ApiService.fetchMenuItems(5);
      final categories = await ApiService.fetchCategories(5);
      final reviews = await ApiService.fetchRestaurantReviews(5);
      final users = await ApiService.fetchUsers();
      final orderStats = await ApiService.fetchAdminOrderStats();
      final restaurantStats = await ApiService.fetchAdminRestaurantStats();

      expect(menuItems.single.category, 'Noodles');
      expect(categories.single.name, 'Noodles');
      expect(reviews.single.reviewText, 'Excellent');
      expect(users.single.role, 'RIDER');
      expect(orderStats.todayRevenue, 999.0);
      expect(restaurantStats.activeRestaurants, 16);
    });

    test(
        'fetchOrdersForRestaurant, fetchAvailableOrders, and fetchRiderOrders decode content lists',
        () async {
      ApiService.setHttpClient(
        MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'content': [
                  {
                    'id': 50,
                    'orderNumber': 'ORD-050',
                    'customerId': 10,
                    'restaurantId': 5,
                    'status': 'PICKED_UP',
                    'totalAmount': 300.0,
                    'deliveryFee': 20.0,
                    'orderItems': [],
                  },
                ],
              },
            }),
            200,
          );
        }),
      );

      final restaurantOrders = await ApiService.fetchOrdersForRestaurant(5);
      final availableOrders = await ApiService.fetchAvailableOrders();
      final riderOrders = await ApiService.fetchRiderOrders(9);

      expect(restaurantOrders.single.orderNumber, 'ORD-050');
      expect(availableOrders.single.status, 'PICKED_UP');
      expect(riderOrders.single.totalAmount, 300.0);
    });

    test('fetchOwnedRestaurant supports successful owner endpoint map payload',
        () async {
      ApiService.setHttpClient(
        MockClient(
          (_) async => http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 15,
                'name': 'Owner Restaurant',
                'ownerId': 15,
                'isActive': true,
              },
            }),
            200,
          ),
        ),
      );

      final restaurant = await ApiService.fetchOwnedRestaurant(15);

      expect(restaurant.ownerId, 15);
      expect(restaurant.name, 'Owner Restaurant');
    });

    test('fetchOwnedRestaurant rethrows when fallback cannot match anything',
        () async {
      SharedPreferences.setMockInitialValues({
        'user_email': 'unknown@example.com',
        'user_name': 'No Match',
      });

      ApiService.setHttpClient(
        MockClient((request) async {
          if (request.url.path.endsWith('/restaurants/owner/88')) {
            return http.Response('{"success":false,"message":"boom"}', 500);
          }
          if (request.url.path.endsWith('/restaurants')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'content': [
                    {'id': 1, 'name': 'Bangkok Bites', 'ownerId': 2},
                  ],
                },
              }),
              200,
            );
          }
          return http.Response('{"success":false}', 404);
        }),
      );

      expect(
        () => ApiService.fetchOwnedRestaurant(88),
        throwsA(isA<Exception>()),
      );
    });

    test('fetchRestaurant decodes a single restaurant payload', () async {
      ApiService.setHttpClient(
        MockClient(
          (_) async => http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 9,
                'name': 'Big Burger House',
                'isActive': true,
              },
            }),
            200,
          ),
        ),
      );

      final restaurant = await ApiService.fetchRestaurant(9);

      expect(restaurant.id, 9);
      expect(restaurant.name, 'Big Burger House');
    });
  });
}
