class PricingModel {
  final String id;
  final String name;
  final int price;
  final int maxImages;

  PricingModel({
    required this.id,
    required this.name,
    required this.price,
    required this.maxImages,
  });

  factory PricingModel.fromJson(Map<String, dynamic> json) {
    return PricingModel(
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

