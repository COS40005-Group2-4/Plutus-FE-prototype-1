import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/models/bill_model.dart';
import '../helpers/test_fixtures.dart';

void main() {
  group('Bill', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = {
          'id': 1,
          'name': 'Electric Bill',
          'amount': 500000,
          'currency': 'VND',
          'due_date': '2024-02-01T00:00:00.000',
          'recurrence': 'monthly',
          'is_paid': 0,
          'category': 'Utilities',
          'notes': 'Monthly electric',
        };

        final bill = Bill.fromJson(json);

        expect(bill.id, 1);
        expect(bill.name, 'Electric Bill');
        expect(bill.amount, 500000.0);
        expect(bill.currency, 'VND');
        expect(bill.dueDate, DateTime(2024, 2, 1));
        expect(bill.recurrence, BillRecurrence.monthly);
        expect(bill.isPaid, false);
        expect(bill.category, 'Utilities');
        expect(bill.notes, 'Monthly electric');
      });

      test('handles is_paid as int (1 = true)', () {
        final json = {
          'name': 'Rent',
          'amount': 10000000,
          'due_date': '2024-02-01T00:00:00.000',
          'recurrence': 'monthly',
          'is_paid': 1,
        };

        final bill = Bill.fromJson(json);
        expect(bill.isPaid, true);
      });

      test('handles is_paid as bool', () {
        final json = {
          'name': 'Rent',
          'amount': 10000000,
          'due_date': '2024-02-01T00:00:00.000',
          'recurrence': 'monthly',
          'is_paid': true,
        };

        final bill = Bill.fromJson(json);
        expect(bill.isPaid, true);
      });

      test('handles is_paid as int 0 (false)', () {
        final json = {
          'name': 'Rent',
          'amount': 10000000,
          'due_date': '2024-02-01T00:00:00.000',
          'recurrence': 'monthly',
          'is_paid': 0,
        };

        final bill = Bill.fromJson(json);
        expect(bill.isPaid, false);
      });

      test('defaults currency to VND when null', () {
        final json = {
          'name': 'Rent',
          'amount': 1000,
          'due_date': '2024-02-01T00:00:00.000',
          'recurrence': 'monthly',
          'is_paid': 0,
        };

        final bill = Bill.fromJson(json);
        expect(bill.currency, 'VND');
      });

      test('handles null optional fields', () {
        final json = {
          'name': 'Rent',
          'amount': 1000,
          'due_date': '2024-02-01T00:00:00.000',
          'recurrence': 'monthly',
          'is_paid': 0,
        };

        final bill = Bill.fromJson(json);
        expect(bill.id, isNull);
        expect(bill.category, isNull);
        expect(bill.notes, isNull);
      });

      test('defaults to oneTime for unknown recurrence', () {
        final json = {
          'name': 'Rent',
          'amount': 1000,
          'due_date': '2024-02-01T00:00:00.000',
          'recurrence': 'unknown_value',
          'is_paid': 0,
        };

        final bill = Bill.fromJson(json);
        expect(bill.recurrence, BillRecurrence.oneTime);
      });

      test('parses all recurrence types', () {
        for (final recurrence in BillRecurrence.values) {
          final json = {
            'name': 'Bill',
            'amount': 100,
            'due_date': '2024-01-01T00:00:00.000',
            'recurrence': recurrence.name,
            'is_paid': 0,
          };

          final bill = Bill.fromJson(json);
          expect(bill.recurrence, recurrence);
        }
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final bill = createTestBill();
        final json = bill.toJson();

        expect(json['id'], 1);
        expect(json['name'], 'Test Bill');
        expect(json['amount'], 1000.0);
        expect(json['currency'], 'VND');
        expect(json['due_date'], isA<String>());
        expect(json['recurrence'], 'monthly');
        expect(json['is_paid'], false);
        expect(json['category'], 'Utilities');
      });

      test('serializes isPaid as bool', () {
        final paidBill = createTestBill(isPaid: true);
        final json = paidBill.toJson();

        expect(json['is_paid'], true);
      });
    });

    group('toJson/fromJson round-trip', () {
      test('preserves all data through serialization cycle', () {
        final original = createTestBill(
          notes: 'Important bill',
          category: 'Insurance',
          recurrence: BillRecurrence.quarterly,
        );
        final restored = Bill.fromJson(original.toJson());

        expect(restored.name, original.name);
        expect(restored.amount, original.amount);
        expect(restored.currency, original.currency);
        expect(restored.recurrence, original.recurrence);
        expect(restored.isPaid, original.isPaid);
        expect(restored.category, original.category);
        expect(restored.notes, original.notes);
      });
    });

    group('copyWith', () {
      test('preserves all fields when no overrides given', () {
        final bill = createTestBill();
        final copy = bill.copyWith();

        expect(copy, bill);
      });

      test('overrides only specified fields', () {
        final bill = createTestBill();
        final copy = bill.copyWith(name: 'Updated Bill', amount: 2000.0);

        expect(copy.name, 'Updated Bill');
        expect(copy.amount, 2000.0);
        expect(copy.id, bill.id);
        expect(copy.currency, bill.currency);
        expect(copy.dueDate, bill.dueDate);
      });

      test('can mark bill as paid', () {
        final bill = createTestBill(isPaid: false);
        final paidBill = bill.copyWith(isPaid: true);

        expect(paidBill.isPaid, true);
        expect(paidBill.name, bill.name);
      });
    });

    group('Equatable', () {
      test('identical bills are equal', () {
        final bill1 = createTestBill();
        final bill2 = createTestBill();

        expect(bill1, bill2);
        expect(bill1.hashCode, bill2.hashCode);
      });

      test('bills with different amounts are not equal', () {
        final bill1 = createTestBill(amount: 100.0);
        final bill2 = createTestBill(amount: 200.0);

        expect(bill1, isNot(bill2));
      });
    });

    group('formattedDueDate', () {
      test('formats date as dd/MM/yyyy', () {
        final bill = createTestBill(dueDate: DateTime(2024, 12, 25));

        expect(bill.formattedDueDate, '25/12/2024');
      });
    });

    group('isOverdue', () {
      test('returns true for unpaid bill with past due date', () {
        final bill = createTestBill(
          dueDate: DateTime(2020, 1, 1),
          isPaid: false,
        );

        expect(bill.isOverdue, true);
      });

      test('returns false for paid bill even with past due date', () {
        final bill = createTestBill(
          dueDate: DateTime(2020, 1, 1),
          isPaid: true,
        );

        expect(bill.isOverdue, false);
      });

      test('returns false for unpaid bill with future due date', () {
        final bill = createTestBill(
          dueDate: DateTime(2099, 12, 31),
          isPaid: false,
        );

        expect(bill.isOverdue, false);
      });
    });

    group('isUpcoming', () {
      test('returns true for unpaid bill due within 7 days', () {
        final bill = createTestBill(
          dueDate: DateTime.now().add(const Duration(days: 3)),
          isPaid: false,
        );

        expect(bill.isUpcoming, true);
      });

      test('returns false for paid bill due within 7 days', () {
        final bill = createTestBill(
          dueDate: DateTime.now().add(const Duration(days: 3)),
          isPaid: true,
        );

        expect(bill.isUpcoming, false);
      });

      test('returns false for bill due more than 7 days away', () {
        final bill = createTestBill(
          dueDate: DateTime.now().add(const Duration(days: 30)),
          isPaid: false,
        );

        expect(bill.isUpcoming, false);
      });

      test('returns false for overdue bill', () {
        final bill = createTestBill(
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
          isPaid: false,
        );

        expect(bill.isUpcoming, false);
      });

      test('returns true for bill due today', () {
        final now = DateTime.now();
        final bill = createTestBill(
          dueDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
          isPaid: false,
        );

        expect(bill.isUpcoming, true);
      });
    });
  });
}
