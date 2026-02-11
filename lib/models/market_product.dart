class MarketProduct {
  final String id;
  final String riderId;
  final String name;
  final String description;
  final double price;
  final double costPrice;
  final String category;
  final String imageUrl;
  final int stock;
  final bool isActive;
  final int soldCount;
  final int viewsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MarketProduct({
    required this.id,
    this.riderId = '',
    required this.name,
    this.description = '',
    required this.price,
    this.costPrice = 0,
    required this.category,
    this.imageUrl = '',
    this.stock = 0,
    this.isActive = true,
    this.soldCount = 0,
    this.viewsCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  double get profit => price - costPrice;
  bool get isInStock => stock > 0;
  double get marginPercent => costPrice > 0 ? ((price - costPrice) / price) * 100 : 100;

  factory MarketProduct.fromJson(Map<String, dynamic> json) {
    return MarketProduct(
      id: json['id']?.toString() ?? '',
      riderId: json['rider_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      costPrice: double.tryParse(json['cost_price']?.toString() ?? '0') ?? 0,
      category: json['category'] as String? ?? 'altro',
      imageUrl: json['image_url'] as String? ?? '',
      stock: int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      soldCount: int.tryParse(json['sold_count']?.toString() ?? '0') ?? 0,
      viewsCount: int.tryParse(json['views_count']?.toString() ?? '0') ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'cost_price': costPrice,
      'category': category,
      'image_url': imageUrl,
      'stock': stock,
      'is_active': isActive,
    };
  }
}
