import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/providers/grooming_provider.dart';
import 'package:petshopapp/services/auth_service.dart';
import 'package:intl/intl.dart';

class GroomingSummaryScreen extends StatelessWidget {
  const GroomingSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GroomingProvider>();
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    final totalPrice = provider.selectedPrice * provider.selectedPets.length;

    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      appBar: AppBar(
        title: const Text('Ringkasan Booking'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.16),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Booking Grooming Anda Siap!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Periksa kembali detail booking sebelum melanjutkan ke pembayaran.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Detail Layanan'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoRow(
                    'Jenis Layanan',
                    provider.selectedServices.isNotEmpty
                        ? provider.selectedServices.join(', ')
                        : '-',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Harga per Pet',
                    currencyFormat.format(provider.selectedPrice),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Jumlah Hewan',
                    '${provider.selectedPets.length} Hewan',
                  ),
                  const SizedBox(height: 12),
                  _buildChipList(
                    'Daftar Hewan',
                    provider.selectedPets.map((p) => p.name).toList(),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: 14),
                  _buildInfoRow(
                    'Tanggal',
                    provider.selectedDate != null
                        ? dateFormat.format(provider.selectedDate!)
                        : '-',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Waktu', provider.selectedTimeSlot ?? '-'),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Lokasi',
                    provider.isHomeService ? 'Home Service' : 'Bawa ke Petshop',
                  ),
                  if (provider.isHomeService) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow('Alamat', provider.alamatLengkap),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Pembayaran di langkah berikutnya',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Pembayaran dilakukan melalui QRIS atau Transfer setelah Anda konfirmasi booking.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textLight,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Total Pembayaran',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Bayar setelah konfirmasi',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    currencyFormat.format(totalPrice),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
      bottomSheet: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: user == null
                  ? null
                  : () => context.push('/grooming-payment-method'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Konfirmasi & Bayar Sekarang'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChipList(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.isEmpty
              ? [
                  const Chip(
                    label: Text(
                      '-',
                      style: TextStyle(color: AppColors.textLight),
                    ),
                  ),
                ]
              : items.map((item) {
                  return Chip(
                    label: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: const Color(0xFF1976D2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                }).toList(),
        ),
      ],
    );
  }
}
