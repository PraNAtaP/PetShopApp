import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'package:petshopapp/models/product_model.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'add_product_dialog.dart';

class ManagementScreen extends StatelessWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk (Inventory)'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddProductDialog(),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: FirestoreService.instance.getProductsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(child: Text('Belum ada produk di inventory.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: DataTable(
                headingRowColor: WidgetStateProperty.resolveWith((states) => AppColors.primary.withValues(alpha: 0.1)),
                columns: const [
                  DataColumn(label: Text('Foto', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Nama Produk', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Harga', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Stok', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: products.map((product) {
                  final isLowStock = product.stok < 5;
                  
                  return DataRow(
                    cells: [
                      DataCell(
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: product.fotoUrl.isNotEmpty
                                ? Image.network(product.fotoUrl, width: 50, height: 50, fit: BoxFit.cover)
                                : Container(width: 50, height: 50, color: Colors.grey, child: const Icon(Icons.image, color: Colors.white)),
                          ),
                        ),
                      ),
                      DataCell(Text(product.namaProduk)),
                      DataCell(
                        Chip(
                          label: Text(product.kategori, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                      DataCell(Text(currencyFormatter.format(product.harga))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isLowStock ? AppColors.error.withValues(alpha: 0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.stok.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isLowStock ? AppColors.error : AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AddProductDialog(productToEdit: product),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Hapus Produk?'),
                                    content: Text('Yakin ingin menghapus ${product.namaProduk}?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                                      TextButton(
                                        onPressed: () {
                                          FirestoreService.instance.deleteProduct(product.productId);
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
