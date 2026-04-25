class UserModel {
  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final String status;
  final bool isOnline;
  final int lastSeen;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl = '',
    this.status = 'Hey there! I am using Hello Chat 👋',
    this.isOnline = false,
    required this.lastSeen,
  });

  factory UserModel.fromMap(Map<dynamic, dynamic> map) {
    return UserModel(
      uid: (map['uid'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      photoUrl: (map['photoUrl'] ?? '').toString(),
      status: (map['status'] ?? 'Hey there! I am using Hello Chat 👋').toString(),
      isOnline: map['isOnline'] == true,
      lastSeen: (map['lastSeen'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'email': email,
    'photoUrl': photoUrl,
    'status': status,
    'isOnline': isOnline,
    'lastSeen': lastSeen,
  };

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    String? status,
    bool? isOnline,
    int? lastSeen,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}