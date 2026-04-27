import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a customer's requested grooming booking.
class GroomingBookingModel {
  final String bookingId;
  final String userId;
  final String customerName;
  final String petName;
  final String petType; // Anjing/Kucing
  final String serviceType;
  final DateTime bookingDate;
  final String timeSlot;
  final double totalPrice;
  final bool isHomeService;
  final String? alamatLengkap;
  final double? latitude;
  final double? longitude;
  final String status; // Pending/Confirmed/Completed/Cancelled
  final DateTime createdAt;

  const GroomingBookingModel({
    required this.bookingId,
    required this.userId,
    required this.customerName,
    required this.petName,
    required this.petType,
    required this.serviceType,
    required this.bookingDate,
    required this.timeSlot,
    required this.totalPrice,
    required this.isHomeService,
    this.alamatLengkap,
    this.latitude,
    this.longitude,
    required this.status,
    required this.createdAt,
  });

  /// Factory constructor to map Firestore [DocumentSnapshot] to [GroomingBookingModel].
  factory GroomingBookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroomingBookingModel(
      bookingId: doc.id,
      userId: data['userId'] ?? '',
      customerName: data['customerName'] ?? '',
      petName: data['petName'] ?? '',
      petType: data['petType'] ?? '',
      serviceType: data['serviceType'] ?? '',
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      timeSlot: data['timeSlot'] ?? '',
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      isHomeService: data['isHomeService'] ?? false,
      alamatLengkap: data['alamatLengkap'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      status: data['status'] ?? 'Pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Converts the [GroomingBookingModel] instance into a Map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'customerName': customerName,
      'petName': petName,
      'petType': petType,
      'serviceType': serviceType,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'timeSlot': timeSlot,
      'totalPrice': totalPrice,
      'isHomeService': isHomeService,
      if (alamatLengkap != null) 'alamatLengkap': alamatLengkap,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a copy of this [GroomingBookingModel] maintaining immutability.
  GroomingBookingModel copyWith({
    String? bookingId,
    String? userId,
    String? customerName,
    String? petName,
    String? petType,
    String? serviceType,
    DateTime? bookingDate,
    String? timeSlot,
    double? totalPrice,
    bool? isHomeService,
    String? alamatLengkap,
    double? latitude,
    double? longitude,
    String? status,
    DateTime? createdAt,
  }) {
    return GroomingBookingModel(
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      petName: petName ?? this.petName,
      petType: petType ?? this.petType,
      serviceType: serviceType ?? this.serviceType,
      bookingDate: bookingDate ?? this.bookingDate,
      timeSlot: timeSlot ?? this.timeSlot,
      totalPrice: totalPrice ?? this.totalPrice,
      isHomeService: isHomeService ?? this.isHomeService,
      alamatLengkap: alamatLengkap ?? this.alamatLengkap,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
