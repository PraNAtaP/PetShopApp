import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an adoption request or application.
class AdoptionModel {
  final String adoptionId;
  final String petId;
  final String petName;
  final String customerId;
  final String customerName;
  final DateTime? tanggalJanjiTemu;
  final String jamJanjiTemu;
  final String status;
  final String? catatanAdmin;
  final DateTime? createdAt;

  /// Creates a new [AdoptionModel] instance.
  const AdoptionModel({
    required this.adoptionId,
    required this.petId,
    required this.petName,
    required this.customerId,
    required this.customerName,
    this.tanggalJanjiTemu,
    required this.jamJanjiTemu,
    required this.status,
    this.catatanAdmin,
    this.createdAt,
  });

  /// Factory constructor to map Firestore [DocumentSnapshot] to [AdoptionModel].
  factory AdoptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdoptionModel(
      adoptionId: doc.id,
      petId: data['pet_id'] ?? '',
      petName: data['pet_name'] ?? '',
      customerId: data['customer_id'] ?? '',
      customerName: data['customer_name'] ?? '',
      tanggalJanjiTemu: (data['tanggal_janji_temu'] as Timestamp?)?.toDate(),
      jamJanjiTemu: data['jam_janji_temu'] ?? '',
      status: data['status'] ?? '',
      catatanAdmin: data['catatan_admin'] as String?,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts the [AdoptionModel] instance into a Map.
  Map<String, dynamic> toMap() {
    return {
      'pet_id': petId,
      'pet_name': petName,
      'customer_id': customerId,
      'customer_name': customerName,
      'tanggal_janji_temu': tanggalJanjiTemu != null ? Timestamp.fromDate(tanggalJanjiTemu!) : null,
      'jam_janji_temu': jamJanjiTemu,
      'status': status,
      'catatan_admin': catatanAdmin,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  /// Creates a copy of this [AdoptionModel] keeping immutability.
  AdoptionModel copyWith({
    String? adoptionId,
    String? petId,
    String? petName,
    String? customerId,
    String? customerName,
    DateTime? tanggalJanjiTemu,
    String? jamJanjiTemu,
    String? status,
    String? catatanAdmin,
    DateTime? createdAt,
  }) {
    return AdoptionModel(
      adoptionId: adoptionId ?? this.adoptionId,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      tanggalJanjiTemu: tanggalJanjiTemu ?? this.tanggalJanjiTemu,
      jamJanjiTemu: jamJanjiTemu ?? this.jamJanjiTemu,
      status: status ?? this.status,
      catatanAdmin: catatanAdmin ?? this.catatanAdmin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
