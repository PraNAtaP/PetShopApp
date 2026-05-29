import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petshopapp/models/grooming_booking_model.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/ui/admin/grooming/admin_add_grooming_dialog.dart';
import 'package:petshopapp/services/grooming_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class BookingManagementScreen extends StatefulWidget {
  const BookingManagementScreen({super.key});

  @override
  State<BookingManagementScreen> createState() => _BookingManagementScreenState();
}

class _BookingManagementScreenState extends State<BookingManagementScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Kelola Booking Grooming'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const AdminAddGroomingDialog(),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Booking Manual'),
      ),
      body: StreamBuilder<List<GroomingBookingModel>>(
        stream: GroomingService.instance.getAdminBookingsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          final bookings = snapshot.data ?? [];

          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Belum ada pesanan grooming masuk.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.05)),
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('ID Booking', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Tanggal Masuk', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Pelanggan', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Jadwal Layanan', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Lokasi Layanan', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status Grooming', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: bookings.map((booking) => _buildBookingRow(booking)).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  DataRow _buildBookingRow(GroomingBookingModel booking) {
    final hasCancelRequest = booking.cancelRequest == true;

    return DataRow(
      cells: [
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#${booking.bookingId.substring(0, 8).toUpperCase()}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              if (hasCancelRequest)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'REK. BATAL',
                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
        DataCell(Text(DateFormat('dd/MM/yy HH:mm').format(booking.createdAt))),
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(booking.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('dd/MM/yy').format(booking.bookingDate)),
              Text(booking.timeSlot, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
        DataCell(Text(currencyFormat.format(booking.totalPrice))),
        DataCell(_buildLocationTypeChip(booking.isHomeService)),
        DataCell(_buildStatusChip(booking.status)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20, color: Colors.blue),
                onPressed: () => _showBookingDetails(booking),
                tooltip: 'Lihat Detail',
              ),
              IconButton(
                icon: const Icon(Icons.edit_note, size: 20, color: Colors.orange),
                onPressed: () => _showUpdateStatusDialog(booking),
                tooltip: 'Update Status',
              ),
              if (booking.status.toLowerCase() != 'selesai' && 
                  booking.status.toLowerCase() != 'completed' && 
                  booking.status.toLowerCase() != 'dibatalkan' &&
                  booking.status.toLowerCase() != 'cancelled')
                IconButton(
                  icon: const Icon(Icons.check_circle, size: 20, color: Colors.green),
                  onPressed: () => _showCompletePaymentDialog(booking),
                  tooltip: 'Selesaikan & Bayar',
                ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
      case 'completed':
      case 'lunas & confirmed':
        return Colors.green;
      case 'confirmed':
      case 'menuju lokasi':
      case 'siap diambil':
        return Colors.blue;
      case 'sedang grooming':
      case 'proses':
        return Colors.purple;
      case 'menunggu verifikasi':
        return Colors.teal;
      case 'menunggu pembayaran':
      case 'pending':
      case 'menunggu':
        return Colors.orange;
      case 'dibatalkan':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _buildLocationTypeChip(bool isHomeService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isHomeService ? Colors.blue.shade50 : Colors.purple.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isHomeService ? Colors.blue.shade200 : Colors.purple.shade200),
      ),
      child: Text(
        isHomeService ? 'Home Service' : 'Di Toko',
        style: TextStyle(
          color: isHomeService ? Colors.blue.shade700 : Colors.purple.shade700,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showBookingDetails(GroomingBookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Detail Grooming', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Booking ID: ${booking.bookingId}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const Divider(height: 32),
                    
                    _buildDetailItem('Status Keseluruhan', booking.status, isBold: true),
                    _buildDetailItem('Metode Pembayaran', booking.metodePembayaran),
                    _buildDetailItem('Lokasi Layanan', booking.isHomeService ? 'Home Service' : 'Di Toko', isBold: true),
                    if (booking.isHomeService && booking.alamatLengkap != null) ...[
                      _buildDetailItem('Alamat', booking.alamatLengkap!),
                      if (booking.latitude != null && booking.longitude != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${booking.latitude},${booking.longitude}')),
                                child: SizedBox(
                                  height: 200,
                                  width: double.infinity,
                                  child: IgnorePointer(
                                    child: FlutterMap(
                                      options: MapOptions(
                                        initialCenter: LatLng(booking.latitude!, booking.longitude!),
                                        initialZoom: 15.0,
                                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                          userAgentPackageName: 'com.prana.pet_point',
                                        ),
                                        MarkerLayer(
                                          markers: [
                                            Marker(
                                              point: LatLng(booking.latitude!, booking.longitude!),
                                              width: 40,
                                              height: 40,
                                              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                child: ElevatedButton.icon(
                                  onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${booking.latitude},${booking.longitude}')),
                                  icon: const Icon(Icons.map, size: 16),
                                  label: const Text('Buka di Google Maps', style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.primary,
                                    elevation: 4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 24),
                    const Text('Jadwal Layanan', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(booking.bookingDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Pukul: ${booking.timeSlot}'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text('Detail Hewan & Layanan', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildDetailItem('Nama Hewan', booking.petName),
                    _buildDetailItem('Jenis Hewan', booking.petType),
                    _buildDetailItem('Tipe Layanan', booking.serviceType),
                    
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          currencyFormat.format(booking.totalPrice),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                    
                    if (booking.buktiBayarUrl != null) ...[
                      const SizedBox(height: 32),
                      const Text('Bukti Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          booking.buktiBayarUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 200,
                              color: Colors.grey[100],
                              child: const Center(child: CircularProgressIndicator()),
                            );
                          },
                        ),
                      ),
                    ],

                    if (booking.cancelRequest == true) ...[
                      const SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Permintaan Pembatalan',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade800),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (booking.metodePembayaran != 'COD') ...[
                              Text('Nama Bank: ${booking.cancelBankName ?? '-'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text('Nomor Rekening: ${booking.cancelBankAccount ?? '-'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text('Atas Nama: ${booking.cancelAccountHolder ?? '-'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 12),
                            ] else ...[
                              const Text('Pesanan COD (Cash on Delivery). Tidak ada detail transfer refund.', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await GroomingService.instance.updateBookingStatus(booking.bookingId, 'Dibatalkan');
                                      await FirebaseFirestore.instance
                                          .collection('grooming_bookings')
                                          .doc(booking.bookingId)
                                          .update({'cancel_request': false});
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Pembatalan disetujui!'), backgroundColor: Colors.green),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 0),
                                    child: const Text('Setujui'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final isPaid = booking.buktiBayarUrl != null && booking.buktiBayarUrl!.isNotEmpty;
                                      await GroomingService.instance.updateBookingStatus(booking.bookingId, isPaid ? 'Confirmed' : 'Pending');
                                      await FirebaseFirestore.instance
                                          .collection('grooming_bookings')
                                          .doc(booking.bookingId)
                                          .update({'cancel_request': false});
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Pembatalan ditolak.'), backgroundColor: Colors.orange),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0),
                                    child: const Text('Tolak'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textLight)),
          Flexible(
            child: Text(
              value, 
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)
            )
          ),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(GroomingBookingModel booking) {
    final bool isCOD = booking.metodePembayaran.toUpperCase() == 'COD';
    final bool isHomeService = booking.isHomeService;

    List<String> availableStatuses = [];
    
    if (isCOD) {
      availableStatuses = isHomeService 
        ? ['Pending', 'Confirmed', 'Menuju Lokasi', 'Sedang Grooming', 'Selesai', 'Dibatalkan']
        : ['Pending', 'Confirmed', 'Sedang Grooming', 'Siap Diambil', 'Selesai', 'Dibatalkan'];
    } else {
      availableStatuses = isHomeService
        ? ['Menunggu Pembayaran', 'Menunggu Verifikasi', 'Lunas & Confirmed', 'Menuju Lokasi', 'Sedang Grooming', 'Selesai', 'Dibatalkan']
        : ['Menunggu Pembayaran', 'Menunggu Verifikasi', 'Lunas & Confirmed', 'Sedang Grooming', 'Siap Diambil', 'Selesai', 'Dibatalkan'];
    }

    if (!availableStatuses.contains(booking.status)) {
      availableStatuses.insert(0, booking.status);
    }

    String selectedStatus = booking.status;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Update Status Grooming', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Metode Pembayaran: ${booking.metodePembayaran}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  Text('Lokasi Layanan: ${booking.isHomeService ? 'Home Service' : 'Di Toko'}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 20),
                  const Text('Pilih Status Gabungan:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableStatuses.map((status) {
                      final isSelected = selectedStatus == status;
                      final statusColor = _getStatusColor(status);
                      
                      return ChoiceChip(
                        label: Text(status),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => selectedStatus = status);
                        },
                        showCheckmark: false,
                        selectedColor: statusColor.withValues(alpha: 0.15),
                        backgroundColor: Colors.grey.shade100,
                        side: BorderSide(
                          color: isSelected ? statusColor : Colors.transparent,
                          width: 1.5,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? statusColor : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext), 
              child: const Text('Batal', style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: isSaving ? null : () async {
                setState(() => isSaving = true);
                try {
                  await GroomingService.instance.updateBookingStatus(booking.bookingId, selectedStatus);
                  if (mounted) {
                    Navigator.pop(dialogContext); 
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Status grooming berhasil diperbarui'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  setState(() => isSaving = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletePaymentDialog(GroomingBookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Selesaikan Transaksi?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tandai grooming ini sebagai Selesai/Completed?'),
            const SizedBox(height: 16),
            Text('Total Tagihan: ${currencyFormat.format(booking.totalPrice)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await GroomingService.instance.updateBookingStatus(booking.bookingId, 'Completed');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi Selesai & Masuk Kas!'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Ya, Selesai'),
          ),
        ],
      ),
    );
  }
}
