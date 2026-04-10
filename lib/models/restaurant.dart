class Restaurant {
  final int id;
  final String name;
  final String? description;
  final String? cuisineType;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? phoneNumber;
  final String? email;
  final int? ownerId;
  final String? imageUrl;
  final double? rating;
  final double? deliveryFee;
  final double? minimumOrderAmount;
  final int? estimatedDeliveryTime;
  final bool isActive;

  Restaurant({
    required this.id,
    required this.name,
    this.description,
    this.cuisineType,
    this.address,
    this.latitude,
    this.longitude,
    this.phoneNumber,
    this.email,
    this.ownerId,
    this.imageUrl,
    this.rating,
    this.deliveryFee,
    this.minimumOrderAmount,
    this.estimatedDeliveryTime,
    required this.isActive,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      cuisineType: json['cuisineType'] ?? json['cuisine_type'],
      address: json['address'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      phoneNumber: json['phoneNumber'] ?? json['phone_number'],
      email: json['email'],
      ownerId: json['ownerId'] ?? json['owner_id'],
      imageUrl: json['imageUrl'] ?? json['image_url'],
      rating: (json['averageRating'] ??
              json['average_rating'] ??
              json['rating'] as num?)
          ?.toDouble(),
      deliveryFee:
          (json['deliveryFee'] ?? json['delivery_fee'] as num?)?.toDouble(),
      minimumOrderAmount:
          (json['minimumOrderAmount'] ?? json['minimum_order_amount'] as num?)
              ?.toDouble(),
      estimatedDeliveryTime:
          json['estimatedDeliveryTime'] ?? json['estimated_delivery_time'],
      isActive: json['isActive'] ?? json['is_active'] ?? true,
    );
  }
}

class MenuItem {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int? categoryId;
  final String? category;
  final String? imageUrl;
  final bool isAvailable;
  int quantity;

  MenuItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.categoryId,
    this.category,
    this.imageUrl,
    required this.isAvailable,
    this.quantity = 0,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      categoryId: json['categoryId'] ?? json['category_id'],
      category:
          json['categoryName'] ?? json['category_name'] ?? json['category'],
      imageUrl: json['imageUrl'] ?? json['image_url'],
      isAvailable: json['isAvailable'] ?? json['is_available'] ?? true,
    );
  }
}

class MenuCategory {
  final int id;
  final int? restaurantId;
  final String name;
  final String? description;
  final int displayOrder;
  final bool isLocalOnly;

  const MenuCategory({
    required this.id,
    this.restaurantId,
    required this.name,
    this.description,
    this.displayOrder = 0,
    this.isLocalOnly = false,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      id: json['id'] ?? 0,
      restaurantId: json['restaurantId'] ?? json['restaurant_id'],
      name: json['name'] ?? '',
      description: json['description'],
      displayOrder: json['displayOrder'] ?? json['display_order'] ?? 0,
      isLocalOnly: json['isLocalOnly'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'restaurantId': restaurantId,
        'name': name,
        'description': description,
        'displayOrder': displayOrder,
        'isLocalOnly': isLocalOnly,
      };
}

class RestaurantReview {
  final int id;
  final int restaurantId;
  final int orderId;
  final int customerId;
  final String customerName;
  final int rating;
  final String? reviewText;
  final String? createdAt;

  const RestaurantReview({
    required this.id,
    required this.restaurantId,
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    this.reviewText,
    this.createdAt,
  });

  factory RestaurantReview.fromJson(Map<String, dynamic> json) {
    return RestaurantReview(
      id: json['id'] ?? 0,
      restaurantId: json['restaurantId'] ?? json['restaurant_id'] ?? 0,
      orderId: json['orderId'] ?? json['order_id'] ?? 0,
      customerId: json['customerId'] ?? json['customer_id'] ?? 0,
      customerName: json['customerName'] ?? json['customer_name'] ?? 'Customer',
      rating: json['rating'] ?? 0,
      reviewText: json['reviewText'] ?? json['review_text'],
      createdAt: json['createdAt'] ?? json['created_at'],
    );
  }
}
