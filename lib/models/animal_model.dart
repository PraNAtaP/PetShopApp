import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an animal available for adoption in the Pet Point application.
class AnimalModel {
  final String id;
  final String name;
  final String type;
  final String gender;
  final String breed;
  final String age;
  final double? weight;
  final String description;
  final String status;
  final String? bookedBy;
  final String imageUrl;
  final DateTime? createdAt;

  const AnimalModel({
    required this.id,
    required this.name,
    required this.type,
    required this.gender,
    required this.breed,
    required this.age,
    this.weight,
    required this.description,
    required this.status,
    this.bookedBy,
    required this.imageUrl,
    this.createdAt,
  });

  /// Factory constructor to map Firestore data to [AnimalModel].
  factory AnimalModel.fromMap(Map<String, dynamic> data, String documentId) {
    return AnimalModel(
      id: documentId,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      gender: data['gender'] ?? '',
      breed: data['breed'] ?? '',
      age: data['age'] ?? '',
      weight: data['weight']?.toDouble(),
      description: data['description'] ?? '',
      status: data['status'] ?? 'available',
      bookedBy: data['bookedBy'],
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts the [AnimalModel] instance into a Map.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'type': type,
      'gender': gender,
      'breed': breed,
      'age': age,
      'weight': weight,
      'description': description,
      'status': status,
      'imageUrl': imageUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
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
    String? gender,
    String? breed,
    String? age,
    double? weight,
    String? description,
    String? status,
    String? bookedBy,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return AnimalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      gender: gender ?? this.gender,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      description: description ?? this.description,
      status: status ?? this.status,
      bookedBy: bookedBy ?? this.bookedBy,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
