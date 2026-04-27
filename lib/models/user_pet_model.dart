import 'package:cloud_firestore/cloud_firestore.dart';

class UserPetModel {
  final String? id;
  final String userId;
  final String name;
  final String type; // Kucing / Anjing
  final String gender; // Jantan / Betina
  final String breed; // Jenis Ras
  final String age; // Usia
  final double? weight; // Berat Badan (Opsional)
  final String? imageUrl; // Foto Hewan (Opsional)
  final DateTime? createdAt;

  const UserPetModel({
    this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.gender,
    required this.breed,
    required this.age,
    this.weight,
    this.imageUrl,
    this.createdAt,
  });

  factory UserPetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserPetModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      gender: data['gender'] ?? '',
      breed: data['breed'] ?? '',
      age: data['age'] ?? '',
      weight: data['weight']?.toDouble(),
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'type': type,
      'gender': gender,
      'breed': breed,
      'age': age,
      'weight': weight,
      'imageUrl': imageUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  UserPetModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    String? gender,
    String? breed,
    String? age,
    double? weight,
    DateTime? createdAt,
  }) {
    return UserPetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      gender: gender ?? this.gender,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
