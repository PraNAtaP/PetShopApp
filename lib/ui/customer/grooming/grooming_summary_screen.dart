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
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ringkasan Booking'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 50, color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text('Daftar Layanan Grooming', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  _buildRow('Jenis Layanan:', provider.selectedServices.isNotEmpty ? provider.selectedServices.join(', ') : '-'),
                  _buildRow('Harga:', currencyFormat.format(provider.selectedPrice)),
                  const Divider(height: 32),
                  _buildRow('Nama Pet:', provider.petName),
                  _buildRow('Jenis Pet:', provider.petType),
                  const Divider(height: 32),
                  _buildRow('Tanggal:', provider.selectedDate != null ? dateFormat.format(provider.selectedDate!) : '-'),
                  _buildRow('Waktu:', provider.selectedTimeSlot ?? '-'),
                  const Divider(height: 32),
                  _buildRow('Lokasi:', provider.isHomeService ? 'Home Service' : 'Bawa ke Petshop'),
                  if (provider.isHomeService)
                    _buildRow('Alamat:', provider.alamatLengkap),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pembayaran:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        currencyFormat.format(provider.selectedPrice),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pembayaran dilakukan melalui QRIS atau Transfer di langkah berikutnya.',
                      style: TextStyle(fontSize: 12, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100), // Space for button
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () {
              if (user == null) return;
              context.push('/grooming-payment-method');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Konfirmasi & Bayar Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
