import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an animal available for adoption in the Pet Point application.
class AnimalModel {
  final String id;
  final String name;
  final String type;
  final String status;
  final String? bookedBy;
  final String imageUrl;

  const AnimalModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.bookedBy,
    required this.imageUrl,
  });

  /// Factory constructor to map Firestore data to [AnimalModel].
  factory AnimalModel.fromMap(Map<String, dynamic> data, String documentId) {
    return AnimalModel(
      id: documentId,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      status: data['status'] ?? 'available',
      bookedBy: data['bookedBy'],
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  /// Converts the [AnimalModel] instance into a Map.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'type': type,
      'status': status,
      'imageUrl': imageUrl,
    };
    if (bookedBy != null) {
      map['bookedBy'] = bookedBy;
    }
    return map;
  }

  /// Creates a copy of this [AnimalModel] replacing given fields with new values.
  AnimalModel copyWith({
    String? id,
    String? name,
    String? type,
    String? status,
    String? bookedBy,
    String? imageUrl,
  }) {
    return AnimalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      bookedBy: bookedBy ?? this.bookedBy,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
