import 'package:intl/intl.dart';

class Transaction {
  final int date;
  final String payee;
  final String description;
  final List<Posting> postings;

  Transaction({
    required this.date,
    required this.payee,
    required this.description,
    required this.postings,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      date: json['date'] as int,
      payee: json['payee'] as String? ?? '',
      description: json['description'] as String? ?? '',
      postings: (json['postings'] as List<dynamic>?)
              ?.map((p) => Posting.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'payee': payee,
      'description': description,
      'postings': postings.map((p) => p.toJson()).toList(),
    };
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(date * 1000);

  String get formattedDate {
    // Format as HH:MM:SS DD/MM/YYYY
    final formatter = DateFormat('HH:mm:ss dd/MM/yyyy');
    return formatter.format(dateTime);
  }

  String get label {
    // Create a clear label for the transaction
    if (payee.isNotEmpty && description.isNotEmpty) {
      return '$payee - $description';
    } else if (payee.isNotEmpty) {
      return payee;
    } else if (description.isNotEmpty) {
      return description;
    } else if (postings.isNotEmpty) {
      return postings.first.account;
    }
    return 'Transaction';
  }

  bool get isExpense {
    // Check if the first posting is an expense (negative amount for assets)
    if (postings.isEmpty) return false;
    final firstPosting = postings.first;
    final account = firstPosting.account.toLowerCase();
    // If it's from an asset account and amount is negative, it's an expense
    if (account.startsWith('assets:') || account.startsWith('asset:')) {
      return firstPosting.amount < 0;
    }
    // If it's to an expense account, it's an expense
    if (account.startsWith('expenses:') || account.startsWith('expense:')) {
      return firstPosting.amount > 0;
    }
    return false;
  }

  double get totalAmount {
    // Calculate the total amount (absolute value of first posting)
    if (postings.isEmpty) return 0.0;
    return postings.first.amount.abs();
  }

  String get currency {
    if (postings.isEmpty) return '';
    return postings.first.commodity;
  }
}

class Posting {
  final String account;
  final double amount;
  final String commodity;

  Posting({
    required this.account,
    required this.amount,
    required this.commodity,
  });

  factory Posting.fromJson(Map<String, dynamic> json) {
    double amountValue = 0.0;
    final amountData = json['amount'];
    if (amountData is String) {
      amountValue = double.tryParse(amountData) ?? 0.0;
    } else if (amountData is num) {
      amountValue = amountData.toDouble();
    }

    return Posting(
      account: json['account'] as String? ?? '',
      amount: amountValue,
      commodity: json['commodity'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account': account,
      'amount': amount,
      'commodity': commodity,
    };
  }

  String get formattedAmount {
    final formatter = NumberFormat("#,##0.00", "en_US");
    return '${amount >= 0 ? '+' : ''}${formatter.format(amount)}';
  }
}
