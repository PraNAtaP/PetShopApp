import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a product available for purchase in the shop.
class ProductModel {
  final String productId;
  final String namaProduk;
  final String kategori;
  final double harga;
  final int stok;
  final String deskripsi;
  final String fotoUrl;
  final int terjual;

  /// Creates a new [ProductModel] instance.
  const ProductModel({
    required this.productId,
    required this.namaProduk,
    required this.kategori,
    required this.harga,
    required this.stok,
    required this.deskripsi,
    required this.fotoUrl,
    this.terjual = 0,
  });

  /// Factory constructor to map Firestore [DocumentSnapshot] to [ProductModel].
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      productId: doc.id,
      namaProduk: data['nama_produk'] ?? '',
      kategori: data['kategori'] ?? '',
      harga: (data['harga'] ?? 0).toDouble(),
      stok: data['stok'] ?? 0,
      deskripsi: data['deskripsi'] ?? '',
      fotoUrl: data['foto_url'] ?? '',
      terjual: data['terjual'] ?? 0,
    );
  }

  /// Converts the [ProductModel] instance into a Map.
  Map<String, dynamic> toMap() {
    return {
      'nama_produk': namaProduk,
      'kategori': kategori,
      'harga': harga,
      'stok': stok,
      'deskripsi': deskripsi,
      'foto_url': fotoUrl,
      'terjual': terjual,
    };
  }

  /// Creates a copy of this [ProductModel] maintaining immutability.
  ProductModel copyWith({
    String? productId,
    String? namaProduk,
    String? kategori,
    double? harga,
    int? stok,
    String? deskripsi,
    String? fotoUrl,
    int? terjual,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      namaProduk: namaProduk ?? this.namaProduk,
      kategori: kategori ?? this.kategori,
      harga: harga ?? this.harga,
      stok: stok ?? this.stok,
      deskripsi: deskripsi ?? this.deskripsi,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      terjual: terjual ?? this.terjual,
    );
  }
}
