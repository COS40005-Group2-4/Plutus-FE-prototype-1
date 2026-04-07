import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/ai/insight.dart';
import '../services/interfaces/i_insights_service.dart';
import '../services/database_service.dart';
import '../providers/settings_provider.dart';

class InsightsProvider extends ChangeNotifier {
  final IInsightsService _insightsService;
  final DatabaseService _databaseService;
  final SettingsProvider _settingsProvider;

  InsightsResponse? _latestInsights;
  DateTime? _lastGenerated;
  bool _isGenerating = false;
  String? _error;
  bool _showImportBanner = false;
  bool _cacheLoaded = false;

  // Period selection (presets or custom date range)
  static const List<int> kPeriodPresets = <int>[1, 3, 6, 12];
  static const double kFontSizeMin = 12.0;
  static const double kFontSizeMax = 20.0;
  static const double kFontSizeStep = 2.0;
  static const double kFontSizeDefault = 14.0;

  int _selectedPeriodMonths = 3;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  double _insightsFontSize = kFontSizeDefault;

  InsightsProvider({
    required IInsightsService insightsService,
    required DatabaseService databaseService,
    required SettingsProvider settingsProvider,
  })  : _insightsService = insightsService,
        _databaseService = databaseService,
        _settingsProvider = settingsProvider {
    _loadCachedInsights();
  }

  // Getters
  InsightsResponse? get latestInsights => _latestInsights;
  DateTime? get lastGenerated => _lastGenerated;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  bool get showImportBanner => _showImportBanner;
  bool get hasInsights => _latestInsights != null;
  bool get cacheLoaded => _cacheLoaded;

  HealthScore? get healthScore => _latestInsights?.healthScore;
  List<SpendingInsight> get spendingInsights => _latestInsights?.spending ?? <SpendingInsight>[];
  Forecast? get forecast => _latestInsights?.forecast;
  List<Alert> get alerts => _latestInsights?.alerts ?? <Alert>[];
  List<CoachingTip> get coachingTips => _latestInsights?.coaching ?? <CoachingTip>[];

  int get unreadAlertCount => alerts.where((a) => !a.isRead).length;

  int get selectedPeriodMonths => _selectedPeriodMonths;
  DateTime? get customStartDate => _customStartDate;
  DateTime? get customEndDate => _customEndDate;
  bool get hasCustomDateRange => _customStartDate != null && _customEndDate != null;
  double get insightsFontSize => _insightsFontSize;
  bool get canIncreaseFontSize => _insightsFontSize < kFontSizeMax;
  bool get canDecreaseFontSize => _insightsFontSize > kFontSizeMin;

