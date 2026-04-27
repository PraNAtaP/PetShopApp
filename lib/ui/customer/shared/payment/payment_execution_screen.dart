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

class UniversalPaymentExecutionScreen extends StatefulWidget {
  final String paymentMethod; // 'QRIS', 'Transfer', 'COD'
  final String category; // 'shop', 'grooming'

  const UniversalPaymentExecutionScreen({
    super.key,
    required this.paymentMethod,
    required this.category,
  });

  @override
  State<UniversalPaymentExecutionScreen> createState() => _UniversalPaymentExecutionScreenState();
}

class _UniversalPaymentExecutionScreenState extends State<UniversalPaymentExecutionScreen> with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  bool _isSuccess = false;
  File? _selectedImage;
  late AnimationController _checkAnimController;
  late Animation<double> _scaleAnimation;

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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

  double _getTotalAmount() {
    if (widget.category == 'shop') {
      return context.read<CartProvider>().totalPrice;
    } else {
      final provider = context.read<GroomingProvider>();
      return provider.selectedPrice * provider.selectedPets.length;
    }
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

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Total Amount Card
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
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (widget.paymentMethod == 'QRIS') _buildQrisInfo(),
                if (widget.paymentMethod == 'Transfer') _buildBankInfo(),
                if (widget.paymentMethod == 'COD') _buildCodInfo(),

                const SizedBox(height: 24),

                // Proof Upload Section (Only for QRIS and Transfer)
                if (widget.paymentMethod != 'COD') _buildUploadSection(),
              ],
            ),
          ),
        ),

        // Bottom Action Button
        _buildBottomButton(),
      ],
    );
  }

  Widget _buildQrisInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          const Text('Scan QR Code di bawah ini', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset('lib/assets/img/qris_placeholder.png', width: 200, height: 200, fit: BoxFit.contain),
          ),
          const SizedBox(height: 12),
          const Text('NMID: ID882910291', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Bank', 'BCA'),
          const Divider(height: 24),
          _buildInfoRow('No. Rekening', '12345678'),
          const Divider(height: 24),
          _buildInfoRow('Atas Nama', 'Pet Point App'),
        ],
      ),
    );
  }

  Widget _buildCodInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: const Column(
        children: [
          Icon(Icons.info_outline, color: Colors.amber, size: 40),
          SizedBox(height: 12),
          Text(
            'Konfirmasi Bayar di Tempat',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Anda dapat melakukan pembayaran tunai saat pesanan sampai atau layanan selesai. Admin akan melakukan konfirmasi setelah Anda klik tombol di bawah.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('UPLOAD BUKTI PEMBAYARAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight)),
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
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Tap untuk pilih foto bukti', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    bool canProceed = widget.paymentMethod == 'COD' || _selectedImage != null;
    String label = widget.paymentMethod == 'COD' ? 'Konfirmasi Pesanan' : 'Upload & Kirim';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))]),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: !canProceed || _isProcessing ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: _isProcessing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Sumber Foto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
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

  Widget _buildSourceOption({required IconData icon, required String label, required VoidCallback onTap}) {
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
              color: AppColors.primary.withOpacity(0.1),
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
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await ImgbbService.uploadImage(_selectedImage!);
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
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
      items: cart.items.map((c) => OrderItemModel(
        productId: c.productId,
        nama: c.nama,
        jumlah: c.jumlah,
        hargaSatuan: c.hargaSatuan,
      )).toList(),
      totalHarga: cart.totalPrice,
      buktiBayarUrl: imageUrl,
      statusBayar: widget.paymentMethod == 'COD' ? 'Pending' : (imageUrl != null ? 'Pending' : 'Unpaid'),
      statusPengiriman: 'Menunggu',
      metodePengambilan: 'Ambil di Toko',
      metodePembayaran: widget.paymentMethod,
    );

    await FirestoreService.instance.createOrder(order);
    await cart.clearCart();
  }

  Future<void> _handleGroomingFinalization(String? imageUrl) async {
    final provider = context.read<GroomingProvider>();
    final auth = context.read<AuthService>();
    final user = auth.currentUser;

    if (user != null) {
      // In grooming provider, we updated confirmBooking to take buktiBayarUrl and metodePembayaran
      await provider.confirmBooking(user.uid, user.nama, buktiBayarUrl: imageUrl, metodePembayaran: widget.paymentMethod);
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
              child: const Icon(Icons.check_circle, color: Colors.green, size: 80),
            ),
            const SizedBox(height: 24),
            const Text('Pesanan Berhasil!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Ke Beranda', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
