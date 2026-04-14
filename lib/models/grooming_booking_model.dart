import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a customer's requested grooming booking.
class GroomingBookingModel {
  final String bookingId;
  final String customerId;
  final String namaHewan;
  final String paketGrooming;
  final bool isHomeService;
  final String? alamatLengkap;
  final GeoPoint? koordinat;
  final DateTime? tanggalBooking;
  final String status;
  final double totalBiaya;

  /// Creates a new [GroomingBookingModel] instance.
  const GroomingBookingModel({
    required this.bookingId,
    required this.customerId,
    required this.namaHewan,
    required this.paketGrooming,
    required this.isHomeService,
    this.alamatLengkap,
    this.koordinat,
    this.tanggalBooking,
    required this.status,
    required this.totalBiaya,
  });

  /// Factory constructor to map Firestore [DocumentSnapshot] to [GroomingBookingModel].
  factory GroomingBookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroomingBookingModel(
      bookingId: doc.id,
      customerId: data['customer_id'] ?? '',
      namaHewan: data['nama_hewan'] ?? '',
      paketGrooming: data['paket_grooming'] ?? '',
      isHomeService: data['is_home_service'] ?? false,
      alamatLengkap: data['alamat_lengkap'] as String?,
      koordinat: data['koordinat'] as GeoPoint?,
      tanggalBooking: (data['tanggal_booking'] as Timestamp?)?.toDate(),
      status: data['status'] ?? '',
      totalBiaya: (data['total_biaya'] ?? 0).toDouble(),
    );
  }

  /// Converts the [GroomingBookingModel] instance into a Map.
  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'nama_hewan': namaHewan,
      'paket_grooming': paketGrooming,
      'is_home_service': isHomeService,
      'alamat_lengkap': alamatLengkap,
      'koordinat': koordinat,
      'tanggal_booking': tanggalBooking != null ? Timestamp.fromDate(tanggalBooking!) : null,
      'status': status,
      'total_biaya': totalBiaya,
    };
  }

  /// Creates a copy of this [GroomingBookingModel] maintaining immutability.
  GroomingBookingModel copyWith({
    String? bookingId,
    String? customerId,
    String? namaHewan,
    String? paketGrooming,
    bool? isHomeService,
    String? alamatLengkap,
    GeoPoint? koordinat,
    DateTime? tanggalBooking,
    String? status,
    double? totalBiaya,
  }) {
    return GroomingBookingModel(
      bookingId: bookingId ?? this.bookingId,
      customerId: customerId ?? this.customerId,
      namaHewan: namaHewan ?? this.namaHewan,
      paketGrooming: paketGrooming ?? this.paketGrooming,
      isHomeService: isHomeService ?? this.isHomeService,
      alamatLengkap: alamatLengkap ?? this.alamatLengkap,
      koordinat: koordinat ?? this.koordinat,
      tanggalBooking: tanggalBooking ?? this.tanggalBooking,
      status: status ?? this.status,
      totalBiaya: totalBiaya ?? this.totalBiaya,
    );
  }
}
