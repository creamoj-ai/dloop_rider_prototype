import 'package:flutter_test/flutter_test.dart';
import 'package:dloop_rider_prototype/models/rider_contact.dart';

void main() {
  group('RiderContact.fromJson', () {
    test('with complete data', () {
      final json = {
        'id': 'contact-001',
        'rider_id': 'rider-abc',
        'name': 'Pizzeria Da Michele',
        'contact_type': 'dealer',
        'status': 'active',
        'phone': '+39 081 5539204',
        'total_orders': 45,
        'monthly_earnings': 350.50,
        'created_at': '2026-01-15T10:00:00Z',
      };

      final contact = RiderContact.fromJson(json);

      expect(contact.id, 'contact-001');
      expect(contact.riderId, 'rider-abc');
      expect(contact.name, 'Pizzeria Da Michele');
      expect(contact.contactType, 'dealer');
      expect(contact.status, 'active');
      expect(contact.phone, '+39 081 5539204');
      expect(contact.totalOrders, 45);
      expect(contact.monthlyEarnings, 350.50);
      expect(contact.createdAt.year, 2026);
    });

    test('with phone null', () {
      final json = {
        'id': 'contact-002',
        'rider_id': 'rider-abc',
        'name': 'Cliente Test',
        'contact_type': 'client',
        'status': 'vip',
        'phone': null,
        'total_orders': 10,
        'monthly_earnings': 0,
        'created_at': '2026-02-01T10:00:00Z',
      };

      final contact = RiderContact.fromJson(json);
      expect(contact.phone, isNull);
    });

    test('with missing/null fields uses defaults', () {
      final json = <String, dynamic>{
        'id': null,
        'rider_id': null,
      };

      final contact = RiderContact.fromJson(json);

      expect(contact.id, '');
      expect(contact.riderId, '');
      expect(contact.name, '');
      expect(contact.contactType, 'client');
      expect(contact.status, 'active');
      expect(contact.phone, isNull);
      expect(contact.totalOrders, 0);
      expect(contact.monthlyEarnings, 0.0);
    });

    test('with numeric fields as strings', () {
      final json = {
        'id': 'contact-003',
        'rider_id': 'r1',
        'name': 'Test',
        'contact_type': 'dealer',
        'status': 'active',
        'total_orders': '25',
        'monthly_earnings': '175.50',
        'created_at': '2026-02-10T12:00:00Z',
      };

      final contact = RiderContact.fromJson(json);
      expect(contact.totalOrders, 25);
      expect(contact.monthlyEarnings, 175.50);
    });
  });

  group('RiderContact computed properties', () {
    test('isDealer for dealer type', () {
      final contact = RiderContact(
        id: '1',
        riderId: 'r1',
        name: 'Dealer Test',
        contactType: 'dealer',
        createdAt: DateTime(2026, 2, 10),
      );

      expect(contact.isDealer, true);
      expect(contact.isClient, false);
    });

    test('isClient for client type', () {
      final contact = RiderContact(
        id: '2',
        riderId: 'r1',
        name: 'Client Test',
        contactType: 'client',
        createdAt: DateTime(2026, 2, 10),
      );

      expect(contact.isDealer, false);
      expect(contact.isClient, true);
    });

    test('isVip for vip status', () {
      final contact = RiderContact(
        id: '3',
        riderId: 'r1',
        name: 'VIP Client',
        contactType: 'client',
        status: 'vip',
        createdAt: DateTime(2026, 2, 10),
      );

      expect(contact.isVip, true);
      expect(contact.isActive, true); // vip is also active
      expect(contact.isPotential, false);
    });

    test('isActive for active status', () {
      final contact = RiderContact(
        id: '4',
        riderId: 'r1',
        name: 'Active Dealer',
        contactType: 'dealer',
        status: 'active',
        createdAt: DateTime(2026, 2, 10),
      );

      expect(contact.isActive, true);
      expect(contact.isVip, false);
      expect(contact.isPotential, false);
    });

    test('isPotential for potential status', () {
      final contact = RiderContact(
        id: '5',
        riderId: 'r1',
        name: 'Potential Dealer',
        contactType: 'dealer',
        status: 'potential',
        createdAt: DateTime(2026, 2, 10),
      );

      expect(contact.isPotential, true);
      expect(contact.isActive, false);
      expect(contact.isVip, false);
    });
  });

  group('RiderContact.toInsertJson', () {
    test('includes rider_id and excludes id/created_at', () {
      final contact = RiderContact(
        id: 'should-not-appear',
        riderId: 'should-be-overridden',
        name: 'New Dealer',
        contactType: 'dealer',
        status: 'potential',
        phone: '+39 333 0000000',
        totalOrders: 0,
        monthlyEarnings: 0,
        createdAt: DateTime(2026, 2, 10),
      );

      final json = contact.toInsertJson('rider-xyz');

      expect(json['rider_id'], 'rider-xyz');
      expect(json['name'], 'New Dealer');
      expect(json['contact_type'], 'dealer');
      expect(json['status'], 'potential');
      expect(json['phone'], '+39 333 0000000');
      expect(json.containsKey('id'), false);
      expect(json.containsKey('created_at'), false);
    });
  });
}
