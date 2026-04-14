import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/product_model.dart';
import '../../services/firestore_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _selectedCategory = 'Semua';
  final List<String> _categories = ['Semua', 'Makanan', 'Aksesoris', 'Obat', 'Lainnya'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Pet Shop'),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _buildProductList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      color: AppColors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                }
              },
              backgroundColor: AppColors.cardBackground,
              selectedColor: AppColors.primary,
              checkmarkColor: AppColors.white,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.white : AppColors.textDark,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<List<ProductModel>>(
      stream: FirestoreService.instance.getProductsStream(category: _selectedCategory),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error.toString(),
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          );
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textLight.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text(
                  'Produk tidak ditemukan',
                  style: TextStyle(color: AppColors.textLight, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final product = products[index];

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 100,
                      color: AppColors.background.withValues(alpha: 0.3),
                      child: product.fotoUrl.isNotEmpty
                          ? Image.network(
                              product.fotoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: AppColors.textLight),
                            )
                          : const Icon(Icons.shopping_bag, color: AppColors.primary, size: 40),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.namaProduk,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textDark,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Rp ${product.harga.toInt()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Stok: ${product.stok}',
                              style: TextStyle(
                                fontSize: 12,
                                color: product.stok > 0 ? AppColors.textLight : AppColors.error,
                              ),
                            ),
                            const Spacer(),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: product.stok > 0 ? () {} : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  minimumSize: const Size(80, 36),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Beli'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
