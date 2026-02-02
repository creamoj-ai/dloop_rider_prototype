class Rider {
  final String name;
  final String email;
  final String avatarUrl;
  final int level;
  final int currentXp;
  final int xpToNextLevel;
  final int streak;
  final int totalOrders;
  final double totalEarnings;
  final double totalKm;
  final double avgRating;
  final DateTime memberSince;

  const Rider({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.level,
    required this.currentXp,
    required this.xpToNextLevel,
    required this.streak,
    required this.totalOrders,
    required this.totalEarnings,
    required this.totalKm,
    required this.avgRating,
    required this.memberSince,
  });
}
