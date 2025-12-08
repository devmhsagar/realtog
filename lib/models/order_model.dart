class OrderModel {
  final String id;
  final String user;
  final OrderPlan plan;
  final String status;
  final List<OrderImage> images;
  final List<dynamic> submissions;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    required this.user,
    required this.plan,
    required this.status,
    required this.images,
    required this.submissions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['_id'] as String,
      user: json['user'] as String,
      plan: OrderPlan.fromJson(json['plan'] as Map<String, dynamic>),
      status: json['status'] as String,
      images: (json['images'] as List<dynamic>)
          .map((image) => OrderImage.fromJson(image as Map<String, dynamic>))
          .toList(),
      submissions: json['submissions'] as List<dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': user,
      'plan': plan.toJson(),
      'status': status,
      'images': images.map((image) => image.toJson()).toList(),
      'submissions': submissions,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class OrderPlan {
  final String id;
  final String name;
  final int price;
  final int maxImages;

  OrderPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.maxImages,
  });

  factory OrderPlan.fromJson(Map<String, dynamic> json) {
    return OrderPlan(
      id: json['_id'] as String,
      name: json['name'] as String,
      price: json['price'] as int,
      maxImages: json['max_images'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'price': price,
      'max_images': maxImages,
    };
  }
}

class OrderImage {
  final String id;
  final String url;

  OrderImage({
    required this.id,
    required this.url,
  });

  factory OrderImage.fromJson(Map<String, dynamic> json) {
    return OrderImage(
      id: json['_id'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'url': url,
    };
  }
}

