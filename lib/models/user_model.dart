import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user profile stored in the Firestore `users` collection.
class UserModel {
  final String uid;
  final String nama;
  final String email;
  final UserRole role;
  final int poin;
  final Timestamp? createdAt;

  const UserModel({
    required this.uid,
    required this.nama,
    required this.email,
    required this.role,
    this.poin = 0,
    this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      nama: data['nama'] ?? '',
      email: data['email'] ?? '',
      role: UserRole.fromString(data['role'] ?? 'customer'),
      poin: data['poin'] ?? 0,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nama': nama,
      'email': email,
      'role': role.value,
      'poin': poin,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Available user roles for role-based access control.
enum UserRole {
  admin,
  customer;

  String get value {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.customer:
        return 'customer';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.customer:
        return 'Customer';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.customer;
    }
  }
}
