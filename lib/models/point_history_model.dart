import 'package:cloud_firestore/cloud_firestore.dart';

enum PointType {
  earn,
  redeem;

  String get value {
    switch (this) {
      case PointType.earn:
        return 'earn';
      case PointType.redeem:
        return 'redeem';
    }
  }

  static PointType fromString(String value) {
    switch (value) {
      case 'redeem':
        return PointType.redeem;
      default:
        return PointType.earn;
    }
  }
}

class PointHistoryModel {
  final String id;
  final String uid;
  final int poin;
  final PointType type;
  final String keterangan;
  final String? orderId;
  final DateTime? createdAt;

  const PointHistoryModel({
    required this.id,
    required this.uid,
    required this.poin,
    required this.type,
    required this.keterangan,
    this.orderId,
    this.createdAt,
  });

  bool get isEarn => poin > 0;

  factory PointHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PointHistoryModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      poin: data['poin'] ?? 0,
      type: PointType.fromString(data['type'] ?? 'earn'),
      keterangan: data['keterangan'] ?? '',
      orderId: data['order_id'] as String?,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'poin': poin,
      'type': type.value,
      'keterangan': keterangan,
      if (orderId != null) 'order_id': orderId,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  PointHistoryModel copyWith({
    String? id,
    String? uid,
    int? poin,
    PointType? type,
    String? keterangan,
    String? orderId,
    DateTime? createdAt,
  }) {
    return PointHistoryModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      poin: poin ?? this.poin,
      type: type ?? this.type,
      keterangan: keterangan ?? this.keterangan,
      orderId: orderId ?? this.orderId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}