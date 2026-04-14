import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a pet entity in the Pet Point application.
class PetModel {
  final String petId;
  final String namaHewan;
  final String jenis;
  final String ras;
  final String umur;
  final String gender;
  final String deskripsi;
  final List<String> fotoUrls;
  final String status;
  final DateTime? createdAt;

  /// Creates a new [PetModel] instance.
  const PetModel({
    required this.petId,
    required this.namaHewan,
    required this.jenis,
    required this.ras,
    required this.umur,
    required this.gender,
    required this.deskripsi,
    required this.fotoUrls,
    required this.status,
    this.createdAt,
  });

  /// Factory constructor to map Firestore [DocumentSnapshot] to [PetModel].
  factory PetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PetModel(
      petId: doc.id,
      namaHewan: data['nama_hewan'] ?? '',
      jenis: data['jenis'] ?? '',
      ras: data['ras'] ?? '',
      umur: data['umur'] ?? '',
      gender: data['gender'] ?? '',
      deskripsi: data['deskripsi'] ?? '',
      fotoUrls: List<String>.from(data['foto_urls'] ?? []),
      status: data['status'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts the [PetModel] instance into a Map.
  Map<String, dynamic> toMap() {
    return {
      'nama_hewan': namaHewan,
      'jenis': jenis,
      'ras': ras,
      'umur': umur,
      'gender': gender,
      'deskripsi': deskripsi,
      'foto_urls': fotoUrls,
      'status': status,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  /// Creates a copy of this [PetModel] replacing given fields with new values.
  PetModel copyWith({
    String? petId,
    String? namaHewan,
    String? jenis,
    String? ras,
    String? umur,
    String? gender,
    String? deskripsi,
    List<String>? fotoUrls,
    String? status,
    DateTime? createdAt,
  }) {
    return PetModel(
      petId: petId ?? this.petId,
      namaHewan: namaHewan ?? this.namaHewan,
      jenis: jenis ?? this.jenis,
      ras: ras ?? this.ras,
      umur: umur ?? this.umur,
      gender: gender ?? this.gender,
      deskripsi: deskripsi ?? this.deskripsi,
      fotoUrls: fotoUrls ?? this.fotoUrls,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
