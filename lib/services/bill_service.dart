import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/bill_model.dart';
import 'interfaces/i_database_service.dart';
import 'interfaces/i_bill_service.dart';
import '../di/service_locator.dart';

class BillService implements IBillService {
  final IDatabaseService _db;

  BillService({IDatabaseService? db}) : _db = db ?? sl<IDatabaseService>();
  int? _currentUserId;

  final StreamController<List<Bill>> _billStreamController =
      StreamController<List<Bill>>.broadcast();

  @override
  Stream<List<Bill>> get billStream => _billStreamController.stream;

  @override
  void setCurrentUser(int userId) {
    _currentUserId = userId;
  }

  @override
  Future<void> notifyBillUpdate() async {
    if (_currentUserId != null) {
      if (kDebugMode) {
        debugPrint('Notifying bill update for user $_currentUserId');
      }
      
      final bills = await getBills();
      
      if (kDebugMode) {
        debugPrint('Sending ${bills.length} bills to stream');
      }
      
      if (!_billStreamController.isClosed) {
        _billStreamController.add(bills);
      }
    }
  }

  @override
  Future<List<Bill>> getBills() async {
    if (_currentUserId == null) {
      if (kDebugMode) {
        debugPrint('No user logged in, returning empty bills');
      }
      return [];
    }

    try {
      final billMaps = await _db.getBillsByUserId(_currentUserId!);
      
      if (kDebugMode) {
        debugPrint('Retrieved ${billMaps.length} bills from database for user $_currentUserId');
      }
      
      return billMaps.map((map) => Bill.fromJson(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading bills: $e');
      }
      return [];
    }
  }

  @override
  Future<void> addBill(Bill bill) async {
    if (_currentUserId == null) {
      throw Exception('No user logged in');
    }

    if (kDebugMode) {
      debugPrint('Adding bill: ${bill.name} for user $_currentUserId');
    }

    await _db.insertBill(_currentUserId!, bill.toJson());
    
    if (kDebugMode) {
      debugPrint('Bill added successfully, notifying listeners');
    }
    
    await notifyBillUpdate();
  }

  @override
  Future<void> updateBill(Bill bill) async {
    if (_currentUserId == null || bill.id == null) {
      throw Exception('Invalid bill or user');
    }

    await _db.updateBill(bill.id!, bill.toJson());
    await notifyBillUpdate();
  }

  @override
  Future<void> deleteBill(int billId) async {
    await _db.deleteBill(billId);
    await notifyBillUpdate();
  }

  @override
  Future<void> markBillAsPaid(int billId) async {
    if (_currentUserId == null) {
      throw Exception('No user logged in');
    }

    final bills = await getBills();
    final bill = bills.firstWhere((b) => b.id == billId);
    
    // Mark current bill as paid
    final updatedBill = bill.copyWith(isPaid: true);
    await updateBill(updatedBill);

    // If recurring, create next occurrence
    if (bill.recurrence != BillRecurrence.oneTime) {
      final nextDueDate = _calculateNextDueDate(bill.dueDate, bill.recurrence, bill.anchorDay);

      final nextBill = Bill(
        name: bill.name,
        amount: bill.amount,
        currency: bill.currency,
        dueDate: nextDueDate,
        recurrence: bill.recurrence,
        isPaid: false,
        category: bill.category,
        notes: bill.notes,
        anchorDay: bill.anchorDay,
      );
      
      await addBill(nextBill);
      
      if (kDebugMode) {
        debugPrint('Created next occurrence of recurring bill: ${bill.name} for $nextDueDate');
      }
    }
  }

  // Returns the last calendar day of [month] in [year].
  int _lastDayOfMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  DateTime _calculateNextDueDate(DateTime currentDueDate, BillRecurrence recurrence, int anchorDay) {
    int year = currentDueDate.year;
    int month = currentDueDate.month;

    switch (recurrence) {
      case BillRecurrence.monthly:
        month += 1;
      case BillRecurrence.quarterly:
        month += 3;
      case BillRecurrence.yearly:
        year += 1;
      case BillRecurrence.oneTime:
        return currentDueDate;
    }

    // Normalise month overflow (e.g. month 13 → Jan of next year)
    while (month > 12) {
      month -= 12;
      year += 1;
    }

    // Use anchorDay but clamp to the actual last day of the target month so we
    // never overflow into the following month (e.g. anchor=31 in Feb → Feb 28/29).
    final day = anchorDay.clamp(1, _lastDayOfMonth(year, month));
    return DateTime(year, month, day);
  }

  @override
  Future<double> getTotalDueAmount({
    required String currency,
    int days = 30,
  }) async {
    final bills = await getBills();
    final now = DateTime.now();
    final endDate = now.add(Duration(days: days));

    return bills
        .where((bill) =>
            !bill.isPaid &&
            bill.currency == currency &&
            bill.dueDate.isAfter(now) &&
            bill.dueDate.isBefore(endDate))
        .fold<double>(0.0, (sum, bill) => sum + bill.amount);
  }

  @override
  void dispose() {
    // Don't close - this is a singleton
  }
}
