import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fee_audit.dart';
import '../services/fee_audit_service.dart';

/// Get fee audit for a specific order.
final feeAuditProvider =
    FutureProvider.family<FeeAudit?, String>((ref, orderId) async {
  return FeeAuditService.getFeesForOrder(orderId);
});

/// Get recent fee audit records for the current rider.
final recentFeesProvider = FutureProvider<List<FeeAudit>>((ref) async {
  return FeeAuditService.getRecentFees();
});

/// Stream all fee audit records.
final feesStreamProvider = StreamProvider<List<FeeAudit>>((ref) {
  return FeeAuditService.streamFees();
});
