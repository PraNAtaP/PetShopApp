import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/order_model.dart';
import 'package:petshopapp/models/product_model.dart';
import 'package:petshopapp/models/grooming_booking_model.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'package:petshopapp/services/grooming_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  DateTime? _filterDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _filterDate) {
      setState(() {
        _filterDate = picked;
      });
    }
  }

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
            
            if (date.isAfter(monthStart) || date.isAtSameMomentAs(monthStart)) {
              monthRevenue += order.totalHarga;
            }
            if (date.isAfter(weekStart) || date.isAtSameMomentAs(weekStart)) {
              weekRevenue += order.totalHarga;
            }
            if (date.isAfter(todayStart) || date.isAtSameMomentAs(todayStart)) {
              todayRevenue += order.totalHarga;
            }
          }

          // Tambahkan pendapatan grooming
          for (var grooming in paidGroomings) {
            final date = grooming.createdAt;
            
            if (date.isAfter(monthStart) || date.isAtSameMomentAs(monthStart)) {
              monthRevenue += grooming.totalPrice;
            }
            if (date.isAfter(weekStart) || date.isAtSameMomentAs(weekStart)) {
              weekRevenue += grooming.totalPrice;
            }
            if (date.isAfter(todayStart) || date.isAtSameMomentAs(todayStart)) {
              todayRevenue += grooming.totalPrice;
            }
          }

          // Gabungkan list terbaru (order + grooming) untuk tabel transaksi
          List<dynamic> recentTransactions = [...orders, ...groomings];
          recentTransactions.sort((a, b) {
            final aDate = a is OrderModel ? (a.createdAt ?? DateTime(0)) : a.createdAt;
            final bDate = b is OrderModel ? (b.createdAt ?? DateTime(0)) : b.createdAt;
            return bDate.compareTo(aDate);
          });
          
          if (_filterDate != null) {
            recentTransactions = recentTransactions.where((item) {
              final date = item is OrderModel ? (item.createdAt ?? DateTime(0)) : (item as GroomingBookingModel).createdAt;
              return date.year == _filterDate!.year && date.month == _filterDate!.month && date.day == _filterDate!.day;
            }).toList();
          }

          final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard Keuangan',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ringkasan pendapatan dari transaksi online dan offline toko.',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
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
                    Row(
                      children: [
                        if (_filterDate != null)
                          TextButton.icon(
                            onPressed: () => setState(() => _filterDate = null),
                            icon: const Icon(Icons.clear, size: 16),
                            label: const Text('Hapus Filter'),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                          ),
                        TextButton.icon(
                          onPressed: () => _selectDate(context),
                          icon: const Icon(Icons.calendar_month),
                          label: Text(_filterDate == null 
                              ? 'Filter Tanggal' 
                              : DateFormat('dd MMM yyyy').format(_filterDate!)),
                        ),
                      ],
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
                            itemCount: recentTransactions.take(20).length, // Show up to 20 recent transactions
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
                                        currencyFormatter.format(order.totalHarga),
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
                                        currencyFormatter.format(grooming.totalPrice),
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

  Widget _buildKpiCard({required String title, required String value, required IconData icon, required Color color, Color textColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.w600)),
              Icon(icon, color: textColor.withOpacity(0.8), size: 28),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
