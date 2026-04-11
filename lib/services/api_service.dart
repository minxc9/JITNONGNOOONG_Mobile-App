import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/admin_stats.dart';
import '../models/order.dart';
import '../models/restaurant.dart';
import '../models/user.dart';
import '../utils/session_manager.dart';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8080/api/v1";
  static const _contentTypeHeader = 'Content-Type';
  static const _jsonMimeType = 'application/json';
  static http.Client _client = http.Client();

  static void setHttpClient(http.Client client) {
    _client = client;
  }

  static void resetHttpClient() {
    _client = http.Client();
  }

  static Future<Map<String, String>> _headers() async {
    final token = await SessionManager.getToken();
    return {
      _contentTypeHeader: _jsonMimeType,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Uri _uri(String path) => Uri.parse('$baseUrl$path');

  static Future<http.Response> _postJson(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    return _client.post(
      _uri(path),
      headers: authenticated
          ? await _headers()
          : const {_contentTypeHeader: _jsonMimeType},
      body: body == null ? null : jsonEncode(body),
    );
  }

  static Future<http.Response> _putJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _client.put(
      _uri(path),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
  }

  static Future<http.Response> _get(String path) async {
    return _client.get(
      _uri(path),
      headers: await _headers(),
    );
  }

  static Future<http.Response> _delete(String path) async {
    return _client.delete(
      _uri(path),
      headers: await _headers(),
    );
  }

  static Future<http.Response> login(String email, String password) async {
    return _postJson(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
  }

  static Future<http.Response> verifyOtp(String email, String otp) async {
    return _postJson(
      '/auth/otp',
      body: {'email': email, 'otp': otp},
    );
  }

  static Future<http.Response> register(Map<String, dynamic> data) async {
    return _postJson('/auth/register', body: data);
  }

  static Future<http.Response> getRestaurants() async {
    return _get('/restaurants');
  }

  static Future<http.Response> getMenu(int restaurantId) async {
    return _get('/restaurants/$restaurantId/menu');
  }

  static Future<http.Response> getRestaurantByOwner(int ownerId) async {
    return _get('/restaurants/owner/$ownerId');
  }

  static Future<http.Response> getRestaurantById(int restaurantId) async {
    return _get('/restaurants/$restaurantId');
  }

  static Future<http.Response> getRestaurantCategories(int restaurantId) async {
    return _get('/restaurants/$restaurantId/categories');
  }

  static Future<http.Response> getRestaurantReviews(int restaurantId) async {
    return _get('/restaurants/$restaurantId/reviews');
  }

  static Future<http.Response> addMenuItem(
    int restaurantId,
    Map<String, dynamic> data,
  ) async {
    return _postJson(
      '/restaurants/$restaurantId/menu',
      body: data,
      authenticated: true,
    );
  }

  static Future<http.Response> updateMenuItem(
    int restaurantId,
    int itemId,
    Map<String, dynamic> data,
  ) async {
    return _putJson('/restaurants/$restaurantId/menu/$itemId', body: data);
  }

  static Future<http.Response> deleteMenuItem(
      int restaurantId, int itemId) async {
    return _delete('/restaurants/$restaurantId/menu/$itemId');
  }

  static Future<http.Response> submitRestaurantReview(
    int restaurantId,
    Map<String, dynamic> data,
  ) async {
    return _postJson(
      '/restaurants/$restaurantId/reviews',
      body: data,
      authenticated: true,
    );
  }

  static Future<http.Response> createOrder(Map<String, dynamic> data) async {
    return _postJson('/orders', body: data, authenticated: true);
  }

  static Future<http.Response> getCustomerOrders(int customerId) async {
    return _get('/orders/customer/$customerId');
  }

  static Future<http.Response> getRestaurantOrders(int restaurantId) async {
    return _get('/orders/restaurant/$restaurantId');
  }

  static Future<http.Response> getOrderById(int orderId) async {
    return _get('/orders/$orderId');
  }

  static Future<http.Response> updateOrderStatus(
    int orderId,
    String newStatus, {
    int? updatedBy,
    String? notes,
  }) async {
    return _putJson(
      '/orders/$orderId/status',
      body: {
        'newStatus': newStatus,
        if (updatedBy != null) 'updatedBy': updatedBy,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  static Future<http.Response> getAvailableOrders() async {
    return _get('/orders/rider/available');
  }

  static Future<http.Response> getRiderOrders(int riderId) async {
    return _get('/orders/rider/$riderId');
  }

  static Future<http.Response> acceptOrder(int riderId, int orderId) async {
    return updateOrderStatus(orderId, 'PICKED_UP', updatedBy: riderId);
  }

  static Future<http.Response> confirmDelivery(int riderId, int orderId) async {
    return updateOrderStatus(orderId, 'DELIVERED', updatedBy: riderId);
  }

  static Future<http.Response> cancelOrder(int orderId) async {
    return _delete('/orders/$orderId');
  }

  static Future<http.Response> processPayment(Map<String, dynamic> data) async {
    return _postJson('/payments/process', body: data, authenticated: true);
  }

  static Future<http.Response> getAllUsers() async {
    return _get('/admin/users');
  }

  static Future<http.Response> updateUserStatus(
      int userId, bool isActive) async {
    return _putJson(
      '/admin/users/$userId/status',
      body: {'isActive': isActive},
    );
  }

  static Future<http.Response> getAdminOrderStats() async {
    return _get('/orders/admin/stats');
  }

  static Future<http.Response> getAdminRestaurantStats() async {
    return _get('/restaurants/stats');
  }

  static Future<dynamic> _decode(http.Response response) async {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Request failed');
    }
    return body['data'];
  }

  static Future<Order> fetchOrder(int orderId) async {
    final data = await _decode(await getOrderById(orderId));
    return Order.fromJson(data);
  }

  static Future<List<Order>> fetchOrdersForCustomer(int customerId) async {
    final data = await _decode(await getCustomerOrders(customerId));
    final rows = data['content'] as List<dynamic>? ?? [];
    return rows.map((row) => Order.fromJson(row)).toList();
  }

  static Future<List<Order>> fetchOrdersForRestaurant(int restaurantId) async {
    final data = await _decode(await getRestaurantOrders(restaurantId));
    final rows = data['content'] as List<dynamic>? ?? [];
    return rows.map((row) => Order.fromJson(row)).toList();
  }

  static Future<List<Order>> fetchAvailableOrders() async {
    final data = await _decode(await getAvailableOrders());
    final rows = data['content'] as List<dynamic>? ?? [];
    return rows.map((row) => Order.fromJson(row)).toList();
  }

  static Future<List<Order>> fetchRiderOrders(int riderId) async {
    final data = await _decode(await getRiderOrders(riderId));
    final rows = data['content'] as List<dynamic>? ?? [];
    return rows.map((row) => Order.fromJson(row)).toList();
  }

  static Future<List<Restaurant>> fetchRestaurants() async {
    final data = await _decode(await getRestaurants());
    final rows =
        data['content'] as List<dynamic>? ?? data as List<dynamic>? ?? [];
    return rows.map((row) => Restaurant.fromJson(row)).toList();
  }

  static Future<Restaurant> fetchOwnedRestaurant(int ownerId) async {
    try {
      final data = await _decode(await getRestaurantByOwner(ownerId));
      final row = data is List<dynamic> && data.isNotEmpty
          ? Map<String, dynamic>.from(data.first as Map)
          : Map<String, dynamic>.from(data as Map);
      return Restaurant.fromJson(row);
    } catch (_) {
      final allRestaurants = await fetchRestaurants();
      final userEmail = await SessionManager.getUserEmail();
      final userName = await SessionManager.getUserName();

      final fallback = allRestaurants
          .where((restaurant) {
            final ownerMatches = restaurant.ownerId == ownerId;
            final emailMatches = userEmail != null &&
                restaurant.email != null &&
                restaurant.email!.toLowerCase() == userEmail.toLowerCase();
            final nameMatches = userName != null &&
                restaurant.name.toLowerCase().contains(userName.toLowerCase());
            return ownerMatches || emailMatches || nameMatches;
          })
          .cast<Restaurant?>()
          .firstWhere(
            (restaurant) => restaurant != null,
            orElse: () => null,
          );

      if (fallback != null) return fallback;
      rethrow;
    }
  }

  static Future<Restaurant> fetchRestaurant(int restaurantId) async {
    final data = await _decode(await getRestaurantById(restaurantId));
    return Restaurant.fromJson(Map<String, dynamic>.from(data as Map));
  }

  static Future<List<MenuItem>> fetchMenuItems(int restaurantId) async {
    final data = await _decode(await getMenu(restaurantId));
    final rows =
        data['content'] as List<dynamic>? ?? data as List<dynamic>? ?? [];
    return rows.map((row) => MenuItem.fromJson(row)).toList();
  }

  static Future<List<MenuCategory>> fetchCategories(int restaurantId) async {
    final data = await _decode(await getRestaurantCategories(restaurantId));
    final rows = data as List<dynamic>? ?? [];
    return rows.map((row) => MenuCategory.fromJson(row)).toList();
  }

  static Future<List<RestaurantReview>> fetchRestaurantReviews(
    int restaurantId,
  ) async {
    final data = await _decode(await getRestaurantReviews(restaurantId));
    final rows = data as List<dynamic>? ?? [];
    return rows.map((row) => RestaurantReview.fromJson(row)).toList();
  }

  static Future<List<User>> fetchUsers() async {
    final data = await _decode(await getAllUsers());
    final rows = data as List<dynamic>? ?? [];
    return rows.map((row) => User.fromJson(row)).toList();
  }

  static Future<OrderStats> fetchAdminOrderStats() async {
    final data = await _decode(await getAdminOrderStats());
    return OrderStats.fromJson(data);
  }

  static Future<RestaurantStats> fetchAdminRestaurantStats() async {
    final data = await _decode(await getAdminRestaurantStats());
    return RestaurantStats.fromJson(data);
  }
}
