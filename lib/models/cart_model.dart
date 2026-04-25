import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an item in the user's persistent shopping cart.
class CartModel {
  final String cartId;
  final String customerId;
  final String productId;
  final String nama;
  final double hargaSatuan;
  final int jumlah;
  final String fotoUrl;
  final DateTime? createdAt;

  const CartModel({
    required this.cartId,
    required this.customerId,
    required this.productId,
    required this.nama,
    required this.hargaSatuan,
    required this.jumlah,
    required this.fotoUrl,
    this.createdAt,
  });

  /// Factory constructor to map Firestore [DocumentSnapshot] to [CartModel].
  factory CartModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CartModel(
      cartId: doc.id,
      customerId: data['customer_id'] ?? '',
      productId: data['product_id'] ?? '',
      nama: data['nama'] ?? '',
      hargaSatuan: (data['harga_satuan'] ?? 0).toDouble(),
      jumlah: data['jumlah'] ?? 0,
      fotoUrl: data['foto_url'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts the [CartModel] instance into a Map.
  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'product_id': productId,
      'nama': nama,
      'harga_satuan': hargaSatuan,
      'jumlah': jumlah,
      'foto_url': fotoUrl,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  /// Creates a copy of this [CartModel] maintaining immutability.
  CartModel copyWith({
    String? cartId,
    String? customerId,
    String? productId,
    String? nama,
    double? hargaSatuan,
    int? jumlah,
    String? fotoUrl,
    DateTime? createdAt,
  }) {
    return CartModel(
      cartId: cartId ?? this.cartId,
      customerId: customerId ?? this.customerId,
      productId: productId ?? this.productId,
      nama: nama ?? this.nama,
      hargaSatuan: hargaSatuan ?? this.hargaSatuan,
      jumlah: jumlah ?? this.jumlah,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
