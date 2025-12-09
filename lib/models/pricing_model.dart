class PricingModel {
  final String id;
  final String name;
  final double price;
  final int maxImages;
  final String? shortDescription;
  final List<String>? whatsIncluded;

  PricingModel({
    required this.id,
    required this.name,
    required this.price,
    required this.maxImages,
    this.shortDescription,
    this.whatsIncluded,
  });

  factory PricingModel.fromJson(Map<String, dynamic> json) {
    return PricingModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      maxImages: json['max_images'] as int,
      shortDescription: json['shortDescription'] as String?,
      whatsIncluded: json['whatsIncluded'] != null
          ? (json['whatsIncluded'] as List<dynamic>)
              .map((item) => item as String)
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'price': price,
      'max_images': maxImages,
      if (shortDescription != null) 'shortDescription': shortDescription,
      if (whatsIncluded != null) 'whatsIncluded': whatsIncluded,
    };
  }
}

