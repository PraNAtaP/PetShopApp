import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/services/auth_service.dart';
import 'package:petshopapp/constants/point_constants.dart';
import 'package:petshopapp/providers/cart_provider.dart';
import 'package:petshopapp/providers/grooming_provider.dart';

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
  double _totalHarga = 0;

  final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthService>();
    final cart = context.read<CartProvider>();
    setState(() {
      _currentPoints = auth.currentUser?.poin ?? 0.0;
      _totalHarga = cart.totalPrice;
    });
  }

  double get _discount {
    if (!_usePoints) return 0;
    final rawDiskon = PointConstants.hitungDiskon(_currentPoints);
    return rawDiskon.clamp(0, _totalHarga);
  }

  double get _totalAfterDiscount =>
      (_totalHarga - _discount).clamp(0, double.infinity);

  void _lanjutkanPembayaran() {
    final routeName = widget.category == 'shop'
        ? 'payment-execution'
        : 'grooming-payment-execution';

    context.pushNamed(
      routeName,
      extra: {
        'metodePembayaran': _totalAfterDiscount == 0 ? 'POIN' : _selectedMethod,
        'usePoints': _usePoints,
        'discount': _discount,
      },
    );
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
      subtotal =
          (grooming.selectedPrice * grooming.selectedPets.length).toDouble();
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

                    // ── Total Harga ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.monetization_on_outlined,
                                      color: AppColors.primary),
                                ),
                                const SizedBox(width: 12),
                                const Text('Total Harga',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                              ],
                            ),
                            Text(
                              currencyFormatter.format(_totalHarga),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.primary),
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
                            child: PointConstants.canRedeem(_currentPoints)
                                ? RichText(
                                    text: TextSpan(
                                      style: const TextStyle(fontSize: 12),
                                      children: [
                                        TextSpan(
                                          text:
                                              'Pakai ${PointConstants.hitungPoinTerpakai(_currentPoints).toStringAsFixed(0)} poin ',
                                          style: const TextStyle(
                                              color: Colors.grey),
                                        ),
                                        TextSpan(
                                          text:
                                              '→ hemat ${currencyFormatter.format(PointConstants.hitungDiskon(_currentPoints))}',
                                          style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  )
                                : Text(
                                    'Poin belum cukup (${_currentPoints.toStringAsFixed(0)} / ${PointConstants.minPoinRedeem.toInt()} poin)',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500),
                                  ),
                          ),
                          value: _usePoints,
                          onChanged: PointConstants.canRedeem(_currentPoints)
                          ? (val) {
                              setState(() => _usePoints = val);
                              if (val && _totalAfterDiscount == 0) {
                                _lanjutkanPembayaran();
                              }
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

    return GestureDetector(
      onTap: () {
        setState(() => _selectedMethod = method);
        if (method == 'COD') {
          if (widget.category == 'shop') {
            final cart = context.read<CartProvider>();
            if (!cart.isDelivery) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Untuk pengambilan di tempat dengan Bayar di Tempat, Anda diharuskan membayar DP 50% terlebih dahulu.',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } else if (widget.category == 'grooming') {
            final grooming = context.read<GroomingProvider>();
            if (!grooming.isHomeService) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Untuk layanan di salon dengan Bayar di Tempat, Anda diharuskan membayar DP 50% terlebih dahulu.',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      },
      child: AnimatedContainer(
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
    );
  }
}