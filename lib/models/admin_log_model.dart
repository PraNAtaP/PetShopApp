import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a log of an administrative action in the system.
class AdminLogModel {
  final String id;
  final String adminName;
  final String actionType; // 'produk', 'chat', 'grooming', 'adopsi', etc.
  final String description;
  final DateTime timestamp;

  const AdminLogModel({
    required this.id,
    required this.adminName,
    required this.actionType,
    required this.description,
    required this.timestamp,
  });

  /// Converts the [AdminLogModel] instance into a Map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'adminName': adminName,
      'actionType': actionType,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  /// Factory constructor to create an [AdminLogModel] from a Map and document ID.
  factory AdminLogModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AdminLogModel(
      id: documentId,
      adminName: map['adminName'] ?? '',
      actionType: map['actionType'] ?? '',
      description: map['description'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Factory constructor to map Firestore [DocumentSnapshot] to [AdminLogModel].
  factory AdminLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AdminLogModel.fromMap(data, doc.id);
  }

  /// Creates a copy of this [AdminLogModel] maintaining immutability.
  AdminLogModel copyWith({
    String? id,
    String? adminName,
    String? actionType,
    String? description,
    DateTime? timestamp,
  }) {
    return AdminLogModel(
      id: id ?? this.id,
      adminName: adminName ?? this.adminName,
      actionType: actionType ?? this.actionType,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
