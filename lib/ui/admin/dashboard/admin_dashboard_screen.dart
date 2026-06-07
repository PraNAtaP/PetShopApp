import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/order_model.dart';
import 'package:petshopapp/models/product_model.dart';
import 'package:petshopapp/models/grooming_booking_model.dart';
import 'package:petshopapp/models/admin_log_model.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'package:petshopapp/services/grooming_service.dart';
import 'package:petshopapp/services/admin_log_service.dart';

import 'package:petshopapp/ui/admin/dashboard/cash_history_screen.dart';
import 'package:petshopapp/ui/admin/dashboard/admin_log_history_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<OrderModel>>(
        stream: FirestoreService.instance.getAllOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<List<GroomingBookingModel>>(
            stream: GroomingService.instance.getAdminBookingsStream(),
            builder: (context, groomingSnapshot) {
              if (groomingSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (groomingSnapshot.hasError) {
                return Center(child: Text('Gagal memuat data grooming: ${groomingSnapshot.error}'));
              }

              final orders = snapshot.data ?? [];
              final groomings = groomingSnapshot.data ?? [];
              
              // Filter Lunas orders
              final lunasOrders = orders.where((o) => o.statusBayar.toLowerCase() == 'lunas').toList();
              // Filter Completed/Paid groomings (asumsi "Completed" berarti lunas)
              final paidGroomings = groomings.where((g) => g.status.toLowerCase() == 'completed' || g.status.toLowerCase() == 'selesai').toList();

              final now = DateTime.now();
              final todayStart = DateTime(now.year, now.month, now.day);
              // Week starts on Monday
              final weekStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));
              final monthStart = DateTime(now.year, now.month, 1);

              double todayRevenue = 0;
              double weekRevenue = 0;
              double monthRevenue = 0;

              for (var order in lunasOrders) {
                if (order.createdAt == null) continue;
                final date = order.createdAt!;
                
                final netRevenue = (order.totalHarga - order.diskonPoin).clamp(0, double.infinity).toDouble();
                if (date.isAfter(monthStart) || date.isAtSameMomentAs(monthStart)) {
                  monthRevenue += netRevenue;
                }
                if (date.isAfter(weekStart) || date.isAtSameMomentAs(weekStart)) {
                  weekRevenue += netRevenue;
                }
                if (date.isAfter(todayStart) || date.isAtSameMomentAs(todayStart)) {
                  todayRevenue += netRevenue;
                }
              }

              // Tambahkan pendapatan grooming
              for (var grooming in paidGroomings) {
                final date = grooming.createdAt;
                
                final netRevenue = (grooming.totalPrice - grooming.diskonPoin).clamp(0, double.infinity).toDouble();
                if (date.isAfter(monthStart) || date.isAtSameMomentAs(monthStart)) {
                  monthRevenue += netRevenue;
                }
                if (date.isAfter(weekStart) || date.isAtSameMomentAs(weekStart)) {
                  weekRevenue += netRevenue;
                }
                if (date.isAfter(todayStart) || date.isAtSameMomentAs(todayStart)) {
                  todayRevenue += netRevenue;
                }
              }

              // Gabungkan list terbaru (order + grooming) untuk tabel transaksi HANYA LUNAS/SELESAI HARI INI
              List<dynamic> recentTransactions = [...lunasOrders, ...paidGroomings].where((item) {
                final date = item is OrderModel ? (item.createdAt ?? DateTime(0)) : (item as GroomingBookingModel).createdAt;
                return date.isAfter(todayStart) || date.isAtSameMomentAs(todayStart);
              }).toList();
              recentTransactions.sort((a, b) {
                final aDate = a is OrderModel ? (a.createdAt ?? DateTime(0)) : a.createdAt;
                final bDate = b is OrderModel ? (b.createdAt ?? DateTime(0)) : b.createdAt;
                return bDate.compareTo(aDate);
              });
              final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 2.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Dashboard Keuangan',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ringkasan pendapatan dari transaksi online dan offline toko.',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
              
                    // KPI Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            title: 'Pendapatan Hari Ini',
                            value: currencyFormatter.format(todayRevenue),
                            icon: Icons.today,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildKpiCard(
                            title: 'Pendapatan Minggu Ini',
                            value: currencyFormatter.format(weekRevenue),
                            icon: Icons.calendar_view_week,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildKpiCard(
                            title: 'Pendapatan Bulan Ini',
                            value: currencyFormatter.format(monthRevenue),
                            icon: Icons.calendar_month,
                            color: AppColors.accent,
                            textColor: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildKpiCard(
                            title: 'Log Aktivitas',
                            value: 'Lihat Riwayat',
                            icon: Icons.history,
                            color: Colors.white,
                            textColor: AppColors.primary,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1.5,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminLogHistoryScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Recent Orders Table
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transaksi Terbaru',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CashHistoryScreen()),
                            );
                          },
                          child: const Text('Lihat Lebih >', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: recentTransactions.isEmpty
                            ? const Center(child: Text('Belum ada transaksi.'))
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: recentTransactions.take(20).length,
                                separatorBuilder: (context, index) => const Divider(),
                                itemBuilder: (context, index) {
                                  final item = recentTransactions[index];
                                  
                                  if (item is OrderModel) {
                                    final order = item;
                                    final dateStr = order.createdAt != null 
                                        ? DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt!) 
                                        : '-';
                                    final isOffline = order.metodePengambilan == 'Offline' && order.customerId == 'OFFLINE_CUSTOMER';
                                    
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: isOffline ? AppColors.accent.withOpacity(0.2) : AppColors.primary.withOpacity(0.2),
                                        child: Icon(
                                          isOffline ? Icons.storefront : Icons.local_shipping,
                                          color: isOffline ? AppColors.accent : AppColors.primary,
                                        ),
                                      ),
                                      title: Text(isOffline ? 'Order Kasir Offline' : 'Order #${order.orderId.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('$dateStr • ${order.items.length} item'),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            currencyFormatter.format((order.totalHarga - order.diskonPoin).clamp(0, double.infinity)),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          Text(
                                            order.statusBayar,
                                            style: TextStyle(
                                              color: order.statusBayar.toLowerCase() == 'lunas' ? Colors.green : AppColors.accent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else if (item is GroomingBookingModel) {
                                    final grooming = item;
                                    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(grooming.createdAt);
                                    
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.purple.withOpacity(0.2),
                                        child: const Icon(
                                          Icons.content_cut,
                                          color: Colors.purple,
                                        ),
                                      ),
                                      title: Text('Grooming: ${grooming.petName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('$dateStr • Paket: ${grooming.serviceType}'),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            currencyFormatter.format((grooming.totalPrice - grooming.diskonPoin).clamp(0, double.infinity)),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          Text(
                                            grooming.status,
                                            style: TextStyle(
                                              color: (grooming.status.toLowerCase() == 'completed' || grooming.status.toLowerCase() == 'selesai') ? Colors.green : Colors.orange,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    Color textColor = Colors.white,
    BoxBorder? border,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: border,
          boxShadow: [
            BoxShadow(
              color: color == Colors.white 
                  ? Colors.black.withOpacity(0.05) 
                  : color.withOpacity(0.4),
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
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: textColor.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: textColor.withOpacity(0.8), size: 28),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}