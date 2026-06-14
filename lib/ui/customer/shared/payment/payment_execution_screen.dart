import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'package:petshopapp/services/cloudinary_service.dart';
import 'package:petshopapp/constants/point_constants.dart';
import 'package:petshopapp/services/grooming_service.dart';
import 'package:petshopapp/models/order_model.dart';
import 'package:petshopapp/providers/cart_provider.dart';
import 'package:petshopapp/providers/grooming_provider.dart';
import 'package:petshopapp/services/auth_service.dart';

class UniversalPaymentExecutionScreen extends StatefulWidget {
  final String paymentMethod;
  final String category;
  final bool usePoints;
  final double discount;
  final OrderModel? order;
  final List<String>? bookingIds;
  final DateTime? createdAt;
  final bool isHomeService;
  final double totalHarga;

  const UniversalPaymentExecutionScreen({
    super.key,
    required this.paymentMethod,
    required this.category,
    this.usePoints = false,
    this.discount = 0,
    this.order,
    this.bookingIds,
    this.createdAt,
    this.isHomeService = false,
    this.totalHarga = 0,
  });

  @override
  State<UniversalPaymentExecutionScreen> createState() =>
      _UniversalPaymentExecutionScreenState();
}

class _UniversalPaymentExecutionScreenState
    extends State<UniversalPaymentExecutionScreen>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  bool _isSuccess = false;
  XFile? _selectedImage;
  late AnimationController _checkAnimController;
  late Animation<double> _scaleAnimation;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  Timer? _timer;
  int _remainingSeconds = 480; // 8 minutes default
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _checkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _checkAnimController,
      curve: Curves.elasticOut,
    );
    
    _startTimer();
  }

  void _startTimer() {
    final DateTime startTime = widget.order?.createdAt ?? widget.createdAt ?? DateTime.now();
    final int elapsedSeconds = DateTime.now().difference(startTime).inSeconds;
    _remainingSeconds = (480 - elapsedSeconds).clamp(0, 480);

    if (_remainingSeconds <= 0) {
      _handleExpiration();
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _handleExpiration();
        }
      });
    });
  }

  Future<void> _handleExpiration() async {
    if (_isExpired || _isSuccess || _isProcessing) return;
    setState(() {
      _isExpired = true;
    });

    try {
      if (widget.category == 'shop' && widget.order != null) {
        await FirestoreService.instance.updateOrderStatus(widget.order!.orderId, 'Expired');
      } else if (widget.category == 'grooming' && widget.bookingIds != null) {
        for (var id in widget.bookingIds!) {
          await GroomingService.instance.updateBookingStatus(id, 'Expired');
        }
      }
    } catch (e) {
      debugPrint('Failed to update expired status: $e');
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Waktu pembayaran habis. Pesanan dibatalkan.')),
    );
    context.goNamed('home');
  }

  String get _formattedTime {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _checkAnimController.dispose();
    super.dispose();
  }

  double _getBaseAmount() {
    if (widget.category == 'shop' && widget.order != null) {
      return widget.order!.totalHarga;
    } else if (widget.category == 'grooming' && widget.totalHarga > 0) {
      return widget.totalHarga;
    }
    
    // Fallback if providers still needed
    double base;
    if (widget.category == 'shop') {
      base = context.read<CartProvider>().totalPrice;
    } else {
      final provider = context.read<GroomingProvider>();
      base = provider.selectedPrice + provider.shippingFee;
    }
    return base;
  }

  double _getTotalAmount() {
    return (_getBaseAmount() - widget.discount).clamp(0, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Konfirmasi Pembayaran';
    if (widget.paymentMethod == 'QRIS') title = 'Pembayaran QRIS';
    if (widget.paymentMethod == 'Transfer') title = 'Transfer Bank';
    if (widget.paymentMethod == 'COD') title = 'Bayar di Tempat';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isSuccess ? _buildSuccessView() : _buildPaymentView(),
    );
  }

  Widget _buildPaymentView() {
    final total = _getTotalAmount();
    final cart = context.watch<CartProvider>();
    final grooming = context.watch<GroomingProvider>();
    final baseTotal = _getBaseAmount();
    final isDpCoveredByPoints = widget.usePoints && widget.discount >= (baseTotal * 0.5);

    bool isDpRequired = false;
    if (widget.category == 'shop') {
      isDpRequired = widget.paymentMethod == 'COD' && !cart.isDelivery && !isDpCoveredByPoints;
    } else if (widget.category == 'grooming') {
      isDpRequired =
          widget.paymentMethod == 'COD' && !grooming.isHomeService && !isDpCoveredByPoints;
    }

    return Column(
      children: [
        if (!_isSuccess)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: _remainingSeconds < 60 ? Colors.red : Colors.amber.shade700,
            alignment: Alignment.center,
            child: Text(
              'Selesaikan pembayaran dalam $_formattedTime',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Total Pembayaran',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormatter.format(total),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.usePoints && widget.discount > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Hemat ${currencyFormatter.format(widget.discount)} dari poin',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                      if (isDpRequired) ...[
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 8),
                        const Text(
                          'DP yang Harus Dibayar (50%)',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormatter.format(total * 0.5),
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (widget.paymentMethod == 'QRIS') _buildQrisInfo(),
                if (widget.paymentMethod == 'Transfer') _buildBankInfo(),
                if (widget.paymentMethod == 'COD')
                  _buildCodInfo(isDpRequired),
                const SizedBox(height: 24),
                if (widget.paymentMethod != 'COD' &&
                        widget.paymentMethod != 'POIN' ||
                    isDpRequired)
                  _buildUploadSection(),
              ],
            ),
          ),
        ),
        _buildBottomButton(isDpRequired),
      ],
    );
  }

  Widget _buildQrisInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Scan QR Code di bawah ini',
            style: TextStyle(color: AppColors.textLight, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'lib/assets/img/qris_placeholder.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Bunga Aulia Sari',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const Text(
            'NMID: ID1026492250984',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _downloadQrisToGallery(),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Simpan QRIS ke Galeri'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadQrisToGallery() async {
    try {
      final byteData = await rootBundle.load('lib/assets/img/qris_placeholder.png');
      final bytes = byteData.buffer.asUint8List();
      
      // Request permission via gal
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }
      
      await Gal.putImageBytes(bytes);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QRIS berhasil disimpan ke galeri')),
      );
    } on GalException catch (e) {
      debugPrint(e.type.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan QRIS: ${e.type.toString()}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  Widget _buildBankInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Bank', 'SeaBank'),
          const Divider(height: 24),
          _buildInfoRow('No. Rekening', '901309379460', showCopy: true),
          const Divider(height: 24),
          _buildInfoRow('Atas Nama', 'Pranata Putrandana'),
        ],
      ),
    );
  }

  Widget _buildCodInfo(bool isDpRequired) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: Colors.amber, size: 40),
          const SizedBox(height: 12),
          Text(
            isDpRequired
                ? 'Pembayaran DP 50% Diperlukan'
                : 'Konfirmasi Bayar di Tempat',
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            isDpRequired
                ? 'Anda memilih Bayar di Tempat (Ambil/Layanan di Toko). Anda diharuskan membayar DP sebesar 50% terlebih dahulu via Transfer Bank atau QRIS. Harap lakukan pembayaran DP dan unggah bukti pembayarannya di bawah.'
                : 'Anda dapat melakukan pembayaran tunai saat pesanan sampai atau layanan selesai. Admin akan melakukan konfirmasi setelah Anda klik tombol di bawah.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          if (isDpRequired) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'PILIHAN TRANSFER DP',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Bank', 'Seabank'),
                  const SizedBox(height: 4),
                  _buildInfoRow('No. Rekening', '901309379460', showCopy: true),
                  const SizedBox(height: 4),
                  _buildInfoRow('Atas Nama', 'Pranata Putrandana'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'ATAU Scan QRIS',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'lib/assets/img/qris_placeholder.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'UPLOAD BUKTI PEMBAYARAN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_selectedImage!.path),
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 40,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap untuk pilih foto bukti',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(bool isDpRequired) {
    bool canProceed = widget.paymentMethod == 'COD' && !isDpRequired ||
        widget.paymentMethod == 'POIN' ||
        _selectedImage != null;

    String label = widget.paymentMethod == 'POIN'
        ? 'Konfirmasi Pesanan'
        : widget.paymentMethod == 'COD'
            ? (isDpRequired ? 'Upload & Konfirmasi DP' : 'Konfirmasi Pesanan')
            : 'Upload & Kirim';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed:
                !canProceed || _isProcessing ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool showCopy = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Row(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (showCopy) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: value));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No. Rekening berhasil disalin')),
                  );
                },
                child: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Sumber Foto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Kamera',
                  onTap: () => _getImage(ImageSource.camera),
                ),
                _buildSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri',
                  onTap: () => _getImage(ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) setState(() => _selectedImage = picked);
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        imageUrl = await CloudinaryService.uploadImageBytes(
          bytes,
          _selectedImage!.name,
        );
      }

      if (widget.category == 'shop') {
        await _handleShopFinalization(imageUrl);
      } else {
        await _handleGroomingFinalization(imageUrl);
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
        });
        _checkAnimController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Future<void> _handleShopFinalization(String? imageUrl) async {
    if (widget.order == null) throw Exception('Order data is missing');
    
    // Cukup update bukti dan status
    final newStatus = widget.paymentMethod == 'COD'
        ? 'Pending'
        : (imageUrl != null ? 'Pending' : 'Unpaid');

    await FirestoreService.instance.updateOrderFullStatus(
      orderId: widget.order!.orderId,
      statusBayar: newStatus,
    );
    
    if (imageUrl != null) {
      await FirestoreService.instance.updateOrderPaymentProof(widget.order!.orderId, imageUrl);
    }
  }

  Future<void> _handleGroomingFinalization(String? imageUrl) async {
    if (widget.bookingIds == null || widget.bookingIds!.isEmpty) {
      throw Exception('Booking data is missing');
    }

    final newStatus = widget.paymentMethod == 'COD'
        ? 'Pending'
        : (imageUrl != null ? 'Pending' : 'Unpaid');

    for (var id in widget.bookingIds!) {
      await GroomingService.instance.updateBookingStatus(id, newStatus);
      if (imageUrl != null) {
        // Asumsi grooming juga punya field buktiBayarUrl yang mau kita update
        await FirebaseFirestore.instance.collection('grooming_bookings').doc(id).update({
          'buktiBayarUrl': imageUrl,
        });
      }
    }
  }
  
  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pesanan Berhasil!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              widget.paymentMethod == 'COD'
                  ? 'Permintaan Anda telah kami terima.\nSilakan tunggu konfirmasi admin.'
                  : 'Bukti pembayaran telah dikirim.\nAdmin akan segera memverifikasi.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => context.goNamed('home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  'Ke Beranda',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}