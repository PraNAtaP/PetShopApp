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
  final String? buktiBayarUrl;
  final String statusBayar;
  final String statusPengiriman;
  final String metodePengambilan;
  final DateTime? createdAt;

  /// Creates a new [OrderModel] instance.
  const OrderModel({
    required this.orderId,
    required this.customerId,
    required this.items,
    required this.totalHarga,
    this.buktiBayarUrl,
    required this.statusBayar,
    required this.statusPengiriman,
    required this.metodePengambilan,
    this.createdAt,
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
      buktiBayarUrl: data['bukti_bayar_url'] as String?,
      statusBayar: data['status_bayar'] ?? '',
      statusPengiriman: data['status_pengiriman'] ?? '',
      metodePengambilan: data['metode_pengambilan'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts the [OrderModel] instance into a Map.
  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'items': items.map((i) => i.toMap()).toList(),
      'total_harga': totalHarga,
      'bukti_bayar_url': buktiBayarUrl,
      'status_bayar': statusBayar,
      'status_pengiriman': statusPengiriman,
      'metode_pengambilan': metodePengambilan,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  /// Creates a copy of this [OrderModel] maintaining immutability.
  OrderModel copyWith({
    String? orderId,
    String? customerId,
    List<OrderItemModel>? items,
    double? totalHarga,
    String? buktiBayarUrl,
    String? statusBayar,
    String? statusPengiriman,
    String? metodePengambilan,
    DateTime? createdAt,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      items: items ?? this.items,
      totalHarga: totalHarga ?? this.totalHarga,
      buktiBayarUrl: buktiBayarUrl ?? this.buktiBayarUrl,
      statusBayar: statusBayar ?? this.statusBayar,
      statusPengiriman: statusPengiriman ?? this.statusPengiriman,
      metodePengambilan: metodePengambilan ?? this.metodePengambilan,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
