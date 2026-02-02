class MarketProduct {
  final String id;
  final String name;
  final double price;
  final double costPrice;
  final String category;
  final String imageUrl;
  final int viewsCount;
  final int soldCount;

  const MarketProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.costPrice,
    required this.category,
    required this.imageUrl,
    required this.viewsCount,
    required this.soldCount,
  });
}
