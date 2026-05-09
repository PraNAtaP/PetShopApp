import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/services/auth_service.dart';

class PointsScreen extends StatelessWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
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
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFD4EED7),
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
                  Text(
                    '${user.poin} Poin',
                    style: const TextStyle(
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, size: 16, color: AppColors.textDark),
                        SizedBox(width: 8),
                        Text(
                          'Poin dapat digunakan saat Checkout',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tier Membership',
                            style: TextStyle(color: AppColors.textLight, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getTier(user.poin),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey.shade300),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Nilai Tukar',
                              style: TextStyle(color: AppColors.textLight, fontSize: 12),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '1.000 poin = Rp5.000',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Riwayat Poin',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.history, size: 48, color: Color(0xFFE0E0E0)),
                    SizedBox(height: 12),
                    Text(
                      'Belum ada riwayat poin',
                      style: TextStyle(color: AppColors.textLight),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Lakukan transaksi untuk mendapatkan poin!',
                      style: TextStyle(color: AppColors.textLight, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

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
                      child: const Icon(Icons.card_giftcard,
                          color: AppColors.primary, size: 32),
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
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        color: Colors.white,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.redeem),
          label: const Text('Tukarkan Poin'),
        ),
      ),
    );
  }

  String _getTier(int poin) {
    if (poin >= 10000) return '💎 Platinum Member';
    if (poin >= 5000) return '🥇 Gold Member';
    if (poin >= 1000) return '🥈 Silver Member';
    return '🥉 Bronze Member';
  }
}