import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/services/auth_service.dart';
import 'package:petshopapp/models/point_history_model.dart';
import 'package:petshopapp/constants/point_constants.dart';

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
                          children: [
                            const Text(
                              'Nilai Tukar',
                              style: TextStyle(color: AppColors.textLight, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${PointConstants.poinPerRedeem.toInt()} poin = '
                              'Rp${PointConstants.diskonPerRedeem.toInt()}',
                              style: const TextStyle(
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

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('point_history')
                  .where('uid', isEqualTo: user.uid)
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Gagal memuat riwayat poin.'),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
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
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final history = PointHistoryModel.fromFirestore(docs[index]);
                    final double poin = history.poin;
                    final String keterangan = history.keterangan;
                    final String tanggal = history.createdAt != null ? _formatDate(history.createdAt!) : '-';
                    final bool isPlus = history.isEarn;

                    return _buildHistoryItem(
                      icon: isPlus
                          ? Icons.add_circle_outline
                          : Icons.remove_circle_outline,
                      iconColor: isPlus ? Colors.green : AppColors.error,
                      title: keterangan,
                      subtitle: tanggal,
                      points: '${isPlus ? '+' : ''}$poin poin',
                      pointsColor: isPlus ? Colors.green : AppColors.error,
                    );
                  },
                );
              },
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
          onPressed: user.poin < PointConstants.minPoinRedeem
              ? null
              : () => _showTukarPoinDialog(context, user.poin, user.uid),
          icon: const Icon(Icons.redeem),
          label: Text(
            user.poin < PointConstants.minPoinRedeem
                ? 'Poin belum cukup (min. ${PointConstants.minPoinRedeem})'
                : 'Tukarkan Poin',
          ),
        ),
      ),
    );
  }

  String _getTier(double poin) {
    if (poin >= 10000) return '💎 Platinum Member';
    if (poin >= 5000) return '🥇 Gold Member';
    if (poin >= 1000) return '🥈 Silver Member';
    return '🥉 Bronze Member';
  }

  String _formatDate(DateTime dt) {
    const bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${bulan[dt.month]} ${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showTukarPoinDialog(BuildContext context, double currentPoin, String uid) {
    final preview = {
      'diskon'       : PointConstants.hitungDiskon(currentPoin),
      'poinTerpakai' : PointConstants.hitungPoinTerpakai(currentPoin),
      'sisaPoin'     : PointConstants.sisaPoin(currentPoin),
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tukarkan Poin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info poin user
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Poin kamu: ${currentPoin.toStringAsFixed(1)} poin',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '${PointConstants.minPoinRedeem.toInt()} poin = '
                    'Rp${PointConstants.diskonPerRedeem.toInt()}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Preview hasil tukar (otomatis semua poin yang bisa ditukar)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rincian Penukaran:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  _buildPreviewRow(
                    'Poin dipakai',
                    '${preview['poinTerpakai']!.toStringAsFixed(1)} poin',
                    Colors.red,
                  ),
                  _buildPreviewRow(
                    'Diskon didapat',
                    'Rp${preview['diskon']!.toInt()}',
                    Colors.green,
                  ),
                  _buildPreviewRow(
                    'Sisa poin',
                    '${preview['sisaPoin']!.toStringAsFixed(1)} poin',
                    Colors.grey,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _prosesTukarPoin(
                context,
                uid,
                currentPoin,
                preview['poinTerpakai']!, // otomatis pakai semua poin yang bisa
              );
            },
            child: const Text('Tukar'),
          ),
        ],
      ),
    );
  }

  // Widget helper untuk baris preview
  Widget _buildPreviewRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: valueColor)),
        ],
      ),
    );
  }

  Future<void> _prosesTukarPoin(
      BuildContext context, String uid, double currentPoin, double jumlahTukar) async {
    final authService = context.read<AuthService>();
    final messenger = ScaffoldMessenger.of(context);

    // Hitung diskon pakai konstanta baru
    final double nilaiDiskon = PointConstants.hitungDiskon(currentPoin);
    final double sisaPoin    = PointConstants.sisaPoin(currentPoin);

    try {
      final firestore = FirebaseFirestore.instance;

      await firestore.collection('users').doc(uid).update({'poin': sisaPoin});

      await firestore.collection('point_history').add({
        'uid'        : uid,
        'poin'       : -jumlahTukar,
        'type'       : 'redeem',
        'keterangan' : 'Penukaran poin — diskon Rp${_formatRupiah(nilaiDiskon)}',
        'created_at' : FieldValue.serverTimestamp(),
      });

      await authService.refreshProfile();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${jumlahTukar.toStringAsFixed(1)} poin ditukar! '
            'Diskon Rp${_formatRupiah(nilaiDiskon)}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menukar poin: $e')),
      );
    }
  }

  String _formatRupiah(double value) {
    return value.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
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
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
      trailing: Text(points,
          style: TextStyle(
              color: pointsColor, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}