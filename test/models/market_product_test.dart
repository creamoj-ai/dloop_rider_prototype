import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/market_product.dart';

void main() {
  group('MarketProduct', () {
    test('constructor sets all fields correctly', () {
      const product = MarketProduct(
        id: 'prod-001',
        name: 'Custodia Telefono',
        price: 19.99,
        costPrice: 8.50,
        category: 'accessori',
        imageUrl: 'https://example.com/phone-case.jpg',
        viewsCount: 120,
        soldCount: 15,
      );

      expect(product.id, 'prod-001');
      expect(product.name, 'Custodia Telefono');
      expect(product.price, 19.99);
      expect(product.costPrice, 8.50);
      expect(product.category, 'accessori');
      expect(product.imageUrl, 'https://example.com/phone-case.jpg');
      expect(product.viewsCount, 120);
      expect(product.soldCount, 15);
    });

    test('profit margin can be derived from price - costPrice', () {
      const product = MarketProduct(
        id: 'prod-002',
        name: 'Borraccia',
        price: 12.00,
        costPrice: 4.00,
        category: 'beverage',
        imageUrl: '',
        viewsCount: 50,
        soldCount: 8,
      );

      expect(product.price - product.costPrice, 8.00);
    });
  });
}
