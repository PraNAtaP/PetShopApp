import 'package:cloud_firestore/cloud_firestore.dart';

class UserAddressModel {
  final String id;
  final String label;
  final String fullAddress;
  final double? latitude;
  final double? longitude;
  final bool isPrimary;
  final DateTime? createdAt;

  const UserAddressModel({
    required this.id,
    required this.label,
    required this.fullAddress,
    this.latitude,
    this.longitude,
    this.isPrimary = false,
    this.createdAt,
  });

  factory UserAddressModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserAddressModel(
      id: doc.id,
      label: data['label'] ?? 'Rumah',
      fullAddress: data['full_address'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      isPrimary: data['is_primary'] ?? false,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'full_address': fullAddress,
      'latitude': latitude,
      'longitude': longitude,
      'is_primary': isPrimary,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  UserAddressModel copyWith({
    String? id,
    String? label,
    String? fullAddress,
    double? latitude,
    double? longitude,
    bool? isPrimary,
    DateTime? createdAt,
  }) {
    return UserAddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      fullAddress: fullAddress ?? this.fullAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
