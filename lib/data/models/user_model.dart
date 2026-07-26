class UserModel {
  final int? id;
  final String? fullName;
  final String? phone;
  final String? avatar;
  final DateTime? createdAt;

  UserModel({
    this.id,
    this.fullName,
    this.phone,
    this.avatar,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['fullName'] ?? json['fullname'],
      phone: json['phone'],
      avatar: json['avatar'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'avatar': avatar,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
