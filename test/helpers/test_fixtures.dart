import 'package:plutus_fe_prototype/models/user_model.dart';
import 'package:plutus_fe_prototype/models/transaction_model.dart';
import 'package:plutus_fe_prototype/models/bill_model.dart';
import 'package:plutus_fe_prototype/models/profile_model.dart';
import 'package:plutus_fe_prototype/models/investment_model.dart';
import 'package:plutus_fe_prototype/models/backup_models.dart';

User createTestUser({
  int id = 1,
  String username = 'testuser',
  String displayName = 'Test User',
  String? email = 'test@example.com',
  String? oauthProvider,
  String? oauthId,
  bool isGuest = false,
  DateTime? createdAt,
  DateTime? lastLogin,
  bool isActive = true,
}) {
  final now = DateTime(2024, 1, 1);
  return User(
    id: id,
    username: username,
    displayName: displayName,
    email: email,
    oauthProvider: oauthProvider,
    oauthId: oauthId,
    isGuest: isGuest,
    createdAt: createdAt ?? now,
    lastLogin: lastLogin ?? now,
    isActive: isActive,
  );
}

Transaction createTestTransaction({
  int? id = 1,
  int date = 1704067200, // 2024-01-01 00:00:00 UTC
  String payee = 'Test Payee',
  String description = 'Test description',
  List<Posting>? postings,
}) {
  return Transaction(
    id: id,
    date: date,
    payee: payee,
    description: description,
    postings: postings ??
        [
          const Posting(account: 'Assets:Cash', amount: -100.0, commodity: 'VND'),
          const Posting(account: 'Expenses:Food', amount: 100.0, commodity: 'VND'),
        ],
  );
}

Bill createTestBill({
  int? id = 1,
  String name = 'Test Bill',
  double amount = 1000.0,
  String currency = 'VND',
  DateTime? dueDate,
  BillRecurrence recurrence = BillRecurrence.monthly,
  bool isPaid = false,
  String? category = 'Utilities',
  String? notes,
}) {
  return Bill(
    id: id,
    name: name,
    amount: amount,
    currency: currency,
    dueDate: dueDate ?? DateTime(2024, 2, 1),
    recurrence: recurrence,
    isPaid: isPaid,
    category: category,
    notes: notes,
  );
}

Profile createTestProfile({
  int userId = 1,
  String? avatarPath,
  String? dateOfBirth,
  String? position,
  String? placeOfEmployment,
  bool showName = true,
  bool showEmail = true,
  bool showDateOfBirth = false,
  bool showPosition = false,
  bool showPlaceOfEmployment = false,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime(2024, 1, 1);
  return Profile(
    userId: userId,
    avatarPath: avatarPath,
    dateOfBirth: dateOfBirth,
    position: position,
    placeOfEmployment: placeOfEmployment,
    showName: showName,
    showEmail: showEmail,
    showDateOfBirth: showDateOfBirth,
    showPosition: showPosition,
    showPlaceOfEmployment: showPlaceOfEmployment,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
  );
}

InvestmentModel createTestInvestment({
  String id = 'inv_001',
  AssetType assetType = AssetType.stock,
  String assetName = 'AAPL',
  double quantity = 10.0,
  double purchaseValue = 1500.0,
  Currency currency = Currency.usd,
  DateTime? purchaseDate,
  double? currentPrice = 175.0,
  List<PriceHistoryPoint>? priceHistory,
}) {
  return InvestmentModel(
    id: id,
    assetType: assetType,
    assetName: assetName,
    quantity: quantity,
    purchaseValue: purchaseValue,
    currency: currency,
    purchaseDate: purchaseDate ?? DateTime(2024, 1, 1),
    currentPrice: currentPrice,
    priceHistory: priceHistory,
  );
}

VersionEntry createTestVersionEntry({
  String s3ObjectKey = 'backups/1/1704067200000.db',
  DateTime? timestamp,
  int fileSizeBytes = 1024,
  String checksum = 'abc123',
}) {
  return VersionEntry(
    s3ObjectKey: s3ObjectKey,
    timestamp: timestamp ?? DateTime(2024, 1, 1),
    fileSizeBytes: fileSizeBytes,
    checksum: checksum,
  );
}

/// Creates a raw user map as returned from the database
Map<String, dynamic> createTestUserMap({
  int id = 1,
  String username = 'testuser',
  String displayName = 'Test User',
  String? email = 'test@example.com',
  String? oauthProvider,
  String? oauthId,
  bool isGuest = false,
}) {
  final now = DateTime(2024, 1, 1).millisecondsSinceEpoch;
  return {
    'id': id,
    'username': username,
    'display_name': displayName,
    'email': email,
    'oauth_provider': oauthProvider,
    'oauth_id': oauthId,
    'is_guest': isGuest ? 1 : 0,
    'created_at': now,
    'last_login': now,
    'is_active': 1,
  };
}