  /// Main action: generate insights from cloud AI
  Future<void> generateInsights({
    List<String> requestedTypes = const <String>['spending', 'forecast', 'alerts', 'coaching'],
  }) async {
    _isGenerating = true;
    _error = null;
    _showImportBanner = false;
    notifyListeners();

    try {
      final String locale = _settingsProvider.language.code;
      final PrivacyLevel privacyLevel = _settingsProvider.privacyLevel;

      // Build data payload from local transactions
      final Map<String, dynamic> data = await _buildDataPayload(privacyLevel);

      // Capture previous health score for trend tracking
      final int? previousHealthScore = _latestInsights?.healthScore?.score;

      InsightsResponse response = await _insightsService.generateInsights(
        locale: locale,
        privacyLevel: privacyLevel,
        requestedTypes: requestedTypes,
        data: data,
      );

      // Inject previousScore so the health widget shows trend arrow
      if (previousHealthScore != null && response.healthScore != null) {
        response = InsightsResponse(
          generatedAt: response.generatedAt,
          healthScore: HealthScore(
            score: response.healthScore!.score,
            previousScore: previousHealthScore,
            components: response.healthScore!.components,
            summary: response.healthScore!.summary,
          ),
          spending: response.spending,
          forecast: response.forecast,
          alerts: response.alerts,
          coaching: response.coaching,
        );
      }

      // Cache to local DB first, then update in-memory state
      try {
        await _cacheInsights(response);
        if (kDebugMode) debugPrint('InsightsProvider: cached ${response.spending.length} spending, ${response.alerts.length} alerts, ${response.coaching.length} coaching to DB');
      } catch (cacheError) {
        if (kDebugMode) debugPrint('InsightsProvider: cache write failed: $cacheError');
        // Continue — data still available in memory for this session
      }

      _latestInsights = response;
      _lastGenerated = response.generatedAt;
      _error = null;

      // Purge old insights (>30 days)
      try {
        await _purgeOldInsights();
      } catch (purgeError) {
        if (kDebugMode) debugPrint('InsightsProvider: purge failed: $purgeError');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) debugPrint('InsightsProvider: generate failed: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Reload insights from local DB cache.
  /// Call after backup restore to pick up insights from the restored DB.
  Future<void> reloadFromCache() async {
    await _loadCachedInsights();
  }

  /// Called after transaction imports to show banner
  void onTransactionsImported() {
    _showImportBanner = true;
    notifyListeners();
  }

  /// Dismiss the import banner without generating
  void dismissImportBanner() {
    _showImportBanner = false;
    notifyListeners();
  }

  /// Set a preset period (1, 3, 6, or 12 months). Clears any custom range.
  void setPeriodPreset(int months) {
    _selectedPeriodMonths = months;
    _customStartDate = null;
    _customEndDate = null;
    notifyListeners();
  }

  /// Set a custom date range for insights analysis.
  void setCustomDateRange(DateTime start, DateTime end) {
    _customStartDate = start;
    _customEndDate = end;
    // Approximate months for payload
    _selectedPeriodMonths = end.difference(start).inDays ~/ 30;
    if (_selectedPeriodMonths < 1) _selectedPeriodMonths = 1;
    notifyListeners();
  }

  /// Clear custom date range and revert to 3-month default.
  void clearCustomDateRange() {
    _customStartDate = null;
    _customEndDate = null;
    _selectedPeriodMonths = 3;
    notifyListeners();
  }

  /// Increase insight text font size by one step (max 20.0).
  void increaseFontSize() {
    if (_insightsFontSize < kFontSizeMax) {
      _insightsFontSize = (_insightsFontSize + kFontSizeStep).clamp(kFontSizeMin, kFontSizeMax);
      notifyListeners();
    }
  }

  /// Decrease insight text font size by one step (min 12.0).
  void decreaseFontSize() {
    if (_insightsFontSize > kFontSizeMin) {
      _insightsFontSize = (_insightsFontSize - kFontSizeStep).clamp(kFontSizeMin, kFontSizeMax);
      notifyListeners();
    }
  }

  /// Mark a single alert as read
  void markAlertRead(String alertId) {
    if (_latestInsights == null) return;
    final List<Alert> updatedAlerts = _latestInsights!.alerts.map((Alert a) {
      if (a.id == alertId) {
        return Alert(
          id: a.id,
          title: a.title,
          body: a.body,
          severity: a.severity,
          isRead: true,
        );
      }
      return a;
    }).toList();

    _latestInsights = InsightsResponse(
      generatedAt: _latestInsights!.generatedAt,
      healthScore: _latestInsights!.healthScore,
      spending: _latestInsights!.spending,
      forecast: _latestInsights!.forecast,
      alerts: updatedAlerts,
      coaching: _latestInsights!.coaching,
    );

    _updateInsightInDb(alertId, isRead: true);
    notifyListeners();
  }

  /// Mark all alerts as read
  void markAllAlertsRead() {
    if (_latestInsights == null) return;
    final List<Alert> updatedAlerts = _latestInsights!.alerts.map((Alert a) {
      return Alert(
        id: a.id,
        title: a.title,
        body: a.body,
        severity: a.severity,
        isRead: true,
      );
    }).toList();

    _latestInsights = InsightsResponse(
      generatedAt: _latestInsights!.generatedAt,
      healthScore: _latestInsights!.healthScore,
      spending: _latestInsights!.spending,
      forecast: _latestInsights!.forecast,
      alerts: updatedAlerts,
      coaching: _latestInsights!.coaching,
    );

    _markAllReadInDb();
    notifyListeners();
  }

  /// Save a coaching tip (persists beyond 30-day purge)
  void saveCoachingTip(String tipId) {
    if (_latestInsights == null) return;
    final List<CoachingTip> updatedTips = _latestInsights!.coaching.map((CoachingTip t) {
      if (t.id == tipId) {
        return CoachingTip(
          id: t.id,
          title: t.title,
          body: t.body,
          savingsEstimate: t.savingsEstimate,
          difficulty: t.difficulty,
          isSaved: true,
        );
      }
      return t;
    }).toList();

    _latestInsights = InsightsResponse(
      generatedAt: _latestInsights!.generatedAt,
      healthScore: _latestInsights!.healthScore,
      spending: _latestInsights!.spending,
      forecast: _latestInsights!.forecast,
      alerts: _latestInsights!.alerts,
      coaching: updatedTips,
    );

    _updateInsightInDb(tipId, isSaved: true);
    notifyListeners();
  }

  /// Dismiss a coaching tip (remove from list)
  void dismissCoachingTip(String tipId) {
    if (_latestInsights == null) return;
    final List<CoachingTip> updatedTips =
        _latestInsights!.coaching.where((CoachingTip t) => t.id != tipId).toList();

    _latestInsights = InsightsResponse(
      generatedAt: _latestInsights!.generatedAt,
      healthScore: _latestInsights!.healthScore,
      spending: _latestInsights!.spending,
      forecast: _latestInsights!.forecast,
      alerts: _latestInsights!.alerts,
      coaching: updatedTips,
    );

    _deleteInsightFromDb(tipId);
    notifyListeners();
  }

  // ── Private: Data payload builders ──

  Future<Map<String, dynamic>> _buildDataPayload(PrivacyLevel privacyLevel) async {
    final db = await _databaseService.database;
    final String currency = _settingsProvider.currency.code;
    final DateTime now = DateTime.now();

    final DateTime periodStart = hasCustomDateRange
        ? _customStartDate!
        : now.subtract(Duration(days: _selectedPeriodMonths * 30));
    final DateTime periodEnd = hasCustomDateRange ? _customEndDate! : now;
    final int activePeriodMonths = hasCustomDateRange
        ? (periodEnd.difference(periodStart).inDays ~/ 30).clamp(1, 24)
        : _selectedPeriodMonths;
    final String periodStartStr = periodStart.toIso8601String().split('T').first;
    final String extendedStartStr = periodStart.isBefore(now.subtract(const Duration(days: 180)))
        ? periodStartStr
        : now.subtract(const Duration(days: 180)).toIso8601String().split('T').first;

    final Map<String, dynamic> data = <String, dynamic>{
      'currency': currency == 'ORIGINAL' ? 'VND' : currency,
      'currentDate': now.toIso8601String().split('T').first,
      'periodMonths': activePeriodMonths,
    };

    // Always include daily spending (no PII)
    final List<Map<String, Object?>> dailyRows = await db.rawQuery('''
      SELECT date, SUM(amount) as total
      FROM transactions
      WHERE type = 'expense' AND date >= ?
      GROUP BY date
      ORDER BY date ASC
    ''', <Object>[periodStartStr]);

    data['dailySpending'] = dailyRows
        .map((Map<String, Object?> r) => (r['total'] as num?)?.toDouble() ?? 0.0)
        .toList();

    // Category totals (all privacy levels)
    final List<Map<String, Object?>> categoryRows = await db.rawQuery('''
      SELECT category,
             SUM(CASE WHEN date >= ? THEN amount ELSE 0 END) as month1,
             COUNT(CASE WHEN date >= ? THEN 1 END) as count1
      FROM transactions
      WHERE type = 'expense' AND date >= ?
      GROUP BY category
    ''', <Object>[periodStartStr, periodStartStr, periodStartStr]);

    data['categories'] = categoryRows.map((Map<String, Object?> r) => <String, dynamic>{
      'name': r['category'] ?? 'Other',
      'amounts': <double>[(r['month1'] as num?)?.toDouble() ?? 0.0],
      'txCount': <int>[(r['count1'] as num?)?.toInt() ?? 0],
    }).toList();

    // Monthly income/expense totals
    final List<Map<String, Object?>> monthlyRows = await db.rawQuery('''
      SELECT type, SUM(amount) as total
      FROM transactions
      WHERE date >= ?
      GROUP BY type
    ''', <Object>[periodStartStr]);

    double totalIncome = 0;
    double totalExpense = 0;
    for (final Map<String, Object?> row in monthlyRows) {
      if (row['type'] == 'income') {
        totalIncome = (row['total'] as num?)?.toDouble() ?? 0.0;
      } else {
        totalExpense = (row['total'] as num?)?.toDouble() ?? 0.0;
      }
    }
    data['monthlyIncome'] = <double>[totalIncome];
    data['monthlyExpense'] = <double>[totalExpense];

    // Standard+ privacy: add top merchants
    if (privacyLevel == PrivacyLevel.standard || privacyLevel == PrivacyLevel.full) {
      final List<Map<String, Object?>> merchantRows = await db.rawQuery('''
        SELECT payee, category, COUNT(*) as cnt, SUM(amount) as total
        FROM transactions
        WHERE type = 'expense' AND date >= ? AND payee IS NOT NULL AND payee != ''
        GROUP BY payee, category
        ORDER BY total DESC
        LIMIT 20
      ''', <Object>[periodStartStr]);

      data['topMerchants'] = merchantRows.map((Map<String, Object?> r) => <String, dynamic>{
        'name': r['payee'] ?? '',
        'category': r['category'] ?? 'Other',
        'count': (r['cnt'] as num?)?.toInt() ?? 0,
        'total': (r['total'] as num?)?.toDouble() ?? 0.0,
      }).toList();
    }

    // Full privacy: add individual transactions
    if (privacyLevel == PrivacyLevel.full) {
      final List<Map<String, Object?>> txnRows = await db.rawQuery('''
        SELECT payee, amount, date, description
        FROM transactions
        WHERE date >= ?
        ORDER BY date DESC
        LIMIT 500
      ''', <Object>[extendedStartStr]);

      data['transactions'] = txnRows.map((Map<String, Object?> r) => <String, dynamic>{
        'payee': r['payee'] ?? '',
        'amount': (r['amount'] as num?)?.toDouble() ?? 0.0,
        'date': r['date'] ?? '',
        'description': r['description'] ?? '',
      }).toList();
    }

    return data;
  }

  // ── Private: SQLite cache operations ──

  Future<void> _cacheInsights(InsightsResponse response) async {
    final db = await _databaseService.database;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int generatedAt = response.generatedAt.millisecondsSinceEpoch;

    final Batch batch = db.batch();

    // Store health score
    if (response.healthScore != null) {
      batch.insert('insights', <String, Object?>{
        'id': 'health_score_${response.generatedAt.toIso8601String()}',
        'type': 'health_score',
        'title': 'Health Score',
        'body': response.healthScore!.summary,
        'metadata': jsonEncode(response.healthScore!.toJson()),
        'severity': null,
        'is_read': 0,
        'is_saved': 0,
        'generated_at': generatedAt,
        'created_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Store forecast
    if (response.forecast != null) {
      batch.insert('insights', <String, Object?>{
        'id': 'forecast_${response.generatedAt.toIso8601String()}',
        'type': 'forecast',
        'title': 'Cash Flow Forecast',
        'body': response.forecast!.summary,
        'metadata': jsonEncode(response.forecast!.toJson()),
        'severity': null,
        'is_read': 0,
        'is_saved': 0,
        'generated_at': generatedAt,
        'created_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Store spending insights
    for (final SpendingInsight insight in response.spending) {
      batch.insert('insights', <String, Object?>{
        'id': insight.id,
        'type': 'spending',
        'title': insight.title,
        'body': insight.body,
        'metadata': jsonEncode(insight.toJson()),
        'severity': insight.metric?.severity.name,
        'is_read': 0,
        'is_saved': 0,
        'generated_at': generatedAt,
        'created_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Store alerts
    for (final Alert alert in response.alerts) {
      batch.insert('insights', <String, Object?>{
        'id': alert.id,
        'type': 'alert',
        'title': alert.title,
        'body': alert.body,
        'metadata': jsonEncode(alert.toJson()),
        'severity': alert.severity.name,
        'is_read': alert.isRead ? 1 : 0,
        'is_saved': 0,
        'generated_at': generatedAt,
        'created_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Store coaching tips
    for (final CoachingTip tip in response.coaching) {
      batch.insert('insights', <String, Object?>{
        'id': tip.id,
        'type': 'coaching',
        'title': tip.title,
        'body': tip.body,
        'metadata': jsonEncode(tip.toJson()),
        'severity': null,
        'is_read': 0,
        'is_saved': tip.isSaved ? 1 : 0,
        'generated_at': generatedAt,
        'created_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);

    // Verify the write actually persisted
    if (kDebugMode) {
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM insights'),
      );
      debugPrint('InsightsProvider: insights table now has $count rows');
    }
  }

  Future<void> _loadCachedInsights() async {
    try {
      final db = await _databaseService.database;

      // Verify the table has data
      final int? rowCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM insights'),
      );
      if (kDebugMode) {
        debugPrint('InsightsProvider: loading cache — insights table has $rowCount rows');
      }
      if (rowCount == null || rowCount == 0) {
        _cacheLoaded = true;
        notifyListeners();
        return;
      }

      // Load latest health score
      final List<Map<String, Object?>> healthRows = await db.query(
        'insights',
        where: 'type = ?',
        whereArgs: <Object>['health_score'],
        orderBy: 'generated_at DESC',
        limit: 1,
      );

      // Load latest forecast
      final List<Map<String, Object?>> forecastRows = await db.query(
        'insights',
        where: 'type = ?',
        whereArgs: <Object>['forecast'],
        orderBy: 'generated_at DESC',
        limit: 1,
      );

      // Load spending insights (latest batch)
      final List<Map<String, Object?>> spendingRows = await db.query(
        'insights',
        where: 'type = ?',
        whereArgs: <Object>['spending'],
        orderBy: 'generated_at DESC',
        limit: 10,
      );

      // Load alerts
      final List<Map<String, Object?>> alertRows = await db.query(
        'insights',
        where: 'type = ?',
        whereArgs: <Object>['alert'],
        orderBy: 'generated_at DESC',
        limit: 20,
      );

      // Load coaching tips
      final List<Map<String, Object?>> coachingRows = await db.query(
        'insights',
        where: 'type = ?',
        whereArgs: <Object>['coaching'],
        orderBy: 'generated_at DESC',
        limit: 20,
      );

      if (healthRows.isEmpty && forecastRows.isEmpty && spendingRows.isEmpty &&
          alertRows.isEmpty && coachingRows.isEmpty) {
        _cacheLoaded = true;
        notifyListeners();
        return;
      }

      HealthScore? healthScore;
      if (healthRows.isNotEmpty && healthRows.first['metadata'] != null) {
        healthScore = HealthScore.fromJson(
          jsonDecode(healthRows.first['metadata'] as String) as Map<String, dynamic>,
        );
      }

      Forecast? forecast;
      if (forecastRows.isNotEmpty && forecastRows.first['metadata'] != null) {
        forecast = Forecast.fromJson(
          jsonDecode(forecastRows.first['metadata'] as String) as Map<String, dynamic>,
        );
      }

      final List<SpendingInsight> spending = spendingRows
          .where((Map<String, Object?> r) => r['metadata'] != null)
          .map((Map<String, Object?> r) => SpendingInsight.fromJson(
                jsonDecode(r['metadata'] as String) as Map<String, dynamic>,
              ))
          .toList();

      final List<Alert> alerts = alertRows
          .where((Map<String, Object?> r) => r['metadata'] != null)
          .map((Map<String, Object?> r) {
        final Alert alert = Alert.fromJson(
          jsonDecode(r['metadata'] as String) as Map<String, dynamic>,
        );
        // Apply local read state from DB
        final bool isRead = (r['is_read'] as int?) == 1;
        if (isRead != alert.isRead) {
          return Alert(
            id: alert.id,
            title: alert.title,
            body: alert.body,
            severity: alert.severity,
            isRead: isRead,
          );
        }
        return alert;
      }).toList();

      final List<CoachingTip> coaching = coachingRows
          .where((Map<String, Object?> r) => r['metadata'] != null)
          .map((Map<String, Object?> r) {
        final CoachingTip tip = CoachingTip.fromJson(
          jsonDecode(r['metadata'] as String) as Map<String, dynamic>,
        );
        final bool isSaved = (r['is_saved'] as int?) == 1;
        if (isSaved != tip.isSaved) {
          return CoachingTip(
            id: tip.id,
            title: tip.title,
            body: tip.body,
            savingsEstimate: tip.savingsEstimate,
            difficulty: tip.difficulty,
            isSaved: isSaved,
          );
        }
        return tip;
      }).toList();

      // Determine generated timestamp from most recent row
      int latestTimestamp = 0;
      for (final List<Map<String, Object?>> rows in <List<Map<String, Object?>>>[
        healthRows, forecastRows, spendingRows, alertRows, coachingRows
      ]) {
        if (rows.isNotEmpty) {
          final int ts = (rows.first['generated_at'] as int?) ?? 0;
          if (ts > latestTimestamp) latestTimestamp = ts;
        }
      }

      _latestInsights = InsightsResponse(
        generatedAt: DateTime.fromMillisecondsSinceEpoch(latestTimestamp),
        healthScore: healthScore,
        spending: spending,
        forecast: forecast,
        alerts: alerts,
        coaching: coaching,
      );
      _lastGenerated = DateTime.fromMillisecondsSinceEpoch(latestTimestamp);
      _cacheLoaded = true;

      if (kDebugMode) {
        debugPrint('InsightsProvider: restored ${spending.length} spending, '
            '${alerts.length} alerts, ${coaching.length} coaching from cache '
            '(generated $_lastGenerated)');
      }

      notifyListeners();
    } catch (e, stack) {
      _cacheLoaded = true;
      if (kDebugMode) {
        debugPrint('InsightsProvider: load cache failed: $e');
        debugPrint('$stack');
      }
      notifyListeners();
    }
  }

  Future<void> _purgeOldInsights() async {
    final db = await _databaseService.database;
    final int cutoff = DateTime.now()
        .subtract(const Duration(days: 30))
        .millisecondsSinceEpoch;

    // Don't purge saved coaching tips
    await db.delete(
      'insights',
      where: 'generated_at < ? AND is_saved = 0',
      whereArgs: <Object>[cutoff],
    );
  }

  Future<void> _updateInsightInDb(String id, {bool? isRead, bool? isSaved}) async {
    try {
      final db = await _databaseService.database;
      final Map<String, Object?> values = <String, Object?>{};
      if (isRead != null) values['is_read'] = isRead ? 1 : 0;
      if (isSaved != null) values['is_saved'] = isSaved ? 1 : 0;
      if (values.isNotEmpty) {
        await db.update('insights', values, where: 'id = ?', whereArgs: <Object>[id]);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('InsightsProvider: update DB failed: $e');
    }
  }

  Future<void> _markAllReadInDb() async {
    try {
      final db = await _databaseService.database;
      await db.update(
        'insights',
        <String, Object?>{'is_read': 1},
        where: 'type = ? AND is_read = 0',
        whereArgs: <Object>['alert'],
      );
    } catch (e) {
      if (kDebugMode) debugPrint('InsightsProvider: mark all read failed: $e');
    }
  }

  Future<void> _deleteInsightFromDb(String id) async {
    try {
      final db = await _databaseService.database;
      await db.delete('insights', where: 'id = ?', whereArgs: <Object>[id]);
    } catch (e) {
      if (kDebugMode) debugPrint('InsightsProvider: delete from DB failed: $e');
    }
  }
}
