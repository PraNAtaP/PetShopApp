import 'package:flutter/material.dart';
import 'package:petshopapp/core/theme/app_colors.dart';

class PointsScreen extends StatelessWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Poin Saya'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Green Card
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFD4EED7), // Light green background
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'TOTAL POIN',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '2.500 Poin',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppColors.textDark),
                        const SizedBox(width: 8),
                        const Text(
                          'Poin dapat digunakan saat Checkout',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Expiry and Tier
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Poin Akan Berakhir', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                        const SizedBox(height: 4),
                        const Text('31 Des 2024', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tier Membership', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                          const SizedBox(height: 4),
                          const Text('Gold Member', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Riwayat Transaksi section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Transaksi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Filter'),
                  ),
                ],
              ),
            ),

            // History List
            _buildHistoryItem(
              icon: Icons.shopping_bag_outlined,
              iconColor: Colors.green,
              title: 'Pembelian #ORD-001',
              subtitle: '12 Okt 2023 • 14:20',
              points: '+50 poin',
              pointsColor: Colors.green,
            ),
            _buildHistoryItem(
              icon: Icons.local_activity_outlined,
              iconColor: AppColors.error,
              title: 'Penukaran Voucher',
              subtitle: '10 Okt 2023 • 09:15',
              points: '-30 poin',
              pointsColor: AppColors.error,
            ),
            _buildHistoryItem(
              icon: Icons.rate_review_outlined,
              iconColor: Colors.green,
              title: 'Ulasan Produk',
              subtitle: '05 Okt 2023 • 18:45',
              points: '+10 poin',
              pointsColor: Colors.green,
            ),
            _buildHistoryItem(
              icon: Icons.cake_outlined,
              iconColor: Colors.green,
              title: 'Bonus Ulang Tahun Anabul',
              subtitle: '01 Okt 2023 • 00:01',
              points: '+100 poin',
              pointsColor: Colors.green,
            ),

            const SizedBox(height: 32),

            // Banner Bottom
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.card_giftcard, color: AppColors.primary, size: 32),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Makin Sering Belanja, Makin Banyak Untungnya!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kumpulkan poin dari setiap transaksi dan tukarkan dengan diskon eksklusif untuk kebutuhan si anabul kesayangan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textLight, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100), // padding for bottom button
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: () {},
          child: const Text('Tukarkan Poin'),
        ),
      ),
    );
  }

  Widget _buildHistoryItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String points,
    required Color pointsColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textLight, fontSize: 12),
      ),
      trailing: Text(
        points,
        style: TextStyle(
          color: pointsColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
