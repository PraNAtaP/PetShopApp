import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/order_model.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService.instance;
  final Map<String, String> _userNames = {};

  Future<String> _getUserName(String uid) async {
    if (_userNames.containsKey(uid)) return _userNames[uid]!;
    try {
      final user = await _firestoreService.getUserProfile(uid);
      final name = user?.nama ?? 'Pelanggan ($uid)';
      _userNames[uid] = name;
      return name;
    } catch (_) {
      return 'Pelanggan ($uid)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Kelola Pesanan (Shop)'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _firestoreService.getAllOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Belum ada pesanan masuk.', style: TextStyle(color: Colors.grey)),
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
                    DataColumn(label: Text('ID Pesanan', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Pelanggan', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status Bayar', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status Kirim', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: orders.map((order) => _buildOrderRow(order)).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  DataRow _buildOrderRow(OrderModel order) {
    final hasCancelRequest = order.cancelRequest == true;

    return DataRow(
      cells: [
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#${order.orderId.substring(0, 8).toUpperCase()}',
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
        DataCell(Text(order.createdAt != null ? DateFormat('dd/MM/yy HH:mm').format(order.createdAt!) : '-')),
        DataCell(
          FutureBuilder<String>(
            future: _getUserName(order.customerId),
            builder: (context, snapshot) => Text(snapshot.data ?? '...'),
          ),
        ),
        DataCell(Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(order.totalHarga))),
        DataCell(_buildStatusChip(order.statusBayar, isPayment: true)),
        DataCell(_buildStatusChip(order.statusPengiriman, isPayment: false)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20, color: Colors.blue),
                onPressed: () => _showOrderDetails(order),
                tooltip: 'Lihat Detail',
              ),
              IconButton(
                icon: const Icon(Icons.edit_note, size: 20, color: Colors.orange),
                onPressed: () => _showUpdateStatusDialog(order),
                tooltip: 'Update Status',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'lunas':
      case 'selesai':
      case 'diambil':
        return Colors.green;
      case 'dikirim':
        return Colors.blue;
      case 'proses':
      case 'diproses':
        return Colors.purple;
      case 'menunggu verifikasi':
        return Colors.teal;
      case 'menunggu pembayaran':
      case 'pending':
        return Colors.orange;
      case 'menunggu':
        return Colors.blueGrey;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _buildStatusChip(String status, {required bool isPayment}) {
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

  void _showOrderDetails(OrderModel order) {
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
                    const Text('Detail Pesanan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Order ID: ${order.orderId}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const Divider(height: 32),
                    
                    _buildDetailItem('Status Pembayaran', order.statusBayar, isBold: true),
                    _buildDetailItem('Status Pengiriman', order.statusPengiriman, isBold: true),
                    _buildDetailItem('Metode Pengambilan', order.metodePengambilan),
                    _buildDetailItem('Metode Pembayaran', order.metodePembayaran),
                    if (order.metodePengambilan == 'Kirim ke Alamat' && order.alamatLengkap != null) ...[
                      _buildDetailItem('Alamat Pengiriman', order.alamatLengkap!),
                      if (order.latitude != null && order.longitude != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${order.latitude},${order.longitude}')),
                                child: SizedBox(
                                  height: 200,
                                  width: double.infinity,
                                  child: IgnorePointer(
                                    child: FlutterMap(
                                      options: MapOptions(
                                        initialCenter: LatLng(order.latitude!, order.longitude!),
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
                                              point: LatLng(order.latitude!, order.longitude!),
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
                                  onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${order.latitude},${order.longitude}')),
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
                    const Text('Daftar Produk', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                            child: Text('${item.jumlah}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(item.nama)),
                          Text(
                            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(item.hargaSatuan * item.jumlah),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(order.totalHarga),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                    
                    if (order.buktiBayarUrl != null) ...[
                      const SizedBox(height: 32),
                      const Text('Bukti Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          order.buktiBayarUrl!,
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
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => launchUrl(Uri.parse(order.buktiBayarUrl!)),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Buka Gambar Penuh'),
                        ),
                      ),
                    ],

                    if (order.cancelRequest == true) ...[
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
                            if (order.metodePembayaran != 'COD') ...[
                              Text('Nama Bank: ${order.cancelBankName ?? '-'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text('Nomor Rekening: ${order.cancelBankAccount ?? '-'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text('Atas Nama: ${order.cancelAccountHolder ?? '-'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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
                                      await _firestoreService.updateOrderFullStatus(
                                        orderId: order.orderId,
                                        statusBayar: 'Dibatalkan',
                                        statusPengiriman: 'Dibatalkan',
                                      );
                                      await FirebaseFirestore.instance
                                          .collection('orders')
                                          .doc(order.orderId)
                                          .update({'cancel_request': false});
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Pembatalan pesanan disetujui!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                    ),
                                    child: const Text('Setujui'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final isPaid = order.buktiBayarUrl != null && order.buktiBayarUrl!.isNotEmpty;
                                      await _firestoreService.updateOrderFullStatus(
                                        orderId: order.orderId,
                                        statusBayar: isPaid ? 'Lunas' : 'Menunggu Verifikasi',
                                        statusPengiriman: isPaid ? 'Diproses' : 'Menunggu',
                                      );
                                      await FirebaseFirestore.instance
                                          .collection('orders')
                                          .doc(order.orderId)
                                          .update({'cancel_request': false});
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Pembatalan pesanan ditolak.'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                    ),
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
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showUpdateStatusDialog(order),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Update Status'),
                          ),
                        ),
                        if (order.statusBayar == 'Menunggu Verifikasi') ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _verifyPayment(order.orderId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Verifikasi Lunas'),
                            ),
                          ),
                        ],
                      ],
                    ),
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
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(OrderModel order) {
    // Validasi Dinamis Berdasarkan Metode Pembayaran dan Pengiriman
    final bool isCOD = order.metodePembayaran.toUpperCase() == 'COD';
    final bool isAmbilDiToko = order.metodePengambilan.toLowerCase().contains('ambil');

    final List<String> paymentStatuses = isCOD 
      ? ['Menunggu Pembayaran', 'Lunas', 'Dibatalkan'] 
      : ['Menunggu Pembayaran', 'Menunggu Verifikasi', 'Lunas', 'Dibatalkan'];
    
    final List<String> shippingStatuses = isAmbilDiToko 
      ? ['Menunggu', 'Proses', 'Diambil', 'Selesai', 'Dibatalkan']
      : ['Menunggu', 'Proses', 'Dikirim', 'Selesai', 'Dibatalkan'];

    // Pastikan nilai dari database tetap terbaca jika menggunakan format lama
    if (!paymentStatuses.contains(order.statusBayar)) {
      paymentStatuses.insert(0, order.statusBayar);
    }
    if (!shippingStatuses.contains(order.statusPengiriman)) {
      shippingStatuses.insert(0, order.statusPengiriman);
    }

    String selectedPaymentStatus = order.statusBayar;
    String selectedShippingStatus = order.statusPengiriman;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Update Status Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status Pembayaran (${order.metodePembayaran})', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: paymentStatuses.map((status) {
                      final isSelected = selectedPaymentStatus == status;
                      final statusColor = _getStatusColor(status);
                      return ChoiceChip(
                        label: Text(status),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => selectedPaymentStatus = status);
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
                  const SizedBox(height: 28),
                  Text('Status Pengiriman (${order.metodePengambilan})', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: shippingStatuses.map((status) {
                      final isSelected = selectedShippingStatus == status;
                      final statusColor = _getStatusColor(status);
                      return ChoiceChip(
                        label: Text(status),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => selectedShippingStatus = status);
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
              onPressed: isSaving ? null : () => Navigator.pop(context), 
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
                  await _firestoreService.updateOrderFullStatus(
                    orderId: order.orderId,
                    statusBayar: selectedPaymentStatus,
                    statusPengiriman: selectedShippingStatus,
                  );
                  if (context.mounted) {
                    Navigator.pop(context); 
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Status pesanan berhasil diperbarui'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  setState(() => isSaving = false);
                  if (context.mounted) {
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

  Future<void> _verifyPayment(String orderId) async {
    try {
      await _firestoreService.updateOrderFullStatus(
        orderId: orderId,
        statusBayar: 'Lunas',
        statusPengiriman: 'Diproses',
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pembayaran berhasil diverifikasi!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal verifikasi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
