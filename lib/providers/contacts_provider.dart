import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rider_contact.dart';
import '../services/contacts_service.dart';

/// Real-time stream of all rider contacts
final contactsStreamProvider = StreamProvider<List<RiderContact>>((ref) {
  return ContactsService.subscribeToContacts();
});

/// Dealers only
final dealersProvider = Provider<AsyncValue<List<RiderContact>>>((ref) {
  return ref.watch(contactsStreamProvider).whenData(
        (contacts) => contacts.where((c) => c.isDealer).toList(),
      );
});

/// Clients only
final clientsProvider = Provider<AsyncValue<List<RiderContact>>>((ref) {
  return ref.watch(contactsStreamProvider).whenData(
        (contacts) => contacts.where((c) => c.isClient).toList(),
      );
});

/// Active dealers count
final activeDealersCountProvider = Provider<int>((ref) {
  return ref.watch(dealersProvider).whenOrNull(
            data: (dealers) => dealers.where((d) => d.isActive).length,
          ) ??
      0;
});

/// Clients count
final clientsCountProvider = Provider<int>((ref) {
  return ref.watch(clientsProvider).whenOrNull(
            data: (clients) => clients.length,
          ) ??
      0;
});

/// Total monthly earnings from dealer contacts
final contactsMonthlyEarningsProvider = Provider<double>((ref) {
  return ref.watch(dealersProvider).whenOrNull(
            data: (dealers) =>
                dealers.fold<double>(0.0, (sum, d) => sum + d.monthlyEarnings),
          ) ??
      0;
});
