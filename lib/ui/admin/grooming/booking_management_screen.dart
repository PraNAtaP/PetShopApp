import 'package:flutter/material.dart';
import 'package:petshopapp/models/grooming_booking_model.dart';
import 'package:petshopapp/services/grooming_service.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingManagementScreen extends StatelessWidget {
  const BookingManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Manajemen Booking Grooming',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              ElevatedButton.icon(
                onPressed: () {}, // Add refresh if needed, but Stream handles it
                icon: const Icon(Icons.refresh),
                label: const Text('Segarkan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<List<GroomingBookingModel>>(
              stream: GroomingService.instance.getAdminBookingsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final bookings = snapshot.data ?? [];
                if (bookings.isEmpty) {
                  return const Center(child: Text('Belum ada pesanan grooming.'));
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(AppColors.primary.withOpacity(0.05)),
                        columns: const [
                          DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Pet', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Lay./Lokasi', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Jadwal', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: bookings.map((booking) {
                          return DataRow(cells: [
                            DataCell(Text(booking.customerName)),
                            DataCell(Text('${booking.petName} (${booking.petType})')),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(booking.serviceType),
                                  Text(
                                    booking.isHomeService ? 'Home Service' : 'Bawa ke Petshop',
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                  ),
                                  if (booking.isHomeService && booking.alamatLengkap != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 150,
                                            child: Text(
                                              booking.alamatLengkap!,
                                              style: const TextStyle(fontSize: 9, color: Colors.blueGrey),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ),
                                          if (booking.latitude != null && booking.longitude != null)
                                            IconButton(
                                              icon: const Icon(Icons.map, size: 16, color: Colors.blue),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              tooltip: 'Buka di Google Maps',
                                              onPressed: () {
                                                final url = 'https://www.google.com/maps/search/?api=1&query=${booking.latitude},${booking.longitude}';
                                                _launchURL(url);
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            DataCell(Text('${DateFormat('dd/MM').format(booking.bookingDate)} @ ${booking.timeSlot}')),
                            DataCell(Text(currencyFormat.format(booking.totalPrice))),
                            DataCell(_buildStatusBadge(booking.status)),
                            DataCell(Row(
                              children: [
                                if (booking.status == 'Pending')
                                  IconButton(
                                    icon: const Icon(Icons.check, color: Colors.green),
                                    tooltip: 'Konfirmasi',
                                    onPressed: () => _updateStatus(context, booking.bookingId, 'Confirmed'),
                                  ),
                                if (booking.status == 'Confirmed')
                                  IconButton(
                                    icon: const Icon(Icons.done_all, color: Colors.blue),
                                    tooltip: 'Selesai',
                                    onPressed: () => _updateStatus(context, booking.bookingId, 'Completed'),
                                  ),
                                if (booking.status != 'Cancelled' && booking.status != 'Completed')
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.red),
                                    tooltip: 'Batalkan',
                                    onPressed: () => _updateStatus(context, booking.bookingId, 'Cancelled'),
                                  ),
                              ],
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
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
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _launchURL(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
