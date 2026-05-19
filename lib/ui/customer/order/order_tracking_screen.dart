import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/order_model.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'package:petshopapp/ui/customer/order/order_status_helper.dart';

/// Displays real-time order tracking with a visual stepper and cancel functionality.
class OrderTrackingScreen extends StatelessWidget {
  final OrderModel order;

  const OrderTrackingScreen({super.key, required this.order});

  // Define the tracking steps for shop orders
  static const List<TrackingStep> _shopSteps = [
    TrackingStep(
      icon: Icons.hourglass_top_rounded,
      label: 'Menunggu Verifikasi',
      description: 'Admin sedang memverifikasi pembayaran Anda',
    ),
    TrackingStep(
      icon: Icons.inventory_2_outlined,
      label: 'Diproses',
      description: 'Pesanan sedang dikemas oleh toko',
    ),
    TrackingStep(
      icon: Icons.local_shipping_outlined,
      label: 'Dikirim',
      description: 'Kurir sedang dalam perjalanan',
    ),
    TrackingStep(
      icon: Icons.check_circle_outline,
      label: 'Pesanan Selesai',
      description: 'Pesanan telah sampai di tujuan',
    ),
  ];

  int _getCurrentStep(String status) {
    switch (status) {
      case 'Menunggu Verifikasi':
      case 'Menunggu Pembayaran':
      case 'Belum Bayar':
      case 'Pending':
        return 0;
      case 'Diproses':
      case 'Lunas':
      case 'Paid':
        return 1;
      case 'Dikirim':
      case 'Siap Diambil':
        return 2;
      case 'Selesai':
      case 'Pesanan Selesai':
        return 3;
      default:
        return 0;
    }
  }

  bool _canCancel(String statusPengiriman) {
    // Can only cancel before "Dikirim"
    final idx = _getCurrentStep(statusPengiriman);
    return idx < 2;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(order.orderId)
          .snapshots(),
      builder: (context, snapshot) {
        // Use live data if available, otherwise fallback to passed order
        final liveData = snapshot.data?.data() as Map<String, dynamic>?;
        final statusBayar = liveData?['status_bayar'] ?? order.statusBayar;
        final statusPengiriman = liveData?['status_pengiriman'] ?? order.statusPengiriman;
        final cancelRequest = liveData?['cancel_request'] == true;
        final isCancelled = statusPengiriman == 'Dibatalkan' || statusBayar == 'Dibatalkan';

        final currentStep = _getCurrentStep(statusPengiriman);

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(
              'Order #${order.orderId.substring(0, 8).toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cancel / Cancelled banner
                if (isCancelled) const CancelledBanner(),
                if (cancelRequest && !isCancelled) const CancelRequestBanner(),

                // Order Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Detail Pesanan',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(statusBayar).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusBayar,
                              style: TextStyle(
                                color: _getStatusColor(statusBayar),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Tanggal', order.createdAt != null
                          ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(order.createdAt!)
                          : '-'),
                      _buildInfoRow('Metode Bayar', order.metodePembayaran),
                      _buildInfoRow('Pengambilan', order.metodePengambilan),
                      const Divider(height: 24),
                      ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item.jumlah}x',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(item.nama, style: const TextStyle(fontSize: 13)),
                            ),
                            Text(
                              currencyFormatter.format(item.hargaSatuan * item.jumlah),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      )),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(
                            currencyFormatter.format(order.totalHarga),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Status Tracking Stepper
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Pengiriman',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      StatusStepper(
                        steps: _shopSteps,
                        currentStep: currentStep,
                        isCancelled: isCancelled,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Cancel Button
                if (_canCancel(statusPengiriman) && !cancelRequest && !isCancelled)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(context),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Batalkan Pesanan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Lunas':
      case 'Paid':
        return const Color(0xFF2E7D32);
      case 'Menunggu Verifikasi':
      case 'Pending':
        return Colors.orange;
      case 'Dibatalkan':
        return AppColors.error;
      default:
        return AppColors.textLight;
    }
  }

  void _showCancelDialog(BuildContext context) {
    final isNonCod = order.metodePembayaran != 'COD';

    if (isNonCod) {
      _showCancelWithBankDialog(context);
    } else {
      _showCancelCodDialog(context);
    }
  }

  void _showCancelCodDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pesanan?'),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan pesanan ini? Pembatalan akan ditinjau oleh Admin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tidak', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirestoreService.instance.requestCancelOrder(
                orderId: order.orderId,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pengajuan pembatalan berhasil dikirim!'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  void _showCancelWithBankDialog(BuildContext context) {
    final bankNameCtrl = TextEditingController();
    final bankAccountCtrl = TextEditingController();
    final accountHolderCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pesanan'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Untuk proses pengembalian dana, silakan masukkan informasi rekening Anda.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: bankNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Bank',
                    hintText: 'cth: BCA, BNI, Mandiri',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: bankAccountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Rekening',
                    hintText: 'cth: 1234567890',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: accountHolderCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Atas Nama',
                    hintText: 'cth: Pranama',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              await FirestoreService.instance.requestCancelOrder(
                orderId: order.orderId,
                bankName: bankNameCtrl.text.trim(),
                bankAccount: bankAccountCtrl.text.trim(),
                accountHolder: accountHolderCtrl.text.trim(),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pengajuan pembatalan berhasil dikirim!'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ajukan Pembatalan'),
          ),
        ],
      ),
    );
  }
}
