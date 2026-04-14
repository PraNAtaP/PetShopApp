import 'package:cloud_firestore/cloud_firestore.dart';

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

/// Represents a user profile stored in the Firestore `users` collection.
class UserModel {
  final String uid;
  final String nama;
  final String email;
  final UserRole role;
  final String? fotoUrl;
  final String? nomorWa;
  final String? alamat;
  final GeoPoint? koordinat;
  final int poin;
  final DateTime? createdAt;

  /// Creates a new [UserModel] instance.
  const UserModel({
    required this.uid,
    required this.nama,
    required this.email,
    required this.role,
    this.fotoUrl,
    this.nomorWa,
    this.alamat,
    this.koordinat,
    this.poin = 0,
    this.createdAt,
  });

  /// Factory constructor to create a [UserModel] from a Firestore [DocumentSnapshot].
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      nama: data['nama'] ?? '',
      email: data['email'] ?? '',
      role: UserRole.fromString(data['role'] ?? 'customer'),
      fotoUrl: data['foto_url'] as String?,
      nomorWa: data['nomor_wa'] as String?,
      alamat: data['alamat'] as String?,
      koordinat: data['koordinat'] as GeoPoint?,
      poin: data['poin'] ?? 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts the [UserModel] instance into a Map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'email': email,
      'role': role.value,
      'foto_url': fotoUrl,
      'nomor_wa': nomorWa,
      'alamat': alamat,
      'koordinat': koordinat,
      'poin': poin,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
  
  /// Helper method for creating [UserModel] for Firestore inserts where you might want serverTimestamp handling.
  Map<String, dynamic> toFirestore() {
    final map = toMap();
    if (createdAt == null) {
      map['created_at'] = FieldValue.serverTimestamp();
    }
    return map;
  }

  /// Creates a copy of this [UserModel] but with the given fields replaced with the new values.
  UserModel copyWith({
    String? uid,
    String? nama,
    String? email,
    UserRole? role,
    String? fotoUrl,
    String? nomorWa,
    String? alamat,
    GeoPoint? koordinat,
    int? poin,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      role: role ?? this.role,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      nomorWa: nomorWa ?? this.nomorWa,
      alamat: alamat ?? this.alamat,
      koordinat: koordinat ?? this.koordinat,
      poin: poin ?? this.poin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
