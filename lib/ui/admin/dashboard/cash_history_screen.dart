import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/order_model.dart';
import 'package:petshopapp/models/grooming_booking_model.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'package:petshopapp/services/grooming_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  String _selectedTypeFilter = 'Semua'; // Semua, Pesanan, Grooming

  Stream<List<OrderModel>>? _ordersStream;
  Stream<List<GroomingBookingModel>>? _groomingStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ordersStream ??= FirestoreService.instance.getAllOrdersStream();
    _groomingStream ??= GroomingService.instance.getAdminBookingsStream();
  }

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

  Future<void> _exportToCsv() async {
    final now = DateTime.now();
    final defaultStart = now.subtract(const Duration(days: 30));
    
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: defaultStart, end: now),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'PILIH RENTANG TANGGAL EXPORT',
      cancelText: 'Batal',
      confirmText: 'Export CSV',
      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450.0, maxHeight: 600.0),
            child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
          ),
        );
      },
    );

    if (picked == null) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final start = DateTime(picked.start.year, picked.start.month, picked.start.day);
      final end = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);

      final firestore = FirebaseFirestore.instance;
      final ordersSnap = await firestore.collection('orders').get();
      final groomingsSnap = await firestore.collection('grooming_bookings').get();

      List<OrderModel> orders = ordersSnap.docs.map((d) => OrderModel.fromFirestore(d)).toList();
      List<GroomingBookingModel> groomings = groomingsSnap.docs.map((d) => GroomingBookingModel.fromFirestore(d)).toList();

      List<dynamic> allTransactions = [];
      
      for (var o in orders) {
        if (o.statusBayar.toLowerCase() == 'lunas') {
          final date = o.createdAt ?? DateTime(0);
          if ((date.isAfter(start) || date.isAtSameMomentAs(start)) && date.isBefore(end)) {
            allTransactions.add(o);
          }
        }
      }
      for (var g in groomings) {
        if (g.status.toLowerCase() == 'completed' || g.status.toLowerCase() == 'selesai') {
          final date = g.createdAt;
          if ((date.isAfter(start) || date.isAtSameMomentAs(start)) && date.isBefore(end)) {
            allTransactions.add(g);
          }
        }
      }

      allTransactions.sort((a, b) {
        final aDate = a is OrderModel ? (a.createdAt ?? DateTime(0)) : a.createdAt;
        final bDate = b is OrderModel ? (b.createdAt ?? DateTime(0)) : b.createdAt;
        return bDate.compareTo(aDate);
      });

      StringBuffer csvData = StringBuffer();
      csvData.writeln("Tanggal,Jenis Transaksi,Deskripsi,Nominal,Status");

      for (var item in allTransactions) {
        if (item is OrderModel) {
          final dateStr = item.createdAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(item.createdAt!) : '-';
          final jenis = item.metodePengambilan == 'Offline' && item.customerId == 'OFFLINE_CUSTOMER' ? 'Order Offline' : 'Order Online';
          final desc = "Order #${item.orderId.substring(0, 8)} - ${item.items.length} item";
          final nominal = item.totalHarga.toStringAsFixed(0);
          csvData.writeln("$dateStr,$jenis,\"$desc\",$nominal,${item.statusBayar}");
        } else if (item is GroomingBookingModel) {
          final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(item.createdAt);
          final desc = "Grooming ${item.petName} - Paket ${item.serviceType}";
          final nominal = item.totalPrice.toStringAsFixed(0);
          csvData.writeln("$dateStr,Grooming,\"$desc\",$nominal,${item.status}");
        }
      }

      final bytes = utf8.encode(csvData.toString());
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "Riwayat_Transaksi_PetPoint_${DateFormat('yyyyMMdd').format(now)}.csv")
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil mengunduh CSV')));
      }

    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal export CSV: $e')));
      }
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
        stream: _ordersStream,
        builder: (context, orderSnapshot) {
          if (orderSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<List<GroomingBookingModel>>(
            stream: _groomingStream,
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
                    width: double.infinity,
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
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: _exportToCsv,
                                icon: const Icon(Icons.download, size: 16),
                                label: const Text('Export CSV', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
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
