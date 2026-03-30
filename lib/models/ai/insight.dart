import 'package:equatable/equatable.dart';

enum InsightType { spending, forecast, alert, coaching }

enum Severity { info, warning, positive }

enum CoachingDifficulty { easy, medium, hard }

enum PrivacyLevel { minimal, standard, full }

class InsightMetric extends Equatable {
  final String label;
  final String direction;
  final Severity severity;

  const InsightMetric({
    required this.label,
    required this.direction,
    required this.severity,
  });

  factory InsightMetric.fromJson(Map<String, dynamic> json) {
    return InsightMetric(
      label: json['label'] as String,
      direction: json['direction'] as String,
      severity: Severity.values.byName(json['severity'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'direction': direction,
      'severity': severity.name,
    };
  }

  @override
  List<Object?> get props => [label, direction, severity];
}

class HealthScoreComponent extends Equatable {
  final double value;
  final int score;

  const HealthScoreComponent({
    required this.value,
    required this.score,
  });

  factory HealthScoreComponent.fromJson(Map<String, dynamic> json) {
    return HealthScoreComponent(
      value: (json['value'] as num).toDouble(),
      score: json['score'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'score': score,
    };
  }

  @override
  List<Object?> get props => [value, score];
}

class HealthScore extends Equatable {
  final int score;
  final int? previousScore;
  final Map<String, HealthScoreComponent> components;
  final String summary;

  const HealthScore({
    required this.score,
    this.previousScore,
    required this.components,
    required this.summary,
  });

  factory HealthScore.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rawComponents =
        json['components'] as Map<String, dynamic>;
    final Map<String, HealthScoreComponent> parsedComponents =
        rawComponents.map(
      (String key, dynamic value) => MapEntry(
        key,
        HealthScoreComponent.fromJson(value as Map<String, dynamic>),
      ),
    );

    return HealthScore(
      score: json['score'] as int,
      previousScore: json['previousScore'] as int?,
      components: parsedComponents,
      summary: json['summary'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'previousScore': previousScore,
      'components': components.map(
        (String key, HealthScoreComponent value) =>
            MapEntry(key, value.toJson()),
      ),
      'summary': summary,
    };
  }

  @override
  List<Object?> get props => [score, previousScore, components, summary];
}

class SpendingInsight extends Equatable {
  final String id;
  final String title;
  final String body;
  final String? category;
  final InsightMetric? metric;

  const SpendingInsight({
    required this.id,
    required this.title,
    required this.body,
    this.category,
    this.metric,
  });

  factory SpendingInsight.fromJson(Map<String, dynamic> json) {
    return SpendingInsight(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      category: json['category'] as String?,
      metric: json['metric'] != null
          ? InsightMetric.fromJson(json['metric'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'category': category,
      'metric': metric?.toJson(),
    };
  }

  @override
  List<Object?> get props => [id, title, body, category, metric];
}

class DailyProjection extends Equatable {
  final String date;
  final double optimistic;
  final double likely;
  final double pessimistic;

  const DailyProjection({
    required this.date,
    required this.optimistic,
    required this.likely,
    required this.pessimistic,
  });

  factory DailyProjection.fromJson(Map<String, dynamic> json) {
    return DailyProjection(
      date: json['date'] as String,
      optimistic: (json['optimistic'] as num).toDouble(),
      likely: (json['likely'] as num).toDouble(),
      pessimistic: (json['pessimistic'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'optimistic': optimistic,
      'likely': likely,
      'pessimistic': pessimistic,
    };
  }

  @override
  List<Object?> get props => [date, optimistic, likely, pessimistic];
}

class Forecast extends Equatable {
  final Map<String, double> projectedBalance;
  final List<DailyProjection> dailyProjection;
  final String summary;

  const Forecast({
    required this.projectedBalance,
    required this.dailyProjection,
    required this.summary,
  });

  factory Forecast.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rawBalance =
        json['projectedBalance'] as Map<String, dynamic>;
    final Map<String, double> parsedBalance = rawBalance.map(
      (String key, dynamic value) => MapEntry(key, (value as num).toDouble()),
    );

    final List<dynamic> rawProjections =
        json['dailyProjection'] as List<dynamic>;
    final List<DailyProjection> parsedProjections = rawProjections
        .map((dynamic e) =>
            DailyProjection.fromJson(e as Map<String, dynamic>))
        .toList();

    return Forecast(
      projectedBalance: parsedBalance,
      dailyProjection: parsedProjections,
      summary: json['summary'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectedBalance': projectedBalance,
      'dailyProjection':
          dailyProjection.map((DailyProjection e) => e.toJson()).toList(),
      'summary': summary,
    };
  }

  @override
  List<Object?> get props => [projectedBalance, dailyProjection, summary];
}

class Alert extends Equatable {
  final String id;
  final String title;
  final String body;
  final Severity severity;
  final bool isRead;

  const Alert({
    required this.id,
    required this.title,
    required this.body,
    required this.severity,
    this.isRead = false,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      severity: Severity.values.byName(json['severity'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'severity': severity.name,
      'isRead': isRead,
    };
  }

  @override
  List<Object?> get props => [id, title, body, severity, isRead];
}

class CoachingTip extends Equatable {
  final String id;
  final String title;
  final String body;
  final double? savingsEstimate;
  final CoachingDifficulty difficulty;
  final bool isSaved;

  const CoachingTip({
    required this.id,
    required this.title,
    required this.body,
    this.savingsEstimate,
    required this.difficulty,
    this.isSaved = false,
  });

  factory CoachingTip.fromJson(Map<String, dynamic> json) {
    return CoachingTip(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      savingsEstimate: json['savingsEstimate'] != null
          ? (json['savingsEstimate'] as num).toDouble()
          : null,
      difficulty:
          CoachingDifficulty.values.byName(json['difficulty'] as String),
      isSaved: json['isSaved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'savingsEstimate': savingsEstimate,
      'difficulty': difficulty.name,
      'isSaved': isSaved,
    };
  }

  @override
  List<Object?> get props =>
      [id, title, body, savingsEstimate, difficulty, isSaved];
}

class InsightsResponse extends Equatable {
  final DateTime generatedAt;
  final HealthScore? healthScore;
  final List<SpendingInsight> spending;
  final Forecast? forecast;
  final List<Alert> alerts;
  final List<CoachingTip> coaching;

  const InsightsResponse({
    required this.generatedAt,
    this.healthScore,
    required this.spending,
    this.forecast,
    required this.alerts,
    required this.coaching,
  });

  factory InsightsResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawSpending = json['spending'] as List<dynamic>;
    final List<SpendingInsight> parsedSpending = rawSpending
        .map((dynamic e) =>
            SpendingInsight.fromJson(e as Map<String, dynamic>))
        .toList();

    final List<dynamic> rawAlerts = json['alerts'] as List<dynamic>;
    final List<Alert> parsedAlerts = rawAlerts
        .map((dynamic e) => Alert.fromJson(e as Map<String, dynamic>))
        .toList();

    final List<dynamic> rawCoaching = json['coaching'] as List<dynamic>;
    final List<CoachingTip> parsedCoaching = rawCoaching
        .map((dynamic e) => CoachingTip.fromJson(e as Map<String, dynamic>))
        .toList();

    return InsightsResponse(
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      healthScore: json['healthScore'] != null
          ? HealthScore.fromJson(json['healthScore'] as Map<String, dynamic>)
          : null,
      spending: parsedSpending,
      forecast: json['forecast'] != null
          ? Forecast.fromJson(json['forecast'] as Map<String, dynamic>)
          : null,
      alerts: parsedAlerts,
      coaching: parsedCoaching,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'healthScore': healthScore?.toJson(),
      'spending':
          spending.map((SpendingInsight e) => e.toJson()).toList(),
      'forecast': forecast?.toJson(),
      'alerts': alerts.map((Alert e) => e.toJson()).toList(),
      'coaching': coaching.map((CoachingTip e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props =>
      [generatedAt, healthScore, spending, forecast, alerts, coaching];
}
