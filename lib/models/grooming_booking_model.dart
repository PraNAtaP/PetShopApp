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
  final int durationMinutes;
  final double totalPrice;
  final bool isHomeService;
  final String? alamatLengkap;
  final double? latitude;
  final double? longitude;
  final String status; // Pending/Confirmed/Completed/Cancelled
  final String? buktiBayarUrl;
  final String metodePembayaran;
  final DateTime createdAt;
  final bool? cancelRequest;
  final String? cancelBankName;
  final String? cancelBankAccount;
  final String? cancelAccountHolder;

  const GroomingBookingModel({
    required this.bookingId,
    required this.userId,
    required this.customerName,
    required this.petName,
    required this.petType,
    required this.serviceType,
    required this.bookingDate,
    required this.timeSlot,
    required this.durationMinutes,
    required this.totalPrice,
    required this.isHomeService,
    this.alamatLengkap,
    this.latitude,
    this.longitude,
    required this.status,
    this.buktiBayarUrl,
    required this.metodePembayaran,
    required this.createdAt,
    this.cancelRequest,
    this.cancelBankName,
    this.cancelBankAccount,
    this.cancelAccountHolder,
  });

  /// Factory constructor to map Firestore [DocumentSnapshot] to [GroomingBookingModel].
  factory GroomingBookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Safety check for critical timestamp fields
    DateTime safeDate(dynamic field) {
      if (field is Timestamp) return field.toDate();
      return DateTime.now();
    }

    return GroomingBookingModel(
      bookingId: doc.id,
      userId: data['userId']?.toString() ?? '',
      customerName: data['customerName']?.toString() ?? '',
      petName: data['petName']?.toString() ?? '',
      petType: data['petType']?.toString() ?? '',
      serviceType: data['serviceType']?.toString() ?? '',
      bookingDate: safeDate(data['bookingDate']),
      timeSlot: data['timeSlot']?.toString() ?? '',
      durationMinutes: data['durationMinutes'] as int? ?? 0,
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      isHomeService: data['isHomeService'] ?? false,
      alamatLengkap: data['alamatLengkap']?.toString(),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      status: data['status']?.toString() ?? 'Pending',
      buktiBayarUrl: data['buktiBayarUrl']?.toString(),
      metodePembayaran: data['metodePembayaran']?.toString() ?? 'Transfer',
      createdAt: safeDate(data['createdAt']),
      cancelRequest: data['cancel_request'] as bool?,
      cancelBankName: data['cancel_bank_name'] as String?,
      cancelBankAccount: data['cancel_bank_account'] as String?,
      cancelAccountHolder: data['cancel_account_holder'] as String?,
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
      'durationMinutes': durationMinutes,
      'totalPrice': totalPrice,
      'isHomeService': isHomeService,
      if (alamatLengkap != null) 'alamatLengkap': alamatLengkap,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'status': status,
      if (buktiBayarUrl != null) 'buktiBayarUrl': buktiBayarUrl,
      'metodePembayaran': metodePembayaran,
      'createdAt': Timestamp.fromDate(createdAt),
      'cancel_request': cancelRequest,
      'cancel_bank_name': cancelBankName,
      'cancel_bank_account': cancelBankAccount,
      'cancel_account_holder': cancelAccountHolder,
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
    int? durationMinutes,
    double? totalPrice,
    bool? isHomeService,
    String? alamatLengkap,
    double? latitude,
    double? longitude,
    String? status,
    String? buktiBayarUrl,
    String? metodePembayaran,
    DateTime? createdAt,
    bool? cancelRequest,
    String? cancelBankName,
    String? cancelBankAccount,
    String? cancelAccountHolder,
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
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalPrice: totalPrice ?? this.totalPrice,
      isHomeService: isHomeService ?? this.isHomeService,
      alamatLengkap: alamatLengkap ?? this.alamatLengkap,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      buktiBayarUrl: buktiBayarUrl ?? this.buktiBayarUrl,
      metodePembayaran: metodePembayaran ?? this.metodePembayaran,
      createdAt: createdAt ?? this.createdAt,
      cancelRequest: cancelRequest ?? this.cancelRequest,
      cancelBankName: cancelBankName ?? this.cancelBankName,
      cancelBankAccount: cancelBankAccount ?? this.cancelBankAccount,
      cancelAccountHolder: cancelAccountHolder ?? this.cancelAccountHolder,
    );
  }
}
