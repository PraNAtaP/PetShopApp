import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import '../main/base_screen.dart';
import 'widgets/home_funfact_slider.dart';
import 'widgets/home_product_slider.dart';

/// Dashboard utama Pet Point.
/// Menampilkan greeting, quick-actions, promo banner, dan tips hewan.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final firstName = user.nama.split(' ').first;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // ── Custom Header (Lonceng diganti Keranjang & Navigasi ke /cart) ──
          SliverToBoxAdapter(child: _buildHeader(context, firstName, user.poin.toInt())),

          // ── Tips & Fun Facts Slider ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: const HomeFunFactSlider(),
            ),
          ),

          // ── Quick Actions ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Layanan Kami',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildServiceCard(
                        context,
                        icon: Icons.content_cut,
                        label: 'Grooming',
                        gradient: const [Color(0xFF003F87), Color(0xFF1565C0)],
                        onTap: () => context.push('/grooming-service'),
                      ),
                      const SizedBox(width: 12),
                      _buildServiceCard(
                        context,
                        icon: Icons.pets,
                        label: 'Adopsi',
                        gradient: const [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                        onTap: () => context.push('/adoption'),
                      ),
                      const SizedBox(width: 12),
                      _buildServiceCard(
                        context,
                        icon: Icons.shopping_bag_outlined,
                        label: 'Shop',
                        gradient: const [Color(0xFFE65100), Color(0xFFFF9800)],
                        // Pindah ke tab Shop di BaseScreen (Index 1)
                        onTap: () {
                          BaseScreen.of(context)?.setTab(1);
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildServiceCard(
                        context,
                        icon: Icons.local_hospital_outlined,
                        label: 'Konsultasi',
                        gradient: const [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
                        // Mengirimkan template text sebagai extra data ke halaman chat
                        onTap: () {
                          const templateMessage = 
                              'hai sahabat pet point! anabul kamu kenapa? Silahkan isi form nya ya agar kami dapat menganalisa kondisi terkini anabul kamu:\n'
                              'Nama anabul:\n'
                              'Jenis anabul:\n'
                              'Kondisi anabul:';
                          context.push('/chat', extra: {'autoSendText': templateMessage});
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Produk Terbaru ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Produk Terbaru',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            BaseScreen.of(context)?.setTab(1);
                          },
                          child: const Text(
                            'Lihat Selengkapnya',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const HomeProductSlider(),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 140)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Header Section
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context, String firstName, int poin) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003F87), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Logo + Cart (Ubah dari Lonceng ke Keranjang)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.pets, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Pet Point',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    // Perubahan Ikon ke Keranjang Belanja
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                    // Navigasi ke Halaman CartScreen
                    onPressed: () => context.push('/cart'),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Greeting
            Text(
              'Halo, $firstName! 👋',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Temukan layanan terbaik untuk anabul kamu.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 20),

            // Points card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.stars_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pet Points',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          '$poin Poin',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Tukar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.white,
                      ),
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

  // ═══════════════════════════════════════════════════════════════════
  // Service Card
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildServiceCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }


}