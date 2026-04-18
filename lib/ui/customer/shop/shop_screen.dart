import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/product_model.dart';
import 'package:petshopapp/services/firestore_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _selectedCategory = 'Semua';
  final List<String> _categories = ['Semua', 'Makanan', 'Aksesoris', 'Obat'];
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Pet Shop', style: TextStyle(color: AppColors.white)),
            backgroundColor: AppColors.primary,
            pinned: true,
            floating: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari produk...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildFilterBar(),
          ),
          StreamBuilder<List<ProductModel>>(
            stream: FirestoreService.instance.getProductsStream(category: _selectedCategory),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.error)),
                  ),
                );
              }

              final products = snapshot.data ?? [];

              if (products.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
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
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = products[index];
                      final isOutOfStock = product.stok <= 0;

                      return Card(
                        elevation: 4,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  product.fotoUrl.isNotEmpty
                                      ? Image.network(
                                          product.fotoUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.broken_image, color: AppColors.textLight),
                                        )
                                      : Container(
                                          color: AppColors.background,
                                          child: const Icon(Icons.shopping_bag, color: AppColors.primary, size: 40),
                                        ),
                                  if (isOutOfStock)
                                    Container(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      alignment: Alignment.center,
                                    ),
                                  if (isOutOfStock)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.error,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Stok Habis',
                                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      product.namaProduk,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      currencyFormatter.format(product.harga),
                                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accent, fontSize: 14),
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 32,
                                      child: ElevatedButton(
                                        onPressed: isOutOfStock ? null : () {},
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: Text(isOutOfStock ? 'Habis' : 'Beli', style: const TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: products.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      color: Colors.transparent,
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
              backgroundColor: AppColors.white,
              selectedColor: AppColors.primary,
              checkmarkColor: AppColors.white,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.white : AppColors.primary,
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
}
