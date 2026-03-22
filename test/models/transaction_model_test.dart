import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/models/transaction_model.dart';
import '../helpers/test_fixtures.dart';

void main() {
  group('Posting', () {
    group('fromJson', () {
      test('parses numeric amount', () {
        final posting = Posting.fromJson({
          'account': 'Assets:Cash',
          'amount': 100.5,
          'commodity': 'VND',
        });

        expect(posting.account, 'Assets:Cash');
        expect(posting.amount, 100.5);
        expect(posting.commodity, 'VND');
      });

      test('parses string amount', () {
        final posting = Posting.fromJson({
          'account': 'Assets:Cash',
          'amount': '250.75',
          'commodity': 'USD',
        });

        expect(posting.amount, 250.75);
      });

      test('handles invalid string amount as 0.0', () {
        final posting = Posting.fromJson({
          'account': 'Assets:Cash',
          'amount': 'not_a_number',
          'commodity': 'VND',
        });

        expect(posting.amount, 0.0);
      });

      test('defaults to empty strings for null account and commodity', () {
        final posting = Posting.fromJson({'amount': 10});

        expect(posting.account, '');
        expect(posting.commodity, '');
      });

      test('handles integer amount', () {
        final posting = Posting.fromJson({
          'account': 'Assets:Bank',
          'amount': 500,
          'commodity': 'VND',
        });

        expect(posting.amount, 500.0);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        const posting = Posting(account: 'Expenses:Food', amount: 42.5, commodity: 'USD');
        final json = posting.toJson();

        expect(json['account'], 'Expenses:Food');
        expect(json['amount'], 42.5);
        expect(json['commodity'], 'USD');
      });
    });

    group('formattedAmount', () {
      test('positive amount has plus sign', () {
        const posting = Posting(account: 'Expenses:Food', amount: 1234.56, commodity: 'VND');

        expect(posting.formattedAmount, '+1,234.56');
      });

      test('negative amount has minus sign', () {
        const posting = Posting(account: 'Assets:Cash', amount: -1234.56, commodity: 'VND');

        expect(posting.formattedAmount, '-1,234.56');
      });

      test('zero amount has plus sign', () {
        const posting = Posting(account: 'Assets:Cash', amount: 0.0, commodity: 'VND');

        expect(posting.formattedAmount, '+0.00');
      });
    });

    group('Equatable', () {
      test('identical postings are equal', () {
        const p1 = Posting(account: 'A', amount: 10, commodity: 'VND');
        const p2 = Posting(account: 'A', amount: 10, commodity: 'VND');

        expect(p1, p2);
      });

      test('different postings are not equal', () {
        const p1 = Posting(account: 'A', amount: 10, commodity: 'VND');
        const p2 = Posting(account: 'B', amount: 10, commodity: 'VND');

        expect(p1, isNot(p2));
      });
    });
  });

  group('Transaction', () {
    group('fromJson', () {
      test('parses full transaction with postings', () {
        final json = {
          'id': 1,
          'date': 1704067200,
          'payee': 'Grocery Store',
          'description': 'Weekly groceries',
          'postings': [
            {'account': 'Assets:Cash', 'amount': -50.0, 'commodity': 'USD'},
            {'account': 'Expenses:Food', 'amount': 50.0, 'commodity': 'USD'},
          ],
        };

        final tx = Transaction.fromJson(json);

        expect(tx.id, 1);
        expect(tx.date, 1704067200);
        expect(tx.payee, 'Grocery Store');
        expect(tx.description, 'Weekly groceries');
        expect(tx.postings.length, 2);
        expect(tx.postings.first.account, 'Assets:Cash');
      });

      test('handles null id', () {
        final json = {
          'date': 1704067200,
          'payee': 'Test',
          'description': 'Test',
          'postings': [],
        };

        final tx = Transaction.fromJson(json);
        expect(tx.id, isNull);
      });

      test('defaults payee and description to empty string when null', () {
        final json = {'date': 1704067200};
        final tx = Transaction.fromJson(json);

        expect(tx.payee, '');
        expect(tx.description, '');
      });

      test('defaults postings to empty list when null', () {
        final json = {'date': 1704067200, 'payee': '', 'description': ''};
        final tx = Transaction.fromJson(json);

        expect(tx.postings, isEmpty);
      });
    });

    group('toJson', () {
      test('serializes all fields including postings', () {
        final tx = createTestTransaction();
        final json = tx.toJson();

        expect(json['id'], 1);
        expect(json['date'], 1704067200);
        expect(json['payee'], 'Test Payee');
        expect(json['postings'], isList);
        expect((json['postings'] as List).length, 2);
      });
    });

    group('toJson/fromJson round-trip', () {
      test('preserves all data through serialization cycle', () {
        final original = createTestTransaction();
        final restored = Transaction.fromJson(original.toJson());

        expect(restored, original);
      });

      test('preserves transaction with no postings', () {
        final original = createTestTransaction(postings: []);
        final restored = Transaction.fromJson(original.toJson());

        expect(restored, original);
      });
    });

    group('dateTime', () {
      test('converts unix timestamp to DateTime', () {
        final tx = createTestTransaction(date: 1704067200);

        expect(tx.dateTime, DateTime.fromMillisecondsSinceEpoch(1704067200 * 1000));
      });
    });

    group('label', () {
      test('returns payee and description when both present', () {
        final tx = createTestTransaction(payee: 'Store', description: 'Food');

        expect(tx.label, 'Store - Food');
      });

      test('returns payee only when description is empty', () {
        final tx = createTestTransaction(payee: 'Store', description: '');

        expect(tx.label, 'Store');
      });

      test('returns description only when payee is empty', () {
        final tx = createTestTransaction(payee: '', description: 'Food');

        expect(tx.label, 'Food');
      });

      test('returns first posting account when both payee and description are empty', () {
        final tx = createTestTransaction(payee: '', description: '');

        expect(tx.label, 'Assets:Cash');
      });

      test('returns "Transaction" when everything is empty', () {
        final tx = createTestTransaction(payee: '', description: '', postings: []);

        expect(tx.label, 'Transaction');
      });
    });

    group('isExpense', () {
      test('returns true for negative asset posting', () {
        final tx = createTestTransaction(
          postings: [
            const Posting(account: 'Assets:Cash', amount: -100.0, commodity: 'VND'),
          ],
        );

        expect(tx.isExpense, true);
      });

      test('returns true for positive expense posting', () {
        final tx = createTestTransaction(
          postings: [
            const Posting(account: 'Expenses:Food', amount: 100.0, commodity: 'VND'),
          ],
        );

        expect(tx.isExpense, true);
      });

      test('returns false for positive asset posting (income)', () {
        final tx = createTestTransaction(
          postings: [
            const Posting(account: 'Assets:Cash', amount: 500.0, commodity: 'VND'),
          ],
        );

        expect(tx.isExpense, false);
      });

      test('returns false for empty postings', () {
        final tx = createTestTransaction(postings: []);

        expect(tx.isExpense, false);
      });

      test('handles "Asset:" prefix (singular)', () {
        final tx = createTestTransaction(
          postings: [
            const Posting(account: 'Asset:Bank', amount: -200.0, commodity: 'VND'),
          ],
        );

        expect(tx.isExpense, true);
      });

      test('handles "Expense:" prefix (singular)', () {
        final tx = createTestTransaction(
          postings: [
            const Posting(account: 'Expense:Rent', amount: 500.0, commodity: 'VND'),
          ],
        );

        expect(tx.isExpense, true);
      });
    });

    group('totalAmount', () {
      test('returns absolute value of first posting amount', () {
        final tx = createTestTransaction(
          postings: [
            const Posting(account: 'Assets:Cash', amount: -150.0, commodity: 'VND'),
          ],
        );

        expect(tx.totalAmount, 150.0);
      });

      test('returns 0.0 for empty postings', () {
        final tx = createTestTransaction(postings: []);

        expect(tx.totalAmount, 0.0);
      });
    });

    group('currency', () {
      test('returns commodity of first posting', () {
        final tx = createTestTransaction(
          postings: [
            const Posting(account: 'Assets:Cash', amount: -100.0, commodity: 'USD'),
          ],
        );

        expect(tx.currency, 'USD');
      });

      test('returns empty string for empty postings', () {
        final tx = createTestTransaction(postings: []);

        expect(tx.currency, '');
      });
    });

    group('Equatable', () {
      test('identical transactions are equal', () {
        final tx1 = createTestTransaction();
        final tx2 = createTestTransaction();

        expect(tx1, tx2);
        expect(tx1.hashCode, tx2.hashCode);
      });

      test('transactions with different ids are not equal', () {
        final tx1 = createTestTransaction(id: 1);
        final tx2 = createTestTransaction(id: 2);

        expect(tx1, isNot(tx2));
      });
    });
  });
}
