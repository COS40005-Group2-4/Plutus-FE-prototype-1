import 'package:intl/intl.dart';

enum BillRecurrence {
  oneTime,
  monthly,
  quarterly,
  yearly,
}

class Bill {
  final int? id;
  final String name;
  final double amount;
  final String currency;
  final DateTime dueDate;
  final BillRecurrence recurrence;
  final bool isPaid;
  final String? category;
  final String? notes;

  Bill({
    this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.dueDate,
    required this.recurrence,
    this.isPaid = false,
    this.category,
    this.notes,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    // Handle is_paid as either int or bool from database
    bool isPaidValue = false;
    if (json['is_paid'] is int) {
      isPaidValue = json['is_paid'] == 1;
    } else if (json['is_paid'] is bool) {
      isPaidValue = json['is_paid'] as bool;
    }
    
    return Bill(
      id: json['id'] as int?,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'VND',
      dueDate: DateTime.parse(json['due_date'] as String),
      recurrence: BillRecurrence.values.firstWhere(
        (e) => e.name == json['recurrence'],
        orElse: () => BillRecurrence.oneTime,
      ),
      isPaid: isPaidValue,
      category: json['category'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'currency': currency,
      'due_date': dueDate.toIso8601String(),
      'recurrence': recurrence.name,
      'is_paid': isPaid,
      'category': category,
      'notes': notes,
    };
  }

  String get formattedDueDate {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(dueDate);
  }

  bool get isOverdue {
    return !isPaid && dueDate.isBefore(DateTime.now());
  }

  bool get isUpcoming {
    final now = DateTime.now();
    final daysUntilDue = dueDate.difference(now).inDays;
    return !isPaid && daysUntilDue >= 0 && daysUntilDue <= 7;
  }

  Bill copyWith({
    int? id,
    String? name,
    double? amount,
    String? currency,
    DateTime? dueDate,
    BillRecurrence? recurrence,
    bool? isPaid,
    String? category,
    String? notes,
  }) {
    return Bill(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      dueDate: dueDate ?? this.dueDate,
      recurrence: recurrence ?? this.recurrence,
      isPaid: isPaid ?? this.isPaid,
      category: category ?? this.category,
      notes: notes ?? this.notes,
    );
  }
}
