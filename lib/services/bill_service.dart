import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/bill_model.dart';
import 'database_service.dart';

class BillService {
  static final BillService _instance = BillService._internal();
  factory BillService() => _instance;
  BillService._internal();

  final DatabaseService _db = DatabaseService();
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
    final updatedBill = bill.copyWith(isPaid: true);
    await updateBill(updatedBill);
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
