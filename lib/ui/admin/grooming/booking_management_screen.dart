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

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manajemen Booking Grooming',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  Text('Kelola jadwal dan konfirmasi pembayaran di sini.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {}, 
                icon: const Icon(Icons.refresh),
                label: const Text('Segarkan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const Text('DEBUG: Jika baris ini muncul, berarti UI dasar ter-render.', style: TextStyle(color: Colors.red, fontSize: 10)),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<GroomingBookingModel>>(
              stream: GroomingService.instance.getAdminBookingsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.red, strokeWidth: 5));
                }
                
                if (snapshot.hasError) {
                  return Container(
                    width: double.infinity,
                    color: Colors.red.shade50,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bug_report, color: Colors.red, size: 60),
                        const SizedBox(height: 16),
                        const Text('Firestore Stream Error!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        const SizedBox(height: 12),
                        SelectableText(snapshot.error.toString(), textAlign: TextAlign.center),
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
                        Icon(Icons.search_off, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Data Kosong (Empty List)', style: TextStyle(color: Colors.grey, fontSize: 18)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) => _buildBookingRowCard(context, bookings[index], currencyFormat),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingRowCard(BuildContext context, GroomingBookingModel booking, NumberFormat currency) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Status Strip
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: _getStatusColor(booking.status),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
            const SizedBox(width: 16),
            
            // Customer & Pet Info
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(booking.petType == 'Kucing' ? Icons.pets : Icons.pets, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('${booking.petName} (${booking.petType})', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const VerticalDivider(width: 1, indent: 15, endIndent: 15),

            // Service & Schedule
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.serviceType, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          '${DateFormat('dd MMM').format(booking.bookingDate)} • ${booking.timeSlot}',
                          style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Text(
                      booking.isHomeService ? 'Home Service' : 'Bawa ke Toko',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ),

            const VerticalDivider(width: 1, indent: 15, endIndent: 15),

            // Payment
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(currency.format(booking.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (booking.buktiBayarUrl != null)
                      TextButton.icon(
                        onPressed: () => _showProofDialog(context, booking.buktiBayarUrl!),
                        icon: const Icon(Icons.image_search, size: 16),
                        label: const Text('Bukti', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      )
                    else
                      Text(
                        booking.metodePembayaran == 'COD' ? '💰 COD' : '-',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),

            const VerticalDivider(width: 1, indent: 15, endIndent: 15),

            // Status Badge & Actions
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildStatusBadge(booking.status),
                    const SizedBox(width: 12),
                    _buildActionButtons(context, booking),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed': return Colors.blue;
      case 'Completed': return Colors.green;
      case 'Cancelled': return Colors.red;
      default: return Colors.orange;
    }
  }

  Widget _buildActionButtons(BuildContext context, GroomingBookingModel booking) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (booking.status == 'Pending')
          _circleActionBtn(
            icon: Icons.check,
            color: Colors.green,
            tooltip: 'Terima Pesanan',
            onPressed: () => _updateStatus(context, booking.bookingId, 'Confirmed'),
          ),
        if (booking.status == 'Confirmed')
          _circleActionBtn(
            icon: Icons.done_all,
            color: Colors.blue,
            tooltip: 'Selesaikan',
            onPressed: () => _updateStatus(context, booking.bookingId, 'Completed'),
          ),
        const SizedBox(width: 4),
        if (booking.status != 'Cancelled' && booking.status != 'Completed')
          _circleActionBtn(
            icon: Icons.close,
            color: Colors.red,
            tooltip: 'Tolak/Batal',
            onPressed: () => _updateStatus(context, booking.bookingId, 'Cancelled'),
          ),
      ],
    );
  }

  Widget _circleActionBtn({required IconData icon, required Color color, required String tooltip, required VoidCallback onPressed}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
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

  void _showProofDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Bukti Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 500, maxWidth: 500),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () => _launchURL(url),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Buka di Tab Baru'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
