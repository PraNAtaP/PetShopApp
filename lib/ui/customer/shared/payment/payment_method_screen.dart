import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/services/auth_service.dart';
import 'package:petshopapp/constants/point_constants.dart';
import 'package:petshopapp/providers/cart_provider.dart';
import 'package:petshopapp/providers/grooming_provider.dart';
import 'package:petshopapp/models/order_model.dart';
import 'package:petshopapp/services/firestore_service.dart';

class UniversalPaymentMethodScreen extends StatefulWidget {
  final String category; // 'shop' or 'grooming'

  const UniversalPaymentMethodScreen({super.key, required this.category});

  @override
  State<UniversalPaymentMethodScreen> createState() =>
      _UniversalPaymentMethodScreenState();
}

class _UniversalPaymentMethodScreenState
    extends State<UniversalPaymentMethodScreen> {
  String? _selectedMethod;
  bool _usePoints = false;
  double _currentPoints = 0;
  double _maxPoints = 0;
  double _totalHarga = 0;
  bool _isProcessing = false;

  final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthService>();
    setState(() {
      _currentPoints = auth.currentUser?.poin ?? 0.0;
      _maxPoints = auth.currentUser?.maxPoin ?? 0.0;

      if (widget.category == 'shop') {
      _totalHarga = context.read<CartProvider>().totalPrice;
    } else {
      final grooming = context.read<GroomingProvider>();
      _totalHarga = (grooming.selectedPrice * grooming.selectedPets.length) +
          grooming.shippingFee;
    }
  });
}

  double get _discount {
    if (!_usePoints) return 0;
    return _maxDiscountForOrder;
  }

  double get _maxDiscountForOrder =>
      PointConstants.hitungDiskon(_currentPoints, _maxPoints).clamp(0, _totalHarga * 0.5).toDouble();

  double get _pointsUsedForOrder =>
      (_maxDiscountForOrder / PointConstants.diskonPerRedeem) * PointConstants.poinPerRedeem;

  double get _totalAfterDiscount =>
      (_totalHarga - _discount).clamp(0, double.infinity);

  void _lanjutkanPembayaran() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin membuat pesanan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Belum'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _prosesBuatPesanan();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Sudah', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _prosesBuatPesanan() async {
    setState(() => _isProcessing = true);
    try {
      final selectedMethod = _totalAfterDiscount == 0 ? 'POIN' : _selectedMethod!;
      final auth = context.read<AuthService>();
      final uid = auth.currentUser?.uid ?? '';

      double poinTerpakai = 0.0;
      if (_usePoints && _discount > 0) {
        poinTerpakai = _pointsUsedForOrder;
        if ((auth.currentUser?.poin ?? 0) < poinTerpakai) {
          throw Exception('Poin tidak mencukupi atau tidak valid!');
        }
      }

      if (widget.category == 'shop') {
        final cart = context.read<CartProvider>();
        
        // Buat pesanan dengan status 'Unpaid' (Belum Dibayar)
        // Jika pembayarannya POIN penuh atau COD tanpa DP, kita bisa langsung set statusnya
        bool isDpCoveredByPoints = _usePoints && (_maxDiscountForOrder >= (_totalHarga * 0.5));
        bool isDpRequired = selectedMethod == 'COD' && !cart.isDelivery && !isDpCoveredByPoints;
        
        String initialStatus = 'Unpaid';
        if (selectedMethod == 'POIN') {
          initialStatus = 'Lunas';
        } else if (selectedMethod == 'COD' && !isDpRequired) {
          initialStatus = 'Pending';
        }

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
          diskonPoin: _usePoints ? _discount : 0.0,
          buktiBayarUrl: null,
          statusBayar: initialStatus,
          statusPengiriman: 'Menunggu',
          metodePengambilan: cart.isDelivery ? 'Kirim ke Alamat' : 'Ambil di Toko',
          metodePembayaran: selectedMethod,
          alamatLengkap: cart.isDelivery ? cart.alamatLengkap : null,
          latitude: cart.isDelivery ? cart.latitude : null,
          longitude: cart.isDelivery ? cart.longitude : null,
          createdAt: DateTime.now(),
        );

        // Langsung simpan ke database dan ambil orderId-nya
        final orderId = await FirestoreService.instance.createOrder(order);
        final createdOrder = order.copyWith(orderId: orderId);

        // Potong poin dan bersihkan keranjang di sini
        if (poinTerpakai > 0) {
          final error = await auth.kurangiPoin(
            jumlahPoin: poinTerpakai,
            keterangan: 'Penukaran poin — diskon Rp${_discount.toInt()}',
          );
          if (error != null) throw Exception(error);
        }
        await cart.clearCart();

        if (mounted) {
          setState(() => _isProcessing = false);
          // Arahkan ke layar pembayaran (countdown 8 menit)
          context.pushNamed(
            'payment-execution',
            extra: {
              'order': createdOrder,
              'metodePembayaran': selectedMethod,
              'usePoints': _usePoints,
              'discount': _discount,
            },
          );
        }
      } else {
        // Untuk Grooming
        final provider = context.read<GroomingProvider>();
        
        bool isDpCoveredByPoints = _usePoints && (_maxDiscountForOrder >= (_totalHarga * 0.5));
        bool isDpRequired = selectedMethod == 'COD' && !provider.isHomeService && !isDpCoveredByPoints;
        
        String initialStatus = 'Unpaid';
        if (selectedMethod == 'POIN') {
          initialStatus = 'Lunas & Confirmed';
        } else if (selectedMethod == 'COD' && !isDpRequired) {
          initialStatus = 'Pending';
        }

        // Simpan booking dengan status awal
        final bookingIds = await provider.confirmBooking(
          uid,
          auth.currentUser?.nama ?? 'User',
          buktiBayarUrl: null,
          metodePembayaran: selectedMethod,
          diskonPoin: _usePoints ? _discount : 0.0,
          statusOverride: initialStatus,
        );

        if (poinTerpakai > 0) {
          final error = await auth.kurangiPoin(
            jumlahPoin: poinTerpakai,
            keterangan: 'Penukaran poin — diskon Rp${_discount.toInt()}',
          );
          if (error != null) throw Exception(error);
        }

        if (mounted) {
          setState(() => _isProcessing = false);
          context.pushNamed(
            'grooming-payment-execution',
            extra: {
              'bookingIds': bookingIds,
              'metodePembayaran': selectedMethod,
              'usePoints': _usePoints,
              'discount': _discount,
              'createdAt': DateTime.now(),
              'isHomeService': provider.isHomeService,
              'totalHarga': _totalHarga,
            },
          );
          // reset provider
          provider.reset();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    double subtotal = 0;
    double shippingFee = 0;
    double totalPrice = 0;

    if (widget.category == 'shop') {
      final cart = context.watch<CartProvider>();
      subtotal = cart.subtotal;
      shippingFee = cart.shippingFee;
      totalPrice = cart.totalPrice;
    } else if (widget.category == 'grooming') {
      final grooming = context.watch<GroomingProvider>();
      subtotal = grooming.selectedPrice;
      shippingFee = grooming.shippingFee;
      totalPrice = subtotal + shippingFee;
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Metode Pembayaran',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // ✅ FIX: SafeArea membungkus seluruh body
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.account_balance_wallet,
                      color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Pembayaran untuk ${widget.category == 'shop' ? 'Perlengkapan' : 'Grooming'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            // ── Konten scrollable ─────────────────────────────────────────
            // ✅ FIX: Expanded hanya membungkus SingleChildScrollView
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                child: Column(
                  children: [
                    // ── Rincian Pembayaran ──────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'Rincian Pembayaran',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.category == 'shop'
                                      ? 'Subtotal Pesanan'
                                      : 'Subtotal Layanan',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textLight,
                                  ),
                                ),
                                Text(
                                  currencyFormatter.format(subtotal),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.category == 'shop'
                                      ? 'Biaya Pengiriman'
                                      : 'Biaya Layanan',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textLight,
                                  ),
                                ),
                                Text(
                                  shippingFee == 0.0
                                      ? 'Gratis'
                                      : currencyFormatter.format(shippingFee),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: shippingFee == 0.0
                                        ? Colors.green
                                        : AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24, thickness: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Pembayaran',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  currencyFormatter.format(totalPrice),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Gunakan Poin ───────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _usePoints
                                ? AppColors.primary
                                : Colors.grey.shade200,
                            width: _usePoints ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.stars_rounded,
                                    color: Colors.amber, size: 18),
                              ),
                              const SizedBox(width: 10),
                              const Text('Gunakan Poin',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: PointConstants.canRedeem(_currentPoints, _maxPoints)
                                ? RichText(
                                    text: TextSpan(
                                      style: const TextStyle(fontSize: 12),
                                      children: [
                                        TextSpan(
                                          text:
                                              'Pakai ${_pointsUsedForOrder.toStringAsFixed(0)} poin ',
                                          style: const TextStyle(
                                              color: Colors.grey),
                                        ),
                                        TextSpan(
                                          text:
                                              '→ hemat ${currencyFormatter.format(_maxDiscountForOrder)}',
                                          style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  )
                                : Text(
                                    'Poin belum cukup (${_currentPoints.toStringAsFixed(0)} / ${PointConstants.getMinPoinRedeem(_maxPoints).toInt()} poin)',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500),
                                  ),
                          ),
                          value: _usePoints,
                          onChanged: PointConstants.canRedeem(_currentPoints, _maxPoints)
                          ? (val) {
                              setState(() => _usePoints = val);
                            }
                          : null,
                        ),
                      ),
                    ),

                    // ── Baris diskon (muncul jika pakai poin) ─────────
                    if (_usePoints && _discount > 0) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total setelah diskon',
                                  style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                currencyFormatter.format(_totalAfterDiscount),
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // ── Payment options ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildPaymentOption(
                            method: 'QRIS',
                            title: 'QRIS',
                            subtitle:
                                'Bayar via QR Code & Upload Bukti Pembayaran.',
                            icon: Icons.qr_code_2,
                            color: const Color(0xFF1A73E8),
                          ),
                          const SizedBox(height: 16),
                          _buildPaymentOption(
                            method: 'Transfer',
                            title: 'Transfer Bank',
                            subtitle:
                                'Transfer ke rekening & Upload Bukti Pembayaran.',
                            icon: Icons.account_balance,
                            color: const Color(0xFF34A853),
                          ),
                          const SizedBox(height: 16),
                          _buildPaymentOption(
                            method: 'COD',
                            title: 'Bayar di Tempat',
                            subtitle:
                                'Bayar tunai di lokasi. Tanpa upload bukti.',
                            icon: Icons.payments_outlined,
                            color: const Color(0xFFFBBC05),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ── Tombol sticky di bawah ────────────────────────────────────
            // ✅ FIX: Langsung child Column, SafeArea sudah di luar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _selectedMethod == null && _totalAfterDiscount != 0
                      ? null
                      : () => _lanjutkanPembayaran(), 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Lanjutkan',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String method,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedMethod == method;
    bool showWarning = false;
    String warningText = '';
    final bool isDpCoveredByPoints = _usePoints && (_maxDiscountForOrder >= (_totalHarga * 0.5));

    if (isSelected && method == 'COD' && !isDpCoveredByPoints) {
      if (widget.category == 'shop') {
        final cart = context.read<CartProvider>();
        if (!cart.isDelivery) {
          showWarning = true;
          warningText = 'Untuk pengambilan di tempat dengan Bayar di Tempat, Anda diharuskan membayar DP 50% terlebih dahulu.';
        }
      } else if (widget.category == 'grooming') {
        final grooming = context.read<GroomingProvider>();
        if (!grooming.isHomeService) {
          showWarning = true;
          warningText = 'Untuk layanan di salon dengan Bayar di Tempat, Anda diharuskan membayar DP 50% terlebih dahulu.';
        }
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() => _selectedMethod = method);
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color:
                          isSelected ? AppColors.primary : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color:
                      isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
      if (showWarning)
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade800, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  warningText,
                  style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }
}