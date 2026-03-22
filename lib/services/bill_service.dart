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

  Stream<List<Bill>> get billStream => _billStreamController.stream;

  void setCurrentUser(int userId) {
    _currentUserId = userId;
  }

  Future<void> notifyBillUpdate() async {
    if (_currentUserId != null) {
      if (kDebugMode) {
        print('Notifying bill update for user $_currentUserId');
      }
      
      final bills = await getBills();
      
      if (kDebugMode) {
        print('Sending ${bills.length} bills to stream');
      }
      
      if (!_billStreamController.isClosed) {
        _billStreamController.add(bills);
      }
    }
  }

  Future<List<Bill>> getBills() async {
    if (_currentUserId == null) {
      if (kDebugMode) {
        print('No user logged in, returning empty bills');
      }
      return [];
    }

    try {
      final billMaps = await _db.getBillsByUserId(_currentUserId!);
      
      if (kDebugMode) {
        print('Retrieved ${billMaps.length} bills from database for user $_currentUserId');
      }
      
      return billMaps.map((map) => Bill.fromJson(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading bills: $e');
      }
      return [];
    }
  }

  Future<void> addBill(Bill bill) async {
    if (_currentUserId == null) {
      throw Exception('No user logged in');
    }

    if (kDebugMode) {
      print('Adding bill: ${bill.name} for user $_currentUserId');
    }

    await _db.insertBill(_currentUserId!, bill.toJson());
    
    if (kDebugMode) {
      print('Bill added successfully, notifying listeners');
    }
    
    await notifyBillUpdate();
  }

  Future<void> updateBill(Bill bill) async {
    if (_currentUserId == null || bill.id == null) {
      throw Exception('Invalid bill or user');
    }

    await _db.updateBill(bill.id!, bill.toJson());
    await notifyBillUpdate();
  }

  Future<void> deleteBill(int billId) async {
    await _db.deleteBill(billId);
    await notifyBillUpdate();
  }

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
        print('Created next occurrence of recurring bill: ${bill.name} for ${nextDueDate}');
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

  void dispose() {
    // Don't close - this is a singleton
  }
}
