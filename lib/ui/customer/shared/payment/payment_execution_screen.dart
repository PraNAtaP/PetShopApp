import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/order_model.dart';
import 'package:petshopapp/providers/cart_provider.dart';
import 'package:petshopapp/providers/grooming_provider.dart';
import 'package:petshopapp/services/auth_service.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'package:petshopapp/services/imgbb_service.dart';
import 'package:petshopapp/constants/point_constants.dart';

class UniversalPaymentExecutionScreen extends StatefulWidget {
  final String paymentMethod;
  final String category;
  final bool usePoints;
  final double discount;

  const UniversalPaymentExecutionScreen({
    super.key,
    required this.paymentMethod,
    required this.category,
    this.usePoints = false,
    this.discount = 0,
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
  }

  @override
  void dispose() {
    _checkAnimController.dispose();
    super.dispose();
  }

  double _getBaseAmount() {
    double base;
    if (widget.category == 'shop') {
      base = context.read<CartProvider>().totalPrice;
    } else {
      final provider = context.read<GroomingProvider>();
      base = (provider.selectedPrice * provider.selectedPets.length) +
          provider.shippingFee;
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
        ],
      ),
    );
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
          _buildInfoRow('No. Rekening', '901309379460'),
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bank',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('BCA',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('No. Rekening',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('12345678',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Atas Nama',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('Pet Point App',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
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
        imageUrl = await ImgbbService.uploadImageBytes(
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
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.uid ?? '';

    final order = OrderModel(
      orderId: '',
      customerId: uid,
      items: cart.items
          .map(
            (c) => OrderItemModel(
              productId: c.productId,
              nama: c.nama,
              jumlah: c.jumlah,
              hargaSatuan: c.hargaSatuan,
            ),
          )
          .toList(),
      totalHarga: cart.totalPrice,
      diskonPoin: widget.usePoints ? widget.discount : 0.0,
      buktiBayarUrl: imageUrl,
      statusBayar: (cart.totalPrice - (widget.usePoints ? widget.discount : 0.0)) <= 0
          ? 'Lunas'
          : (widget.paymentMethod == 'COD'
              ? 'Pending'
              : (imageUrl != null ? 'Pending' : 'Unpaid')),
      statusPengiriman: 'Menunggu',
      metodePengambilan: cart.isDelivery ? 'Kirim ke Alamat' : 'Ambil di Toko',
      metodePembayaran: widget.paymentMethod,
      alamatLengkap: cart.isDelivery ? cart.alamatLengkap : null,
      latitude: cart.isDelivery ? cart.latitude : null,
      longitude: cart.isDelivery ? cart.longitude : null,
    );

    await FirestoreService.instance.createOrder(order);

    if (widget.usePoints && widget.discount > 0) {
      final double poinTerpakai = (widget.discount / PointConstants.diskonPerRedeem) * PointConstants.poinPerRedeem;
      if (poinTerpakai > 0) {
        final error = await auth.kurangiPoin(
          jumlahPoin: poinTerpakai,
          keterangan: 'Penukaran poin — diskon Rp${widget.discount.toInt()}',
        );
        if (error != null) debugPrint('Gagal mengurangi poin: $error');
      }
    }



    await cart.clearCart();

  }

  Future<void> _handleGroomingFinalization(String? imageUrl) async {
    final provider = context.read<GroomingProvider>();
    final auth = context.read<AuthService>();
    final user = auth.currentUser;

    if (widget.usePoints && widget.discount > 0) {
      final double poinTerpakai = (widget.discount /
              PointConstants.diskonPerRedeem) *
          PointConstants.poinPerRedeem;
      if (poinTerpakai > 0) {
        await auth.kurangiPoin(
          jumlahPoin: poinTerpakai,
          keterangan: 'Penukaran poin — diskon Rp${widget.discount.toInt()}',
        );
      }
    }

    if (user != null) {
      await provider.confirmBooking(
        user.uid,
        user.nama,
        buktiBayarUrl: imageUrl,
        metodePembayaran: widget.paymentMethod,
        diskonPoin: widget.usePoints ? widget.discount : 0.0,
      );
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