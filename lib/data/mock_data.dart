import '../models/earning.dart';
import '../models/rider.dart';
import '../models/network_node.dart';
import '../models/market_product.dart';

class MockData {
  MockData._();

  static final rider = Rider(
    name: 'Marco Rossi',
    email: 'marco.rossi@dloop.it',
    avatarUrl: 'https://i.pravatar.cc/150?img=12',
    level: 7,
    currentXp: 2340,
    xpToNextLevel: 3000,
    streak: 12,
    totalOrders: 1847,
    totalEarnings: 24680.50,
    totalKm: 8420.3,
    avgRating: 4.87,
    memberSince: DateTime(2024, 3, 15),
  );

  static const double todayEarnings = 142.60;
  static const int todayOrders = 8;
  static const int currentStreak = 12;
  static const double hourlyRate = 14.80;
  static const double hoursActive = 6.5;
  static const double balance = 1847.50;
  static const double pendingBalance = 234.20;
  static const double weekEarnings = 687.40;
  static const String currentMode = 'delivering';
  static const String currentZone = 'Milano Centro';

  static const double networkMonthlyIncome = 340.00;
  static const double marketMonthlyIncome = 180.00;
  static const double deliveryMonthlyIncome = 2400.00;

  static final List<Earning> transactions = [
    Earning(id: 'e1', type: EarningType.delivery, description: 'Consegna #4821', amount: 8.50, dateTime: DateTime.now().subtract(const Duration(minutes: 22)), status: EarningStatus.completed),
    Earning(id: 'e2', type: EarningType.delivery, description: 'Consegna #4820', amount: 12.00, dateTime: DateTime.now().subtract(const Duration(hours: 1)), status: EarningStatus.completed),
    Earning(id: 'e3', type: EarningType.network, description: 'Commissione rete - Luigi', amount: 3.40, dateTime: DateTime.now().subtract(const Duration(hours: 2)), status: EarningStatus.completed),
    Earning(id: 'e4', type: EarningType.delivery, description: 'Consegna #4819', amount: 15.20, dateTime: DateTime.now().subtract(const Duration(hours: 3)), status: EarningStatus.completed),
    Earning(id: 'e5', type: EarningType.market, description: 'Vendita - Power Bank', amount: 8.00, dateTime: DateTime.now().subtract(const Duration(hours: 4)), status: EarningStatus.completed),
    Earning(id: 'e6', type: EarningType.delivery, description: 'Consegna #4818', amount: 9.80, dateTime: DateTime.now().subtract(const Duration(hours: 5)), status: EarningStatus.completed),
    Earning(id: 'e7', type: EarningType.network, description: 'Bonus referral - Anna', amount: 25.00, dateTime: DateTime.now().subtract(const Duration(hours: 6)), status: EarningStatus.pending),
    Earning(id: 'e8', type: EarningType.delivery, description: 'Consegna #4817', amount: 11.50, dateTime: DateTime.now().subtract(const Duration(hours: 7)), status: EarningStatus.completed),
    Earning(id: 'e9', type: EarningType.market, description: 'Vendita - Cavo USB-C', amount: 4.20, dateTime: DateTime.now().subtract(const Duration(hours: 8)), status: EarningStatus.completed),
    Earning(id: 'e10', type: EarningType.delivery, description: 'Consegna #4816', amount: 45.00, dateTime: DateTime.now().subtract(const Duration(hours: 9)), status: EarningStatus.completed),
  ];

  static const List<NetworkNode> dealers = [
    NetworkNode(id: 'd1', name: 'Pizzeria Da Mario', type: NodeType.dealer, status: NodeStatus.active, totalOrders: 342, totalSpent: 4200.00, isVip: true, distance: 0.8),
    NetworkNode(id: 'd2', name: 'Sushi Zen', type: NodeType.dealer, status: NodeStatus.active, totalOrders: 187, totalSpent: 2800.00, isVip: false, distance: 1.2),
    NetworkNode(id: 'd3', name: 'Burger Lab', type: NodeType.dealer, status: NodeStatus.active, totalOrders: 95, totalSpent: 1400.00, isVip: false, distance: 2.1),
    NetworkNode(id: 'd4', name: 'Pasticceria Dolce', type: NodeType.dealer, status: NodeStatus.potential, totalOrders: 0, totalSpent: 0, isVip: false, distance: 0.5),
  ];

  static const List<NetworkNode> clients = [
    NetworkNode(id: 'c1', name: 'Luigi Bianchi', type: NodeType.client, status: NodeStatus.active, totalOrders: 48, totalSpent: 720.00, isVip: true, distance: 1.0),
    NetworkNode(id: 'c2', name: 'Anna Verdi', type: NodeType.client, status: NodeStatus.active, totalOrders: 32, totalSpent: 480.00, isVip: false, distance: 1.5),
    NetworkNode(id: 'c3', name: 'Paolo Neri', type: NodeType.client, status: NodeStatus.active, totalOrders: 21, totalSpent: 315.00, isVip: false, distance: 0.7),
    NetworkNode(id: 'c4', name: 'Giulia Romano', type: NodeType.client, status: NodeStatus.potential, totalOrders: 3, totalSpent: 45.00, isVip: false, distance: 2.3),
    NetworkNode(id: 'c5', name: 'Stefano Colombo', type: NodeType.client, status: NodeStatus.active, totalOrders: 15, totalSpent: 225.00, isVip: false, distance: 1.8),
  ];

  static const List<MarketProduct> products = [
    MarketProduct(id: 'p1', name: 'Power Bank 10000mAh', price: 24.99, costPrice: 12.00, category: 'Tech', imageUrl: '', viewsCount: 342, soldCount: 28),
    MarketProduct(id: 'p2', name: 'Cavo USB-C 2m', price: 9.99, costPrice: 3.50, category: 'Tech', imageUrl: '', viewsCount: 518, soldCount: 67),
    MarketProduct(id: 'p3', name: 'Supporto Telefono Bici', price: 14.99, costPrice: 6.00, category: 'Accessori', imageUrl: '', viewsCount: 210, soldCount: 15),
    MarketProduct(id: 'p4', name: 'Guanti Touch Screen', price: 12.99, costPrice: 4.50, category: 'Abbigliamento', imageUrl: '', viewsCount: 189, soldCount: 22),
    MarketProduct(id: 'p5', name: 'Luce LED Bici Set', price: 19.99, costPrice: 8.00, category: 'Accessori', imageUrl: '', viewsCount: 276, soldCount: 31),
    MarketProduct(id: 'p6', name: 'Borraccia Termica 750ml', price: 16.99, costPrice: 7.00, category: 'Accessori', imageUrl: '', viewsCount: 154, soldCount: 12),
  ];
}
