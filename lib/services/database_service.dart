import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/profile_model.dart';
import 'interfaces/i_database_service.dart';

class DatabaseService implements IDatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  
  static Database? _database;
  
  DatabaseService._internal();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    // Safety net: ensure budget tables exist even if migration was skipped
    await _ensureBudgetTables(_database!);
    return _database!;
  }

  Future<void> _ensureBudgetTables(Database db) async {
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='budgets'");
    if (tables.isEmpty) {
      if (kDebugMode) print('Budget tables missing — creating now');
      await db.execute('CREATE TABLE IF NOT EXISTS budgets (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, name TEXT NOT NULL, mode TEXT NOT NULL, period_type TEXT NOT NULL, period_start TEXT, currency_code TEXT NOT NULL, is_active INTEGER DEFAULT 1, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE)');
      await db.execute('CREATE TABLE IF NOT EXISTS budget_categories (id INTEGER PRIMARY KEY AUTOINCREMENT, budget_id INTEGER NOT NULL, name TEXT NOT NULL, account_patterns TEXT NOT NULL, budgeted_amount REAL NOT NULL, rollover_enabled INTEGER DEFAULT 0, rollover_behavior TEXT DEFAULT \'carry\', sort_order INTEGER DEFAULT 0, icon TEXT, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, FOREIGN KEY (budget_id) REFERENCES budgets (id) ON DELETE CASCADE)');
      await db.execute('CREATE TABLE IF NOT EXISTS budget_periods (id INTEGER PRIMARY KEY AUTOINCREMENT, budget_category_id INTEGER NOT NULL, period_start TEXT NOT NULL, period_end TEXT NOT NULL, budgeted_amount REAL NOT NULL, rollover_amount REAL DEFAULT 0, created_at INTEGER NOT NULL, FOREIGN KEY (budget_category_id) REFERENCES budget_categories (id) ON DELETE CASCADE)');
      await db.execute('CREATE TABLE IF NOT EXISTS notification_rules (id INTEGER PRIMARY KEY AUTOINCREMENT, budget_category_id INTEGER NOT NULL, threshold_pct REAL NOT NULL, enabled INTEGER DEFAULT 1, FOREIGN KEY (budget_category_id) REFERENCES budget_categories (id) ON DELETE CASCADE)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_budgets_user_id ON budgets(user_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_budget_categories_budget_id ON budget_categories(budget_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_budget_periods_category_id ON budget_periods(budget_category_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_notification_rules_category_id ON notification_rules(budget_category_id)');
    }
  }
  
  Future<Database> _initDatabase() async {
    // Initialize FFI for desktop platforms
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    // Get platform-appropriate database location
    final String dbPath = await _getDatabasePath();
    
    if (kDebugMode) {
      print('Database path: $dbPath');
    }
    
    return await openDatabase(
      dbPath,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  Future<String> _getDatabasePath() async {
    if (kIsWeb) {
      // For web, use in-memory database or IndexedDB via sqflite
      return 'plutus_local.db';
    }
    
    String directory;
    
    if (Platform.isWindows) {
      // Windows: Use AppData\Local
      directory = (await getApplicationSupportDirectory()).path;
    } else if (Platform.isMacOS) {
      // macOS: Use Application Support
      directory = (await getApplicationSupportDirectory()).path;
    } else if (Platform.isLinux) {
      // Linux: Use .local/share
      directory = (await getApplicationSupportDirectory()).path;
    } else if (Platform.isAndroid) {
      // Android: Use app's internal storage
      directory = await getDatabasesPath();
    } else if (Platform.isIOS) {
      // iOS: Use Documents directory
      directory = (await getApplicationDocumentsDirectory()).path;
    } else {
      // Fallback
      directory = (await getApplicationSupportDirectory()).path;
    }
    
    return join(directory, 'plutus_local.db');
  }
  
  Future<void> _onCreate(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        display_name TEXT NOT NULL,
        email TEXT,
        oauth_provider TEXT,
        oauth_id TEXT,
        is_guest INTEGER DEFAULT 0,
        data_consent INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        last_login INTEGER NOT NULL,
        is_active INTEGER DEFAULT 1
      )
    ''');
    
    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        transaction_id TEXT UNIQUE,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        category TEXT,
        description TEXT,
        payee TEXT,
        date TEXT NOT NULL,
        account TEXT,
        is_synced INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    
    // Create user_settings table
    await db.execute('''
      CREATE TABLE user_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        key TEXT NOT NULL,
        value TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        UNIQUE(user_id, key),
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    
    // Create profiles table
    await db.execute('''
      CREATE TABLE profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        avatar_path TEXT,
        date_of_birth TEXT,
        position TEXT,
        place_of_employment TEXT,
        show_name INTEGER DEFAULT 1,
        show_email INTEGER DEFAULT 1,
        show_date_of_birth INTEGER DEFAULT 0,
        show_position INTEGER DEFAULT 0,
        show_place_of_employment INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    
    // Create postings table for double-entry accounting
    await db.execute('''
      CREATE TABLE postings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        account TEXT NOT NULL,
        amount REAL NOT NULL,
        commodity TEXT NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE
      )
    ''');
    
    // Create bills table
    await db.execute('''
      CREATE TABLE bills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        due_date TEXT NOT NULL,
        recurrence TEXT NOT NULL,
        is_paid INTEGER DEFAULT 0,
        category TEXT,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    
    // Create budgets table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        mode TEXT NOT NULL,
        period_type TEXT NOT NULL,
        period_start TEXT,
        currency_code TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create budget_categories table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS budget_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        budget_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        account_patterns TEXT NOT NULL,
        budgeted_amount REAL NOT NULL,
        rollover_enabled INTEGER DEFAULT 0,
        rollover_behavior TEXT DEFAULT 'carry',
        sort_order INTEGER DEFAULT 0,
        icon TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (budget_id) REFERENCES budgets (id) ON DELETE CASCADE
      )
    ''');

    // Create budget_periods table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS budget_periods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        budget_category_id INTEGER NOT NULL,
        period_start TEXT NOT NULL,
        period_end TEXT NOT NULL,
        budgeted_amount REAL NOT NULL,
        rollover_amount REAL DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (budget_category_id) REFERENCES budget_categories (id) ON DELETE CASCADE
      )
    ''');

    // Create notification_rules table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notification_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        budget_category_id INTEGER NOT NULL,
        threshold_pct REAL NOT NULL,
        enabled INTEGER DEFAULT 1,
        FOREIGN KEY (budget_category_id) REFERENCES budget_categories (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_transactions_user_id ON transactions(user_id)');
    await db.execute('CREATE INDEX idx_transactions_date ON transactions(date)');
    await db.execute('CREATE INDEX idx_user_settings_user_id ON user_settings(user_id)');
    await db.execute('CREATE INDEX idx_profiles_user_id ON profiles(user_id)');
    await db.execute('CREATE INDEX idx_postings_transaction_id ON postings(transaction_id)');
    await db.execute('CREATE INDEX idx_bills_user_id ON bills(user_id)');
    await db.execute('CREATE INDEX idx_bills_due_date ON bills(due_date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_budgets_user_id ON budgets(user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_budget_categories_budget_id ON budget_categories(budget_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_budget_periods_category_id ON budget_periods(budget_category_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notification_rules_category_id ON notification_rules(budget_category_id)');

    if (kDebugMode) {
      print('Database tables created successfully');
    }
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      print('Database upgraded from version $oldVersion to $newVersion');
    }
    
    // Upgrade from version 1 to 2: Add profiles table
    if (oldVersion < 2) {
      try {
        // Check if profiles table exists
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='profiles'",
        );
        
        if (tables.isEmpty) {
          // Create profiles table if it doesn't exist
          await db.execute('''
            CREATE TABLE profiles (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL UNIQUE,
              avatar_path TEXT,
              date_of_birth TEXT,
              position TEXT,
              place_of_employment TEXT,
              show_name INTEGER DEFAULT 1,
              show_email INTEGER DEFAULT 1,
              show_date_of_birth INTEGER DEFAULT 0,
              show_position INTEGER DEFAULT 0,
              show_place_of_employment INTEGER DEFAULT 0,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
            )
          ''');
          
          // Create index
          await db.execute('CREATE INDEX idx_profiles_user_id ON profiles(user_id)');
          
          if (kDebugMode) {
            print('Profiles table created successfully during upgrade');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error creating profiles table during upgrade: $e');
        }
        rethrow;
      }
    }
    
    // Upgrade from version 2 to 3: Add postings table for double-entry accounting
    if (oldVersion < 3) {
      try {
        // Check if postings table exists
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='postings'",
        );
        
        if (tables.isEmpty) {
          // Create postings table
          await db.execute('''
            CREATE TABLE postings (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              transaction_id INTEGER NOT NULL,
              account TEXT NOT NULL,
              amount REAL NOT NULL,
              commodity TEXT NOT NULL,
              FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE
            )
          ''');
          
          // Create index
          await db.execute('CREATE INDEX idx_postings_transaction_id ON postings(transaction_id)');
          
          if (kDebugMode) {
            print('Postings table created successfully during upgrade');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error creating postings table during upgrade: $e');
        }
        rethrow;
      }
    }
    
    // Upgrade from version 3 to 4: Add bills table
    if (oldVersion < 4) {
      try {
        // Check if bills table exists
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='bills'",
        );
        
        if (tables.isEmpty) {
          // Create bills table
          await db.execute('''
            CREATE TABLE bills (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL,
              name TEXT NOT NULL,
              amount REAL NOT NULL,
              currency TEXT NOT NULL,
              due_date TEXT NOT NULL,
              recurrence TEXT NOT NULL,
              is_paid INTEGER DEFAULT 0,
              category TEXT,
              notes TEXT,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
            )
          ''');
          
          // Create indexes
          await db.execute('CREATE INDEX idx_bills_user_id ON bills(user_id)');
          await db.execute('CREATE INDEX idx_bills_due_date ON bills(due_date)');
          
          if (kDebugMode) {
            print('Bills table created successfully during upgrade');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error creating bills table during upgrade: $e');
        }
        rethrow;
      }
    }

    // Upgrade from version 4 to 5: Add data_consent column
    if (oldVersion < 5) {
      try {
        // Check if data_consent column exists
        final columns = await db.rawQuery(
          "PRAGMA table_info(users)",
        );
        final hasDataConsent = columns.any((col) => col['name'] == 'data_consent');

        if (!hasDataConsent) {
          await db.execute('ALTER TABLE users ADD COLUMN data_consent INTEGER DEFAULT 0');
          if (kDebugMode) {
            print('data_consent column added successfully during upgrade');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error adding data_consent column during upgrade: $e');
        }
        rethrow;
      }
    }

    // Upgrade from version 5 to 6: Add budget tables
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budgets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          mode TEXT NOT NULL,
          period_type TEXT NOT NULL,
          period_start TEXT,
          currency_code TEXT NOT NULL,
          is_active INTEGER DEFAULT 1,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS budget_categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          budget_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          account_patterns TEXT NOT NULL,
          budgeted_amount REAL NOT NULL,
          rollover_enabled INTEGER DEFAULT 0,
          rollover_behavior TEXT DEFAULT 'carry',
          sort_order INTEGER DEFAULT 0,
          icon TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          FOREIGN KEY (budget_id) REFERENCES budgets (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS budget_periods (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          budget_category_id INTEGER NOT NULL,
          period_start TEXT NOT NULL,
          period_end TEXT NOT NULL,
          budgeted_amount REAL NOT NULL,
          rollover_amount REAL DEFAULT 0,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (budget_category_id) REFERENCES budget_categories (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS notification_rules (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          budget_category_id INTEGER NOT NULL,
          threshold_pct REAL NOT NULL,
          enabled INTEGER DEFAULT 1,
          FOREIGN KEY (budget_category_id) REFERENCES budget_categories (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('CREATE INDEX IF NOT EXISTS idx_budgets_user_id ON budgets(user_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_budget_categories_budget_id ON budget_categories(budget_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_budget_periods_category_id ON budget_periods(budget_category_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_notification_rules_category_id ON notification_rules(budget_category_id)');
    }
  }
  
  // User operations
  Future<int> createUser({
    required String username,
    required String displayName,
    String? email,
    String? oauthProvider,
    String? oauthId,
    bool isGuest = false,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    return await db.insert('users', {
      'username': username,
      'display_name': displayName,
      'email': email,
      'oauth_provider': oauthProvider,
      'oauth_id': oauthId,
      'is_guest': isGuest ? 1 : 0,
      'created_at': now,
      'last_login': now,
      'is_active': 1,
    });
  }
  
  Future<Map<String, dynamic>?> getUserById(int userId) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    
    return results.isNotEmpty ? results.first : null;
  }
  
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'username = ? AND is_active = 1',
      whereArgs: [username],
      limit: 1,
    );
    
    return results.isNotEmpty ? results.first : null;
  }
  
  Future<Map<String, dynamic>?> getUserByOAuth(String provider, String oauthId) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'oauth_provider = ? AND oauth_id = ? AND is_active = 1',
      whereArgs: [provider, oauthId],
      limit: 1,
    );
    
    return results.isNotEmpty ? results.first : null;
  }
  
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query(
      'users',
      where: 'is_active = 1',
      orderBy: 'last_login DESC',
    );
  }
  
  Future<void> updateUserLastLogin(int userId) async {
    final db = await database;
    await db.update(
      'users',
      {'last_login': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
  
  Future<void> linkOAuthToUser(int userId, String provider, String oauthId, String email) async {
    final db = await database;
    await db.update(
      'users',
      {
        'oauth_provider': provider,
        'oauth_id': oauthId,
        'email': email,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
  
  Future<void> unlinkOAuthFromUser(int userId) async {
    final db = await database;
    await db.update(
      'users',
      {
        'oauth_provider': null,
        'oauth_id': null,
        'email': null,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> setUserDataConsent(int userId, bool consent) async {
    final db = await database;
    await db.update(
      'users',
      {'data_consent': consent ? 1 : 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
  
  // Transaction operations
  Future<int> insertTransaction(int userId, Map<String, dynamic> transaction) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final txId = await db.insert('transactions', {
      'user_id': userId,
      'transaction_id': transaction['transaction_id'] ?? 'tx_${now}_$userId',
      'type': transaction['type'] ?? 'expense',
      'amount': transaction['amount'] ?? 0.0,
      'currency': transaction['currency'] ?? 'VND',
      'category': transaction['category'],
      'description': transaction['description'],
      'payee': transaction['payee'],
      'date': transaction['date'] ?? DateTime.now().toIso8601String(),
      'account': transaction['account'],
      'is_synced': 0,
      'created_at': now,
      'updated_at': now,
    });
    
    // Insert postings if provided
    if (transaction['postings'] != null && transaction['postings'] is List) {
      final postings = transaction['postings'] as List;
      for (final posting in postings) {
        await db.insert('postings', {
          'transaction_id': txId,
          'account': posting['account'],
          'amount': posting['amount'],
          'commodity': posting['commodity'],
        });
      }
    }
    
    return txId;
  }
  
  Future<List<Map<String, dynamic>>> getPostingsByTransactionId(int transactionId) async {
    final db = await database;
    return await db.query(
      'postings',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
  }
  
  Future<List<Map<String, dynamic>>> getTransactionsByUserId(int userId) async {
    final db = await database;
    final transactions = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    
    // Attach postings to each transaction
    final List<Map<String, dynamic>> result = [];
    for (final tx in transactions) {
      final txMap = Map<String, dynamic>.from(tx);
      final postings = await getPostingsByTransactionId(tx['id'] as int);
      txMap['postings'] = postings;
      result.add(txMap);
    }
    
    return result;
  }
  
  Future<void> deleteTransaction(int transactionId) async {
    final db = await database;
    // Delete postings first (will be handled by CASCADE, but being explicit)
    await db.delete(
      'postings',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }
  
  Future<void> markTransactionAsSynced(int transactionId) async {
    final db = await database;
    await db.update(
      'transactions',
      {'is_synced': 1, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }
  
  Future<List<Map<String, dynamic>>> getUnsyncedTransactions(int userId) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'user_id = ? AND is_synced = 0',
      whereArgs: [userId],
    );
  }
  
  // Settings operations
  Future<void> setSetting(int userId, String key, String value) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.insert(
      'user_settings',
      {
        'user_id': userId,
        'key': key,
        'value': value,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<String?> getSetting(int userId, String key) async {
    final db = await database;
    final results = await db.query(
      'user_settings',
      where: 'user_id = ? AND key = ?',
      whereArgs: [userId, key],
      limit: 1,
    );
    
    return results.isNotEmpty ? results.first['value'] as String? : null;
  }
  
  Future<Map<String, String>> getAllSettings(int userId) async {
    final db = await database;
    final results = await db.query(
      'user_settings',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    
    return Map.fromEntries(
      results.map((row) => MapEntry(row['key'] as String, row['value'] as String)),
    );
  }
  
  Future<void> deleteSetting(int userId, String key) async {
    final db = await database;
    await db.delete(
      'user_settings',
      where: 'user_id = ? AND key = ?',
      whereArgs: [userId, key],
    );
  }
  
  // Profile operations
  Future<void> createProfile(Profile profile) async {
    final db = await database;
    await db.insert(
      'profiles',
      {
        'user_id': profile.userId,
        'avatar_path': profile.avatarPath,
        'date_of_birth': profile.dateOfBirth,
        'position': profile.position,
        'place_of_employment': profile.placeOfEmployment,
        'show_name': profile.showName ? 1 : 0,
        'show_email': profile.showEmail ? 1 : 0,
        'show_date_of_birth': profile.showDateOfBirth ? 1 : 0,
        'show_position': profile.showPosition ? 1 : 0,
        'show_place_of_employment': profile.showPlaceOfEmployment ? 1 : 0,
        'created_at': profile.createdAt.millisecondsSinceEpoch,
        'updated_at': profile.updatedAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getProfileByUserId(int userId) async {
    final db = await database;
    final results = await db.query(
      'profiles',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateProfile(Profile profile) async {
    final db = await database;
    await db.update(
      'profiles',
      {
        'avatar_path': profile.avatarPath,
        'date_of_birth': profile.dateOfBirth,
        'position': profile.position,
        'place_of_employment': profile.placeOfEmployment,
        'show_name': profile.showName ? 1 : 0,
        'show_email': profile.showEmail ? 1 : 0,
        'show_date_of_birth': profile.showDateOfBirth ? 1 : 0,
        'show_position': profile.showPosition ? 1 : 0,
        'show_place_of_employment': profile.showPlaceOfEmployment ? 1 : 0,
        'updated_at': profile.updatedAt.millisecondsSinceEpoch,
      },
      where: 'user_id = ?',
      whereArgs: [profile.userId],
    );
  }

  Future<void> deleteProfile(int userId) async {
    final db = await database;
    await db.delete(
      'profiles',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
  
  // Utility operations
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('user_settings');
    await db.delete('profiles');
    await db.delete('bills');
    await db.delete('users');
  }
  
  Future<void> clearUserData(int userId) async {
    final db = await database;
    await db.delete('transactions', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('user_settings', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('profiles', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('bills', where: 'user_id = ?', whereArgs: [userId]);
  }
  
  // Bill operations
  Future<int> insertBill(int userId, Map<String, dynamic> bill) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    return await db.insert('bills', {
      'user_id': userId,
      'name': bill['name'],
      'amount': bill['amount'],
      'currency': bill['currency'],
      'due_date': bill['due_date'],
      'recurrence': bill['recurrence'],
      'is_paid': bill['is_paid'] == true ? 1 : 0,
      'category': bill['category'],
      'notes': bill['notes'],
      'created_at': now,
      'updated_at': now,
    });
  }
  
  Future<List<Map<String, dynamic>>> getBillsByUserId(int userId) async {
    final db = await database;
    return await db.query(
      'bills',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'due_date ASC',
    );
  }
  
  Future<void> updateBill(int billId, Map<String, dynamic> bill) async {
    final db = await database;
    await db.update(
      'bills',
      {
        'name': bill['name'],
        'amount': bill['amount'],
        'currency': bill['currency'],
        'due_date': bill['due_date'],
        'recurrence': bill['recurrence'],
        'is_paid': bill['is_paid'] == true ? 1 : 0,
        'category': bill['category'],
        'notes': bill['notes'],
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [billId],
    );
  }
  
  Future<void> deleteBill(int billId) async {
    final db = await database;
    await db.delete(
      'bills',
      where: 'id = ?',
      whereArgs: [billId],
    );
  }
  
  // Investment operations
  Future<int> insertInvestment(int userId, Map<String, dynamic> investment) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    investment['user_id'] = userId;
    investment['created_at'] = investment['created_at'] ?? now;
    investment['updated_at'] = investment['updated_at'] ?? now;
    investment['is_synced'] = 0;
    return await db.insert('investments', investment);
  }

  Future<List<Map<String, dynamic>>> getInvestmentsByUserId(int userId) async {
    final db = await database;
    return await db.query(
      'investments',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<Map<String, dynamic>?> getInvestmentById(String investmentId) async {
    final db = await database;
    final results = await db.query(
      'investments',
      where: 'id = ?',
      whereArgs: [investmentId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateInvestment(String investmentId, Map<String, dynamic> investment) async {
    final db = await database;
    investment['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'investments',
      investment,
      where: 'id = ?',
      whereArgs: [investmentId],
    );
  }

  Future<void> deleteInvestment(String investmentId) async {
    final db = await database;
    await db.delete(
      'investments',
      where: 'id = ?',
      whereArgs: [investmentId],
    );
  }

  Future<void> markInvestmentAsSynced(String investmentId) async {
    final db = await database;
    await db.update(
      'investments',
      {'is_synced': 1, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [investmentId],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedInvestments(int userId) async {
    final db = await database;
    return await db.query(
      'investments',
      where: 'user_id = ? AND is_synced = 0',
      whereArgs: [userId],
    );
  }

  // Budget CRUD
  Future<int> insertBudget(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('budgets', data);
  }

  Future<List<Map<String, dynamic>>> getBudgetsByUserId(int userId) async {
    final db = await database;
    return await db.query(
      'budgets',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getActiveBudgetByUserId(int userId) async {
    final db = await database;
    final results = await db.query(
      'budgets',
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [userId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateBudget(int id, Map<String, dynamic> data) async {
    final db = await database;
    final updated = Map<String, dynamic>.from(data);
    updated['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'budgets',
      updated,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteBudget(int id) async {
    final db = await database;
    await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Budget Category CRUD
  Future<int> insertBudgetCategory(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('budget_categories', data);
  }

  Future<List<Map<String, dynamic>>> getBudgetCategoriesByBudgetId(int budgetId) async {
    final db = await database;
    return await db.query(
      'budget_categories',
      where: 'budget_id = ?',
      whereArgs: [budgetId],
      orderBy: 'sort_order ASC',
    );
  }

  Future<void> updateBudgetCategory(int id, Map<String, dynamic> data) async {
    final db = await database;
    final updated = Map<String, dynamic>.from(data);
    updated['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'budget_categories',
      updated,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteBudgetCategory(int id) async {
    final db = await database;
    await db.delete(
      'budget_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteBudgetCategoriesByBudgetId(int budgetId) async {
    final db = await database;
    await db.delete(
      'budget_categories',
      where: 'budget_id = ?',
      whereArgs: [budgetId],
    );
  }

  // Budget Period CRUD
  Future<int> insertBudgetPeriod(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('budget_periods', data);
  }

  Future<List<Map<String, dynamic>>> getBudgetPeriodsByCategoryId(int categoryId) async {
    final db = await database;
    return await db.query(
      'budget_periods',
      where: 'budget_category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'period_start DESC',
    );
  }

  Future<Map<String, dynamic>?> getBudgetPeriodForDate(int categoryId, String date) async {
    final db = await database;
    final results = await db.query(
      'budget_periods',
      where: 'budget_category_id = ? AND period_start <= ? AND period_end > ?',
      whereArgs: [categoryId, date, date],
      orderBy: 'period_start DESC',
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> deleteBudgetPeriodsByCategoryId(int categoryId) async {
    final db = await database;
    await db.delete(
      'budget_periods',
      where: 'budget_category_id = ?',
      whereArgs: [categoryId],
    );
  }

  // Notification Rule CRUD
  Future<int> insertNotificationRule(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('notification_rules', data);
  }

  Future<List<Map<String, dynamic>>> getNotificationRulesByCategoryId(int categoryId) async {
    final db = await database;
    return await db.query(
      'notification_rules',
      where: 'budget_category_id = ?',
      whereArgs: [categoryId],
    );
  }

  Future<void> updateNotificationRule(int id, Map<String, dynamic> data) async {
    final db = await database;
    await db.update(
      'notification_rules',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteNotificationRulesByCategoryId(int categoryId) async {
    final db = await database;
    await db.delete(
      'notification_rules',
      where: 'budget_category_id = ?',
      whereArgs: [categoryId],
    );
  }

  // Budget spending queries
  Future<List<Map<String, dynamic>>> getExpensePostingsForPeriod(
    int userId,
    String startDate,
    String endDate,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT p.* FROM postings p
      JOIN transactions t ON p.transaction_id = t.id
      WHERE t.user_id = ?
        AND t.date >= ?
        AND t.date < ?
        AND p.account LIKE 'Expenses:%'
        AND p.amount > 0
      ''',
      [userId, startDate, endDate],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
