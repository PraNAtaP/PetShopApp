import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/order_model.dart';
import 'package:petshopapp/models/grooming_booking_model.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'package:petshopapp/services/grooming_service.dart';

class CashHistoryScreen extends StatefulWidget {
  const CashHistoryScreen({super.key});

  @override
  State<CashHistoryScreen> createState() => _CashHistoryScreenState();
}

class _CashHistoryScreenState extends State<CashHistoryScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  String _selectedDateFilter = 'Hari Ini'; // Semua Waktu, Hari Ini, Minggu Ini, Bulan Ini, Rentang Tanggal
  DateTimeRange? _customDateRange;
  String _selectedTypeFilter = 'Semua'; // Semua, Grooming, Pesanan

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _customDateRange ?? DateTimeRange(start: DateTime.now(), end: DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 450.0,
              maxHeight: 600.0,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: child,
            ),
          ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedDateFilter = 'Rentang Tanggal';
      });
    }
  }

  bool _isDateInRange(DateTime date) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    if (_selectedDateFilter == 'Hari Ini') {
      return date.isAfter(todayStart) || date.isAtSameMomentAs(todayStart);
    } else if (_selectedDateFilter == 'Minggu Ini') {
      final weekStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));
      return date.isAfter(weekStart) || date.isAtSameMomentAs(weekStart);
    } else if (_selectedDateFilter == 'Bulan Ini') {
      final monthStart = DateTime(now.year, now.month, 1);
      return date.isAfter(monthStart) || date.isAtSameMomentAs(monthStart);
    } else if (_selectedDateFilter == 'Rentang Tanggal' && _customDateRange != null) {
      final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
      final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
      return (date.isAfter(start) || date.isAtSameMomentAs(start)) && date.isBefore(end);
    }
    return true; // Semua Waktu
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Arus Kas'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: FirestoreService.instance.getAllOrdersStream(),
        builder: (context, orderSnapshot) {
          if (orderSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<List<GroomingBookingModel>>(
            stream: GroomingService.instance.getAdminBookingsStream(),
            builder: (context, groomingSnapshot) {
              if (groomingSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final orders = orderSnapshot.data ?? [];
              final groomings = groomingSnapshot.data ?? [];

              // 1. Filter status lunas/completed
              final lunasOrders = orders.where((o) => o.statusBayar.toLowerCase() == 'lunas').toList();
              final paidGroomings = groomings.where((g) => g.status.toLowerCase() == 'completed' || g.status.toLowerCase() == 'selesai').toList();

              // 2. Combine based on Type filter
              List<dynamic> allTransactions = [];
              if (_selectedTypeFilter == 'Semua' || _selectedTypeFilter == 'Pesanan') {
                allTransactions.addAll(lunasOrders);
              }
              if (_selectedTypeFilter == 'Semua' || _selectedTypeFilter == 'Grooming') {
                allTransactions.addAll(paidGroomings);
              }

              // 3. Filter by Date
              allTransactions = allTransactions.where((item) {
                final date = item is OrderModel ? (item.createdAt ?? DateTime(0)) : (item as GroomingBookingModel).createdAt;
                return _isDateInRange(date);
              }).toList();

              // 4. Sort descending
              allTransactions.sort((a, b) {
                final aDate = a is OrderModel ? (a.createdAt ?? DateTime(0)) : a.createdAt;
                final bDate = b is OrderModel ? (b.createdAt ?? DateTime(0)) : b.createdAt;
                return bDate.compareTo(aDate);
              });

              // Calculate total for displayed items (ONLY PAID)
              double totalFilteredRevenue = 0;
              for (var item in allTransactions) {
                if (item is OrderModel && item.statusBayar.toLowerCase() == 'lunas') {
                  totalFilteredRevenue += item.totalHarga;
                }
                if (item is GroomingBookingModel && (item.status.toLowerCase() == 'completed' || item.status.toLowerCase() == 'selesai')) {
                  totalFilteredRevenue += item.totalPrice;
                }
              }

              return Column(
                children: [
                  // Filter Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.filter_alt, color: AppColors.primary),
                            const SizedBox(width: 8),
                            const Text('Filter Riwayat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Spacer(),
                            Text(
                              'Total: ${currencyFormatter.format(totalFilteredRevenue)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildDropdown(
                                label: 'Waktu',
                                value: _selectedDateFilter == 'Rentang Tanggal' && _customDateRange == null ? 'Semua Waktu' : _selectedDateFilter,
                                items: ['Semua Waktu', 'Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Rentang Tanggal'],
                                onChanged: (val) {
                                  if (val == 'Rentang Tanggal') {
                                    _pickDateRange();
                                  } else {
                                    setState(() {
                                      _selectedDateFilter = val!;
                                      _customDateRange = null;
                                    });
                                  }
                                },
                              ),
                              if (_selectedDateFilter == 'Rentang Tanggal' && _customDateRange != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Chip(
                                    label: Text('${DateFormat('dd MMM').format(_customDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_customDateRange!.end)}'),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedDateFilter = 'Semua Waktu';
                                        _customDateRange = null;
                                      });
                                    },
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
                                  ),
                                ),
                              const SizedBox(width: 16),
                              _buildDropdown(
                                label: 'Jenis',
                                value: _selectedTypeFilter,
                                items: ['Semua', 'Pesanan', 'Grooming'],
                                onChanged: (val) {
                                  setState(() {
                                    _selectedTypeFilter = val!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(height: 1),

                  // List Section
                  Expanded(
                    child: allTransactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text('Tidak ada transaksi yang sesuai filter', style: TextStyle(color: Colors.grey.shade500)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: allTransactions.length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final item = allTransactions[index];
                              
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
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label),
          isDense: true,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
