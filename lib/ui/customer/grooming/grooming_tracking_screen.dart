import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/grooming_booking_model.dart';
import 'package:petshopapp/services/grooming_service.dart';
import 'package:petshopapp/ui/customer/order/order_status_helper.dart';

/// Displays real-time grooming booking tracking with a visual stepper.
class GroomingTrackingScreen extends StatelessWidget {
  final GroomingBookingModel booking;

  const GroomingTrackingScreen({super.key, required this.booking});

  static const List<TrackingStep> _homeServiceSteps = [
    TrackingStep(
      icon: Icons.hourglass_top_rounded,
      label: 'Menunggu Konfirmasi',
      description: 'Admin sedang mengecek pembayaran Anda',
    ),
    TrackingStep(
      icon: Icons.person_search_outlined,
      label: 'Groomer Ditugaskan',
      description: 'Groomer sudah dijadwalkan untuk Anda',
    ),
    TrackingStep(
      icon: Icons.directions_car_outlined,
      label: 'Groomer Dalam Perjalanan',
      description: 'Groomer sedang menuju lokasi Anda',
    ),
    TrackingStep(
      icon: Icons.check_circle_outline,
      label: 'Grooming Selesai',
      description: 'Grooming telah selesai, terima kasih!',
    ),
  ];

  static const List<TrackingStep> _inStoreSteps = [
    TrackingStep(
      icon: Icons.hourglass_top_rounded,
      label: 'Menunggu Konfirmasi',
      description: 'Admin sedang mengecek pembayaran Anda',
    ),
    TrackingStep(
      icon: Icons.check_circle_outline,
      label: 'Terkonfirmasi',
      description: 'Silakan datang sesuai jadwal yang dipilih',
    ),
    TrackingStep(
      icon: Icons.stars_rounded,
      label: 'Grooming Selesai',
      description: 'Grooming telah selesai, terima kasih!',
    ),
  ];

  int _getCurrentStep(String status, bool isHomeService) {
    if (isHomeService) {
      switch (status) {
        case 'Pending':
        case 'Menunggu Konfirmasi':
          return 0;
        case 'Confirmed':
        case 'Groomer Ditugaskan':
          return 1;
        case 'Groomer Dalam Perjalanan':
          return 2;
        case 'Completed':
        case 'Grooming Selesai':
          return 3;
        default:
          return 0;
      }
    } else {
      switch (status) {
        case 'Pending':
        case 'Menunggu Konfirmasi':
          return 0;
        case 'Confirmed':
        case 'Terkonfirmasi':
          return 1;
        case 'Completed':
        case 'Grooming Selesai':
          return 2;
        default:
          return 0;
      }
    }
  }

  bool _canCancel(String status) {
    // Can cancel before groomer is on the way or completed
    return status == 'Pending' ||
        status == 'Menunggu Konfirmasi' ||
        status == 'Confirmed' ||
        status == 'Groomer Ditugaskan' ||
        status == 'Terkonfirmasi';
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('grooming_bookings')
          .doc(booking.bookingId)
          .snapshots(),
      builder: (context, snapshot) {
        final liveData = snapshot.data?.data() as Map<String, dynamic>?;
        final status = liveData?['status'] ?? booking.status;
        final cancelRequest = liveData?['cancel_request'] == true;
        final isCancelled = status == 'Cancelled' || status == 'Dibatalkan';
        final isHomeService = booking.isHomeService;

        final steps = isHomeService ? _homeServiceSteps : _inStoreSteps;
        final currentStep = _getCurrentStep(status, isHomeService);

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text(
              'Tracking Grooming',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                if (isCancelled) const CancelledBanner(),
                if (cancelRequest && !isCancelled) const CancelRequestBanner(),

                // Booking Info Card
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
                            'Detail Booking',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isHomeService
                                  ? Colors.blue.shade50
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isHomeService ? '🏠 Home Service' : '📍 Di Toko',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isHomeService
                                    ? Colors.blue.shade700
                                    : Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Hewan', '${booking.petName} (${booking.petType})'),
                      _buildInfoRow('Layanan', booking.serviceType),
                      _buildInfoRow('Jadwal', dateFormat.format(booking.bookingDate)),
                      _buildInfoRow('Jam', booking.timeSlot),
                      _buildInfoRow('Pembayaran', booking.metodePembayaran),
                      if (isHomeService && booking.alamatLengkap != null) ...[
                        const Divider(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                booking.alamatLengkap!,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(
                            currencyFormat.format(booking.totalPrice),
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

                // Stepper Card
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
                      Text(
                        isHomeService ? 'Status Kedatangan' : 'Status Booking',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      StatusStepper(
                        steps: steps,
                        currentStep: currentStep,
                        isCancelled: isCancelled,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Cancel Button
                if (_canCancel(status) && !cancelRequest && !isCancelled)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(context),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Batalkan Booking'),
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
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    final isNonCod = booking.metodePembayaran != 'COD';

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
        title: const Text('Batalkan Booking?'),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan booking grooming ini? Pembatalan akan ditinjau oleh Admin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tidak', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await GroomingService.instance.requestCancelBooking(
                bookingId: booking.bookingId,
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
        title: const Text('Batalkan Booking'),
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
              await GroomingService.instance.requestCancelBooking(
                bookingId: booking.bookingId,
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
