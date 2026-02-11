import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rider_contact.dart';
import '../utils/retry.dart';

class ContactsService {
  static final _client = Supabase.instance.client;

  static String? get _riderId => _client.auth.currentUser?.id;

  /// Real-time stream of all rider contacts
  static Stream<List<RiderContact>> subscribeToContacts() {
    final riderId = _riderId;
    if (riderId == null) return Stream.value([]);

    return retryStream(
      () => _client
          .from('rider_contacts')
          .stream(primaryKey: ['id'])
          .eq('rider_id', riderId)
          .order('created_at', ascending: true)
          .map((data) =>
              data.map((json) => RiderContact.fromJson(json)).toList()),
      onReconnect: (attempt, e) {
        print('⚡ ContactsService.subscribeToContacts reconnect $attempt: $e');
      },
    );
  }

  /// Add a new contact
  static Future<void> addContact({
    required String name,
    required String contactType,
    String status = 'active',
    String? phone,
  }) async {
    final riderId = _riderId;
    if (riderId == null) throw Exception('Not authenticated');

    await retry(() async {
      await _client.from('rider_contacts').insert({
        'rider_id': riderId,
        'name': name,
        'contact_type': contactType,
        'status': status,
        'phone': phone,
      });
    }, onRetry: (attempt, e) {
      print('⚡ ContactsService.addContact retry $attempt: $e');
    });
  }

  /// Delete a contact
  static Future<void> deleteContact(String contactId) async {
    await retry(() async {
      await _client.from('rider_contacts').delete().eq('id', contactId);
    });
  }
}
