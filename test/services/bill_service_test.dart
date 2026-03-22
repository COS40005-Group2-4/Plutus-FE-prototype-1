import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plutus_fe_prototype/models/bill_model.dart';
import 'package:plutus_fe_prototype/services/bill_service.dart';

import '../helpers/mock_services.mocks.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockIDatabaseService mockDb;
  late BillService service;

  const int userId = 1;

  Map<String, dynamic> billToDbMap(Bill bill, {int? dbId}) {
    return {
      'id': dbId ?? bill.id,
      'name': bill.name,
      'amount': bill.amount,
      'currency': bill.currency,
      'due_date': bill.dueDate.toIso8601String(),
      'recurrence': bill.recurrence.name,
      'is_paid': bill.isPaid ? 1 : 0,
      'category': bill.category,
      'notes': bill.notes,
    };
  }

  setUp(() {
    mockDb = MockIDatabaseService();
    service = BillService(db: mockDb);
    service.setCurrentUser(userId);
  });

  group('getBills', () {
    test('returns empty list when no user is set', () async {
      final noUserService = BillService(db: mockDb);

      final bills = await noUserService.getBills();

      expect(bills, isEmpty);
      verifyNever(mockDb.getBillsByUserId(any));
    });

    test('returns empty list when database has no bills', () async {
      when(mockDb.getBillsByUserId(userId))
          .thenAnswer((_) async => []);

      final bills = await service.getBills();

      expect(bills, isEmpty);
    });

    test('returns parsed bills from database', () async {
      final bill1 = createTestBill(id: 1, name: 'Rent');
      final bill2 = createTestBill(id: 2, name: 'Electric');

      when(mockDb.getBillsByUserId(userId)).thenAnswer((_) async => [
            billToDbMap(bill1),
            billToDbMap(bill2),
          ]);

      final bills = await service.getBills();

      expect(bills.length, 2);
      expect(bills[0].name, 'Rent');
      expect(bills[1].name, 'Electric');
    });

    test('returns empty list on database error', () async {
      when(mockDb.getBillsByUserId(userId))
          .thenThrow(Exception('DB error'));

      final bills = await service.getBills();

      expect(bills, isEmpty);
    });
  });

  group('addBill', () {
    test('inserts bill and notifies update', () async {
      final bill = createTestBill(id: null, name: 'Internet');

      when(mockDb.insertBill(userId, any))
          .thenAnswer((_) async => 1);
      when(mockDb.getBillsByUserId(userId))
          .thenAnswer((_) async => [billToDbMap(bill, dbId: 1)]);

      await service.addBill(bill);

      verify(mockDb.insertBill(userId, any)).called(1);
    });

    test('throws when no user is logged in', () async {
      final noUserService = BillService(db: mockDb);
      final bill = createTestBill(name: 'Test');

      expect(
        () => noUserService.addBill(bill),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('updateBill', () {
    test('updates bill in database', () async {
      final bill = createTestBill(id: 5, name: 'Updated Bill');

      when(mockDb.updateBill(5, any))
          .thenAnswer((_) async {});
      when(mockDb.getBillsByUserId(userId))
          .thenAnswer((_) async => [billToDbMap(bill)]);

      await service.updateBill(bill);

      verify(mockDb.updateBill(5, any)).called(1);
    });

    test('throws when bill has no id', () async {
      final bill = createTestBill(id: null);

      expect(
        () => service.updateBill(bill),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when no user is logged in', () async {
      final noUserService = BillService(db: mockDb);
      final bill = createTestBill(id: 1);

      expect(
        () => noUserService.updateBill(bill),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('deleteBill', () {
    test('deletes bill from database', () async {
      when(mockDb.deleteBill(3))
          .thenAnswer((_) async {});
      when(mockDb.getBillsByUserId(userId))
          .thenAnswer((_) async => []);

      await service.deleteBill(3);

      verify(mockDb.deleteBill(3)).called(1);
    });
  });

  group('markBillAsPaid', () {
    test('marks one-time bill as paid without creating next occurrence', () async {
      final bill = createTestBill(
        id: 10,
        name: 'One-time Fee',
        recurrence: BillRecurrence.oneTime,
        isPaid: false,
      );

      when(mockDb.getBillsByUserId(userId))
          .thenAnswer((_) async => [billToDbMap(bill)]);
      when(mockDb.updateBill(10, any))
          .thenAnswer((_) async {});

      await service.markBillAsPaid(10);

      verify(mockDb.updateBill(10, any)).called(1);
      // Should NOT insert a new bill for one-time recurrence
      verifyNever(mockDb.insertBill(any, any));
    });

    test('marks recurring bill as paid and creates next occurrence', () async {
      final bill = createTestBill(
        id: 20,
        name: 'Monthly Rent',
        recurrence: BillRecurrence.monthly,
        isPaid: false,
        dueDate: DateTime(2024, 3, 1),
      );

      when(mockDb.getBillsByUserId(userId))
          .thenAnswer((_) async => [billToDbMap(bill)]);
      when(mockDb.updateBill(20, any))
          .thenAnswer((_) async {});
      when(mockDb.insertBill(userId, any))
          .thenAnswer((_) async => 21);

      await service.markBillAsPaid(20);

      // Should update the current bill
      verify(mockDb.updateBill(20, any)).called(1);
      // Should insert a new bill for the next month
      verify(mockDb.insertBill(userId, any)).called(1);
    });

    test('throws when no user is logged in', () async {
      final noUserService = BillService(db: mockDb);

      expect(
        () => noUserService.markBillAsPaid(1),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('getTotalDueAmount', () {
    test('returns 0.0 when no bills exist', () async {
      when(mockDb.getBillsByUserId(userId))
          .thenAnswer((_) async => []);

      final total =
          await service.getTotalDueAmount(currency: 'VND', days: 30);

      expect(total, 0.0);
    });

    test('sums only unpaid bills in the correct currency within the date range', () async {
      final now = DateTime.now();
      final inRange = now.add(const Duration(days: 10));
      final outOfRange = now.add(const Duration(days: 60));
      final past = now.subtract(const Duration(days: 5));

      final unpaidInRange = createTestBill(
        id: 1,
        name: 'Bill A',
        amount: 500.0,
        currency: 'VND',
        dueDate: inRange,
        isPaid: false,
      );
      final paidInRange = createTestBill(
        id: 2,
        name: 'Bill B',
        amount: 300.0,
        currency: 'VND',
        dueDate: inRange,
        isPaid: true,
      );
      final unpaidOutOfRange = createTestBill(
        id: 3,
        name: 'Bill C',
        amount: 1000.0,
        currency: 'VND',
        dueDate: outOfRange,
        isPaid: false,
      );
      final unpaidDiffCurrency = createTestBill(
        id: 4,
        name: 'Bill D',
        amount: 200.0,
        currency: 'USD',
        dueDate: inRange,
        isPaid: false,
      );
      final unpaidPast = createTestBill(
        id: 5,
        name: 'Bill E',
        amount: 100.0,
        currency: 'VND',
        dueDate: past,
        isPaid: false,
      );

      when(mockDb.getBillsByUserId(userId)).thenAnswer((_) async => [
            billToDbMap(unpaidInRange),
            billToDbMap(paidInRange),
            billToDbMap(unpaidOutOfRange),
            billToDbMap(unpaidDiffCurrency),
            billToDbMap(unpaidPast),
          ]);

      final total =
          await service.getTotalDueAmount(currency: 'VND', days: 30);

      expect(total, 500.0);
    });

    test('returns 0.0 when user is not set', () async {
      final noUserService = BillService(db: mockDb);

      final total =
          await noUserService.getTotalDueAmount(currency: 'VND');

      expect(total, 0.0);
    });
  });

  group('billStream', () {
    test('emits bills when notifyBillUpdate is called', () async {
      final bill = createTestBill(id: 1, name: 'Stream Bill');

      when(mockDb.getBillsByUserId(userId))
          .thenAnswer((_) async => [billToDbMap(bill)]);

      expectLater(
        service.billStream,
        emits(isA<List<Bill>>().having((l) => l.length, 'length', 1)),
      );

      await service.notifyBillUpdate();
    });
  });
}
