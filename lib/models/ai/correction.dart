import 'package:equatable/equatable.dart';

class Correction extends Equatable {
  final int? id;
  final String feature;
  final String transactionId;
  final String aiSuggested;
  final String userChose;
  final String? payee;
  final int createdAt;

  const Correction({
    this.id,
    required this.feature,
    required this.transactionId,
    required this.aiSuggested,
    required this.userChose,
    this.payee,
    required this.createdAt,
  });

  factory Correction.fromMap(Map<String, dynamic> map) {
    return Correction(
      id: map['id'] as int?,
      feature: map['feature'] as String,
      transactionId: map['transaction_id'] as String,
      aiSuggested: map['ai_suggested'] as String,
      userChose: map['user_chose'] as String,
      payee: map['payee'] as String?,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'feature': feature,
      'transaction_id': transactionId,
      'ai_suggested': aiSuggested,
      'user_chose': userChose,
      'payee': payee,
      'created_at': createdAt,
    };
  }

  Map<String, dynamic> toApiFormat() {
    return {
      'payee': payee ?? '',
      'ai_suggested': aiSuggested,
      'user_chose': userChose,
    };
  }

  @override
  List<Object?> get props => [id, feature, transactionId, aiSuggested, userChose, createdAt];
}
