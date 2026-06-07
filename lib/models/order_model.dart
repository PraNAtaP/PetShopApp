import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single product item within a customer's order.
class OrderItemModel {
  final String productId;
  final String nama;
  final int jumlah;
  final double hargaSatuan;

  const OrderItemModel({
    required this.productId,
    required this.nama,
    required this.jumlah,
    required this.hargaSatuan,
  });

  /// Maps a Firestore Map to [OrderItemModel].
  factory OrderItemModel.fromMap(Map<String, dynamic> data) {
    return OrderItemModel(
      productId: data['product_id'] ?? '',
      nama: data['nama'] ?? '',
      jumlah: data['jumlah'] ?? 0,
      hargaSatuan: (data['harga_satuan'] ?? 0).toDouble(),
    );
  }

  /// Converts the [OrderItemModel] to a Map.
  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'nama': nama,
      'jumlah': jumlah,
      'harga_satuan': hargaSatuan,
    };
  }
}

/// Represents a customer's order containing items and payment details.
class OrderModel {
  final String orderId;
  final String customerId;
  final List<OrderItemModel> items;
  final double totalHarga;
  final double diskonPoin;
  final String? buktiBayarUrl;
  final String statusBayar;
  final String statusPengiriman;
  final String metodePengambilan;
  final String metodePembayaran;
  final String? alamatLengkap;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final bool? cancelRequest;
  final String? cancelBankName;
  final String? cancelBankAccount;
  final String? cancelAccountHolder;

  /// Creates a new [OrderModel] instance.
  const OrderModel({
    required this.orderId,
    required this.customerId,
    required this.items,
    required this.totalHarga,
    this.diskonPoin = 0.0,
    this.buktiBayarUrl,
    required this.statusBayar,
    required this.statusPengiriman,
    required this.metodePengambilan,
    required this.metodePembayaran,
    this.alamatLengkap,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.cancelRequest,
    this.cancelBankName,
    this.cancelBankAccount,
    this.cancelAccountHolder,
  });

  /// Factory constructor to map Firestore [DocumentSnapshot] to [OrderModel].
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final itemsList = (data['items'] as List<dynamic>?) ?? [];
    final parsedItems = itemsList.map((i) => OrderItemModel.fromMap(i as Map<String, dynamic>)).toList();

    return OrderModel(
      orderId: doc.id,
      customerId: data['customer_id'] ?? '',
      items: parsedItems,
      totalHarga: (data['total_harga'] ?? 0).toDouble(),
      diskonPoin: (data['diskon_poin'] ?? 0).toDouble(),
      buktiBayarUrl: data['bukti_bayar_url'] as String?,
      statusBayar: data['status_bayar'] ?? '',
      statusPengiriman: data['status_pengiriman'] ?? '',
      metodePengambilan: data['metode_pengambilan'] ?? '',
      metodePembayaran: data['metode_pembayaran'] ?? '',
      alamatLengkap: data['alamat_lengkap'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      cancelRequest: data['cancel_request'] as bool?,
      cancelBankName: data['cancel_bank_name'] as String?,
      cancelBankAccount: data['cancel_bank_account'] as String?,
      cancelAccountHolder: data['cancel_account_holder'] as String?,
    );
  }

  /// Converts the [OrderModel] instance into a Map.
  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'items': items.map((i) => i.toMap()).toList(),
      'total_harga': totalHarga,
      'diskon_poin': diskonPoin,
      'bukti_bayar_url': buktiBayarUrl,
      'status_bayar': statusBayar,
      'status_pengiriman': statusPengiriman,
      'metode_pengambilan': metodePengambilan,
      'metode_pembayaran': metodePembayaran,
      if (alamatLengkap != null) 'alamat_lengkap': alamatLengkap,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'cancel_request': cancelRequest,
      'cancel_bank_name': cancelBankName,
      'cancel_bank_account': cancelBankAccount,
      'cancel_account_holder': cancelAccountHolder,
    };
  }

  /// Creates a copy of this [OrderModel] maintaining immutability.
  OrderModel copyWith({
    String? orderId,
    String? customerId,
    List<OrderItemModel>? items,
    double? totalHarga,
    double? diskonPoin,
    String? buktiBayarUrl,
    String? statusBayar,
    String? statusPengiriman,
    String? metodePengambilan,
    String? metodePembayaran,
    DateTime? createdAt,
    bool? cancelRequest,
    String? cancelBankName,
    String? cancelBankAccount,
    String? cancelAccountHolder,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      items: items ?? this.items,
      totalHarga: totalHarga ?? this.totalHarga,
      diskonPoin: diskonPoin ?? this.diskonPoin,
      buktiBayarUrl: buktiBayarUrl ?? this.buktiBayarUrl,
      statusBayar: statusBayar ?? this.statusBayar,
      statusPengiriman: statusPengiriman ?? this.statusPengiriman,
      metodePengambilan: metodePengambilan ?? this.metodePengambilan,
      metodePembayaran: metodePembayaran ?? this.metodePembayaran,
      createdAt: createdAt ?? this.createdAt,
      cancelRequest: cancelRequest ?? this.cancelRequest,
      cancelBankName: cancelBankName ?? this.cancelBankName,
      cancelBankAccount: cancelBankAccount ?? this.cancelBankAccount,
      cancelAccountHolder: cancelAccountHolder ?? this.cancelAccountHolder,
    );
  }
}
