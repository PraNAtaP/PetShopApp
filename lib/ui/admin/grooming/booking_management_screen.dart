import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petshopapp/services/grooming_service.dart';
import 'package:petshopapp/models/grooming_booking_model.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingManagementScreen extends StatelessWidget {
  const BookingManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Manajemen Booking Grooming'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {}, // Refresh logic
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<GroomingBookingModel>>(
        stream: GroomingService.instance.getAdminBookingsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.error)),
                ],
              ),
            );
          }

          final bookings = snapshot.data ?? [];

          if (bookings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Belum ada pesanan grooming.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.resolveWith(
                  (states) => AppColors.primary.withValues(alpha: 0.1),
                ),
                columns: const [
                  DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Hewan', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Layanan', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Jadwal', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Bukti', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: bookings.map((booking) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(booking.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('ID: ${booking.userId.substring(0, 5)}...', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            Icon(booking.petType == 'Kucing' ? Icons.pets : Icons.pets, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text('${booking.petName} (${booking.petType})'),
                          ],
                        ),
                      ),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(booking.serviceType),
                            Text(
                              booking.isHomeService ? '🏠 Home Service' : '📍 Di Toko',
                              style: const TextStyle(fontSize: 10, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(DateFormat('dd/MM/yyyy').format(booking.bookingDate)),
                            Text(booking.timeSlot, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      DataCell(
                        booking.buktiBayarUrl != null
                            ? IconButton(
                                icon: const Icon(Icons.receipt_long, color: Colors.blue),
                                onPressed: () => _showProofDialog(context, booking.buktiBayarUrl!),
                                tooltip: 'Lihat Bukti Bayar',
                              )
                            : Text(
                                booking.metodePembayaran == 'COD' ? '💵 COD' : '-',
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                      ),
                      DataCell(_buildStatusBadge(booking.status)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (booking.status == 'Pending')
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                onPressed: () => _updateStatus(context, booking.bookingId, 'Confirmed'),
                                tooltip: 'Konfirmasi',
                              ),
                            if (booking.status == 'Confirmed')
                              IconButton(
                                icon: const Icon(Icons.done_all, color: Colors.blue),
                                onPressed: () => _updateStatus(context, booking.bookingId, 'Completed'),
                                tooltip: 'Selesai',
                              ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _updateStatus(context, booking.bookingId, 'Cancelled'),
                              tooltip: 'Batalkan',
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

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Confirmed': color = Colors.blue; break;
      case 'Completed': color = Colors.green; break;
      case 'Cancelled': color = Colors.red; break;
      default: color = Colors.orange; // Pending
    }

    return Chip(
      label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _updateStatus(BuildContext context, String id, String status) async {
    try {
      await GroomingService.instance.updateBookingStatus(id, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status diperbarui menjadi $status')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status: $e')),
      );
    }
  }

  void _showProofDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bukti Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                width: 300,
                height: 400,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => launchUrl(Uri.parse(url)),
            child: const Text('Buka Gambar Penuh'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
