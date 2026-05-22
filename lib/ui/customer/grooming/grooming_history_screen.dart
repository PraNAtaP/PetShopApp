import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/grooming_booking_model.dart';
import 'package:petshopapp/services/auth_service.dart';
import 'package:petshopapp/services/grooming_service.dart';
import 'package:petshopapp/ui/customer/grooming/grooming_tracking_screen.dart';

/// Displays a list of all grooming bookings for the logged-in customer.
class GroomingHistoryScreen extends StatelessWidget {
  const GroomingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Riwayat Grooming',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text('Silakan login terlebih dahulu'))
          : StreamBuilder<List<GroomingBookingModel>>(
              stream: GroomingService.instance.getCustomerBookingsStream(user.uid),
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

                final bookings = snapshot.data ?? [];

                if (bookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wash_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum ada booking grooming',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Booking grooming Anda akan muncul di sini',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: bookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return _buildBookingCard(context, booking, currencyFormat, dateFormat);
                  },
                );
              },
            ),
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    GroomingBookingModel booking,
    NumberFormat formatter,
    DateFormat dateFormat,
  ) {
    final statusColor = _getStatusColor(booking.status);
    final statusLabel = _getStatusLabel(booking.status);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GroomingTrackingScreen(booking: booking),
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
                    child: Icon(Icons.wash, color: statusColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.serviceType,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${booking.petName} (${booking.petType})',
                          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  _buildDetailRow(
                    Icons.calendar_today,
                    dateFormat.format(booking.bookingDate),
                  ),
                  const SizedBox(height: 6),
                  _buildDetailRow(
                    Icons.access_time,
                    booking.timeSlot,
                  ),
                  const SizedBox(height: 6),
                  _buildDetailRow(
                    booking.isHomeService ? Icons.home : Icons.storefront,
                    booking.isHomeService ? 'Home Service' : 'Di Toko',
                  ),
                ],
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.touch_app_outlined, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Ketuk untuk lacak',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                  Text(
                    formatter.format(booking.totalPrice),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textLight),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
      case 'Grooming Selesai':
        return const Color(0xFF2E7D32);
      case 'Confirmed':
      case 'Terkonfirmasi':
      case 'Groomer Ditugaskan':
        return const Color(0xFF1565C0);
      case 'Groomer Dalam Perjalanan':
        return const Color(0xFF0277BD);
      case 'Pending':
      case 'Menunggu Konfirmasi':
        return const Color(0xFFE65100);
      case 'Cancelled':
      case 'Dibatalkan':
        return AppColors.error;
      default:
        return AppColors.textLight;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'Pending':
        return 'Menunggu';
      case 'Confirmed':
        return 'Dikonfirmasi';
      case 'Completed':
        return 'Selesai';
      case 'Cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }
}
