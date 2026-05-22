import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/product_model.dart';
import 'package:petshopapp/services/firestore_service.dart';

class HomeProductSlider extends StatelessWidget {
  const HomeProductSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return StreamBuilder<List<ProductModel>>(
      stream: FirestoreService.instance.getProductsStream(category: 'Semua'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // Hide section if no data
        }

        // Limit to 5 products for the slider
        final products = snapshot.data!.take(5).toList();

        return SizedBox(
          height: 250, // Fixed height for horizontal list
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final isOutOfStock = product.stok <= 0;

              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 16, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () {
                    context.push('/product-detail', extra: product);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Section
                      Expanded(
                        flex: 3,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              child: Hero(
                                tag: 'home_product_${product.productId}',
                                child: product.fotoUrl.isNotEmpty
                                    ? Image.network(
                                        product.fotoUrl,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
                                      )
                                    : Container(
                                        color: Colors.grey.shade100,
                                        width: double.infinity,
                                        child: const Icon(Icons.pets, color: AppColors.primary, size: 40),
                                      ),
                              ),
                            ),
                            if (isOutOfStock)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(150),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Habis',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Details Section
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                product.namaProduk,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.textDark,
                                  height: 1.2,
                                ),
                              ),
                              Text(
                                currencyFormatter.format(product.harga),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
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
          ),
        );
      },
    );
  }
}
