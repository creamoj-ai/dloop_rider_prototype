/// Dispatch scoring information attached to an order assignment.
class DispatchInfo {
  final double score;
  final Map<String, double> factors;
  final double distanceKm;
  final int attemptNumber;
  final DateTime createdAt;

  const DispatchInfo({
    required this.score,
    required this.factors,
    required this.distanceKm,
    required this.attemptNumber,
    required this.createdAt,
  });

  factory DispatchInfo.fromJson(Map<String, dynamic> json) {
    final rawFactors = json['factors_json'] as Map<String, dynamic>? ?? {};
    return DispatchInfo(
      score: (json['score'] as num?)?.toDouble() ?? 0,
      factors: rawFactors.map((k, v) => MapEntry(k, (v as num).toDouble())),
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      attemptNumber: (json['attempt_number'] as num?)?.toInt() ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  String get scoreLabel => '${(score * 100).toStringAsFixed(0)}%';

  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km';
}
