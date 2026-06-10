import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/order_model.dart';
import 'package:petshopapp/services/auth_service.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'package:petshopapp/ui/customer/order/order_tracking_screen.dart';

/// Displays real-time order history for the logged-in customer.
class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Riwayat Pesanan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text('Silakan login terlebih dahulu'))
          : StreamBuilder<List<OrderModel>>(
              stream: FirestoreService.instance.getOrdersStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text('Error: ${snapshot.error}',
                            style: const TextStyle(color: AppColors.textLight)),
                      ],
                    ),
                  );
                }

                final orders = snapshot.data ?? [];

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum ada pesanan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pesanan Anda akan muncul di sini',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderCard(context, order, currencyFormatter);
                  },
                );
              },
            ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    OrderModel order,
    NumberFormat formatter,
  ) {
    final dateStr = order.createdAt != null
        ? DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(order.createdAt!)
        : '-';

    bool isUnpaid = order.statusBayar == 'Unpaid';
    bool canResumePayment = false;
    int remainingSeconds = 0;
    
    if (isUnpaid && order.createdAt != null) {
      final elapsed = DateTime.now().difference(order.createdAt!).inSeconds;
      remainingSeconds = 480 - elapsed;
      if (remainingSeconds > 0) {
        canResumePayment = true;
      }
    }
    
    // UI Override for Expired Status (locally displayed as expired if time ran out but Firestore not yet updated)
    String displayStatusBayar = order.statusBayar;
    String displayStatusKirim = order.statusPengiriman;
    if (isUnpaid && !canResumePayment) {
      displayStatusBayar = 'Expired';
      displayStatusKirim = 'Dibatalkan';
      
      // Auto-expire in Firestore
      if (order.statusBayar != 'Expired') {
        Future.microtask(() {
          FirestoreService.instance.updateOrderFullStatus(
            orderId: order.orderId,
            statusBayar: 'Expired',
            statusPengiriman: 'Dibatalkan',
          );
        });
      }
    }
    
    final statusColor = _getStatusColor(displayStatusBayar);
    final statusIcon = _getStatusIcon(displayStatusBayar);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(order: order),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.06),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.orderId.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          displayStatusBayar,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          displayStatusKirim,
                          style: TextStyle(
                            color: displayStatusKirim == 'Dibatalkan' ? Colors.red : Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Items
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${item.nama} x${item.jumlah}',
                            style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                          ),
                        ),
                        Text(
                          formatter.format(item.hargaSatuan * item.jumlah),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        order.metodePembayaran == 'QRIS'
                            ? Icons.qr_code_2
                            : Icons.account_balance,
                        size: 16,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        order.metodePembayaran,
                        style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(color: Colors.grey.shade300),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.touch_app_outlined, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Ketuk untuk lacak',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                  Text(
                    formatter.format(order.totalHarga),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Resume Payment Button if applicable
            if (canResumePayment)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    context.pushNamed(
                      'payment-execution',
                      extra: {
                        'order': order,
                        'metodePembayaran': order.metodePembayaran,
                        'usePoints': order.diskonPoin > 0,
                        'discount': order.diskonPoin,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Selesaikan Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),

          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Paid':
        return AppColors.secondary;
      case 'Verified':
        return AppColors.primary;
      case 'Pending':
        return AppColors.accent;
      case 'Rejected':
        return AppColors.error;
      case 'Expired':
        return Colors.red;
      default:
        return AppColors.textLight;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Paid':
        return Icons.check_circle_outline;
      case 'Verified':
        return Icons.verified_outlined;
      case 'Pending':
        return Icons.hourglass_top_rounded;
      case 'Rejected':
      case 'Expired':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }
}
