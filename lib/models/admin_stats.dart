class OrderStats {
  final int todayOrders;
  final int monthOrders;
  final int totalOrders;
  final double todayRevenue;
  final double monthRevenue;

  const OrderStats({
    required this.todayOrders,
    required this.monthOrders,
    required this.totalOrders,
    required this.todayRevenue,
    required this.monthRevenue,
  });

  factory OrderStats.fromJson(Map<String, dynamic> json) {
    return OrderStats(
      todayOrders: json['todayOrders'] ?? 0,
      monthOrders: json['monthOrders'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      todayRevenue: (json['todayRevenue'] as num?)?.toDouble() ?? 0,
      monthRevenue: (json['monthRevenue'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RestaurantStats {
  final int totalRestaurants;
  final int activeRestaurants;

  const RestaurantStats({
    required this.totalRestaurants,
    required this.activeRestaurants,
  });

  factory RestaurantStats.fromJson(Map<String, dynamic> json) {
    return RestaurantStats(
      totalRestaurants: json['totalRestaurants'] ?? 0,
      activeRestaurants: json['activeRestaurants'] ?? 0,
    );
  }
}
