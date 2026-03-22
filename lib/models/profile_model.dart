import 'package:equatable/equatable.dart';

/// Profile model extending user information with personal details
class Profile extends Equatable {
  final int userId;
  final String? avatarPath;
  final String? dateOfBirth;
  final String? position;
  final String? placeOfEmployment;
  final bool showName;
  final bool showEmail;
  final bool showDateOfBirth;
  final bool showPosition;
  final bool showPlaceOfEmployment;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.userId,
    this.avatarPath,
    this.dateOfBirth,
    this.position,
    this.placeOfEmployment,
    this.showName = true,
    this.showEmail = true,
    this.showDateOfBirth = false,
    this.showPosition = false,
    this.showPlaceOfEmployment = false,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [userId, avatarPath, dateOfBirth, position, placeOfEmployment, showName, showEmail, showDateOfBirth, showPosition, showPlaceOfEmployment, createdAt, updatedAt];

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      userId: map['user_id'] as int,
      avatarPath: map['avatar_path'] as String?,
      dateOfBirth: map['date_of_birth'] as String?,
      position: map['position'] as String?,
      placeOfEmployment: map['place_of_employment'] as String?,
      showName: (map['show_name'] as int) == 1,
      showEmail: (map['show_email'] as int) == 1,
      showDateOfBirth: (map['show_date_of_birth'] as int) == 1,
      showPosition: (map['show_position'] as int) == 1,
      showPlaceOfEmployment: (map['show_place_of_employment'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'avatar_path': avatarPath,
      'date_of_birth': dateOfBirth,
      'position': position,
      'place_of_employment': placeOfEmployment,
      'show_name': showName ? 1 : 0,
      'show_email': showEmail ? 1 : 0,
      'show_date_of_birth': showDateOfBirth ? 1 : 0,
      'show_position': showPosition ? 1 : 0,
      'show_place_of_employment': showPlaceOfEmployment ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Profile copyWith({
    int? userId,
    String? avatarPath,
    String? dateOfBirth,
    String? position,
    String? placeOfEmployment,
    bool? showName,
    bool? showEmail,
    bool? showDateOfBirth,
    bool? showPosition,
    bool? showPlaceOfEmployment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      userId: userId ?? this.userId,
      avatarPath: avatarPath ?? this.avatarPath,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      position: position ?? this.position,
      placeOfEmployment: placeOfEmployment ?? this.placeOfEmployment,
      showName: showName ?? this.showName,
      showEmail: showEmail ?? this.showEmail,
      showDateOfBirth: showDateOfBirth ?? this.showDateOfBirth,
      showPosition: showPosition ?? this.showPosition,
      showPlaceOfEmployment: showPlaceOfEmployment ?? this.showPlaceOfEmployment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
