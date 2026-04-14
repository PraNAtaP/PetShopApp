import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a Fun Fact or Tip in the application.
class FunFactModel {
  final String factId;
  final String judul;
  final String konten;
  final String fotoUrl;
  final String kategori;
  final DateTime? createdAt;

  /// Creates a new [FunFactModel] instance.
  const FunFactModel({
    required this.factId,
    required this.judul,
    required this.konten,
    required this.fotoUrl,
    required this.kategori,
    this.createdAt,
  });

  /// Factory constructor to map Firestore [DocumentSnapshot] to [FunFactModel].
  factory FunFactModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FunFactModel(
      factId: doc.id,
      judul: data['judul'] ?? '',
      konten: data['konten'] ?? '',
      fotoUrl: data['foto_url'] ?? '',
      kategori: data['kategori'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts the [FunFactModel] instance into a Map.
  Map<String, dynamic> toMap() {
    return {
      'judul': judul,
      'konten': konten,
      'foto_url': fotoUrl,
      'kategori': kategori,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  /// Creates a copy of this [FunFactModel] maintaining immutability.
  FunFactModel copyWith({
    String? factId,
    String? judul,
    String? konten,
    String? fotoUrl,
    String? kategori,
    DateTime? createdAt,
  }) {
    return FunFactModel(
      factId: factId ?? this.factId,
      judul: judul ?? this.judul,
      konten: konten ?? this.konten,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      kategori: kategori ?? this.kategori,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
