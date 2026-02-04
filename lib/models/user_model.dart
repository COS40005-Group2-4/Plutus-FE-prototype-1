class User {
  final int id;
  final String username;
  final String displayName;
  final String? email;
  final String? oauthProvider;
  final String? oauthId;
  final bool isGuest;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isActive;
  
  User({
    required this.id,
    required this.username,
    required this.displayName,
    this.email,
    this.oauthProvider,
    this.oauthId,
    this.isGuest = false,
    required this.createdAt,
    required this.lastLogin,
    this.isActive = true,
  });
  
  bool get hasOAuth => oauthProvider != null && oauthId != null;
  
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      username: map['username'] as String,
      displayName: map['display_name'] as String,
      email: map['email'] as String?,
      oauthProvider: map['oauth_provider'] as String?,
      oauthId: map['oauth_id'] as String?,
      isGuest: (map['is_guest'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      lastLogin: DateTime.fromMillisecondsSinceEpoch(map['last_login'] as int),
      isActive: (map['is_active'] as int) == 1,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'email': email,
      'oauth_provider': oauthProvider,
      'oauth_id': oauthId,
      'is_guest': isGuest ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_login': lastLogin.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
    };
  }
  
  User copyWith({
    int? id,
    String? username,
    String? displayName,
    String? email,
    String? oauthProvider,
    String? oauthId,
    bool? isGuest,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      oauthProvider: oauthProvider ?? this.oauthProvider,
      oauthId: oauthId ?? this.oauthId,
      isGuest: isGuest ?? this.isGuest,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
    );
  }
}
