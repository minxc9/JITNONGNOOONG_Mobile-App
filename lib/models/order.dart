class Order {
  final int id;
  final String orderNumber;
  final int customerId;
  final String? customerName;
  final String? customerPhoneNumber;
  final int restaurantId;
  final String? restaurantName;
  final int? riderId;
  final String status;
  final double totalAmount;
  final double deliveryFee;
  final String? deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? specialInstructions;
  final int? restaurantReviewId;
  final int? restaurantRating;
  final String? restaurantReviewText;
  final String? restaurantReviewedAt;
  final List<OrderItem> orderItems;
  final String? createdAt;
  final String? estimatedDeliveryTime;
  final String? updatedAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    this.customerName,
    this.customerPhoneNumber,
    required this.restaurantId,
    this.restaurantName,
    this.riderId,
    required this.status,
    required this.totalAmount,
    required this.deliveryFee,
    this.deliveryAddress,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.specialInstructions,
    this.restaurantReviewId,
    this.restaurantRating,
    this.restaurantReviewText,
    this.restaurantReviewedAt,
    required this.orderItems,
    this.createdAt,
    this.estimatedDeliveryTime,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['orderItems'] ?? json['order_items'] ?? json['items'];
    final items = (rawItems as List<dynamic>? ?? [])
        .map((i) => OrderItem.fromJson(i))
        .toList();
    return Order(
      id: json['id'] ?? 0,
      orderNumber: json['orderNumber'] ?? json['order_number'] ?? '',
      customerId: json['customerId'] ?? json['customer_id'] ?? 0,
      customerName: json['customerName'] ?? json['customer_name'],
      customerPhoneNumber:
          json['customerPhoneNumber'] ?? json['customer_phone_number'],
      restaurantId: json['restaurantId'] ?? json['restaurant_id'] ?? 0,
      restaurantName: json['restaurantName'] ?? json['restaurant_name'],
      riderId: json['riderId'] ?? json['rider_id'],
      status: json['status'] ?? 'PENDING',
      totalAmount:
          (json['totalAmount'] ?? json['total_amount'] as num?)?.toDouble() ??
              0.0,
      deliveryFee:
          (json['deliveryFee'] ?? json['delivery_fee'] as num?)?.toDouble() ??
              0.0,
      deliveryAddress: json['deliveryAddress'] ?? json['delivery_address'],
      deliveryLatitude:
          (json['deliveryLatitude'] ?? json['delivery_latitude'] as num?)
              ?.toDouble(),
      deliveryLongitude:
          (json['deliveryLongitude'] ?? json['delivery_longitude'] as num?)
              ?.toDouble(),
      specialInstructions:
          json['specialInstructions'] ?? json['special_instructions'],
      restaurantReviewId:
          json['restaurantReviewId'] ?? json['restaurant_review_id'],
      restaurantRating: json['restaurantRating'] ?? json['restaurant_rating'],
      restaurantReviewText:
          json['restaurantReviewText'] ?? json['restaurant_review_text'],
      restaurantReviewedAt:
          json['restaurantReviewedAt'] ?? json['restaurant_reviewed_at'],
      orderItems: items,
      createdAt: json['createdAt'] ?? json['created_at'],
      estimatedDeliveryTime:
          json['estimatedDeliveryTime'] ?? json['estimated_delivery_time'],
      updatedAt: json['updatedAt'] ?? json['updated_at'],
    );
  }
}

class OrderItem {
  final int id;
  final String menuItemName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItem({
    required this.id,
    required this.menuItemName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      menuItemName: json['menuItemName'] ?? json['menu_item_name'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice:
          (json['unitPrice'] ?? json['unit_price'] as num?)?.toDouble() ?? 0.0,
      totalPrice:
          (json['totalPrice'] ?? json['total_price'] as num?)?.toDouble() ??
              0.0,
    );
  }
}
