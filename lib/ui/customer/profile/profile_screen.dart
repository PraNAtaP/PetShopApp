import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/services/auth_service.dart';
import 'package:petshopapp/ui/customer/order/order_history_screen.dart';
import 'package:petshopapp/ui/customer/grooming/grooming_history_screen.dart';
import 'package:petshopapp/ui/customer/profile/address_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petshopapp/constants/point_constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser;

        return Scaffold(
          backgroundColor: AppColors.background.withValues(alpha: 0.2),
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {},
              ),
            ],
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Top Section (Blue Background)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 40, top: 20),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.cardBackground,
                            backgroundImage: user?.fotoUrl != null && user!.fotoUrl!.isNotEmpty
                                ? NetworkImage(user.fotoUrl!)
                                : null,
                            child: user?.fotoUrl == null || user!.fotoUrl!.isEmpty
                                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                                : null,
                          ),
                          IgnorePointer(
                            child: SizedBox(
                              width: 160,
                              height: 160,
                              child: Image.asset(
                                'lib/assets/img/cute_cat_frame.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.nama ?? 'Pengguna',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'ID: ${user?.uid.substring(0, 8).toUpperCase() ?? '-'}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  PointConstants.getTier(user?.maxPoin ?? 0),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _showTierInfo(context),
                                  child: const Icon(Icons.info_outline, color: Colors.white, size: 18),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.textDark,
                          minimumSize: const Size(140, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.edit_note, size: 20),
                        label: const Text('Edit Profil'),
                        onPressed: () {
                          context.pushNamed('edit-profile');
                        },
                      ),
                    ],
                  ),
                ),

                // Content Section
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Informasi Dasar card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'INFORMASI DASAR',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textLight,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow(
                                icon: Icons.email_outlined,
                                title: 'Email',
                                subtitle: user?.email ?? '-',
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(
                                icon: Icons.phone_outlined,
                                title: 'No. Telepon',
                                subtitle: user?.nomorWa ?? 'Belum diatur',
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const AddressListScreen()),
                                    );
                                  },
                                  icon: const Icon(Icons.book_outlined, size: 18),
                                  label: const Text('Buku Alamat'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(color: AppColors.primary),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Aktivitas Saya
                        const Text(
                          'AKTIVITAS SAYA',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildActionTile(
                                icon: Icons.receipt_long_outlined,
                                title: 'Riwayat Pesanan',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const OrderHistoryScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(height: 1, indent: 56),
                              _buildActionTile(
                                icon: Icons.wash_outlined,
                                title: 'Riwayat Grooming',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const GroomingHistoryScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(height: 1, indent: 56),
                              _buildActionTile(
                                icon: Icons.pets_outlined,
                                title: 'Kelola Hewan Peliharaan',
                                onTap: () {
                                  context.push('/user-pets');
                                },
                              ),
                              const Divider(height: 1, indent: 56),
                              _buildActionTile(
                                icon: Icons.history_outlined,
                                title: 'Riwayat Adopsi',
                                onTap: () {
                                  context.push('/adoption-history');
                                },
                              ),
                              const Divider(height: 1, indent: 56),
                              _buildActionTile(
                                icon: Icons.stars_outlined,
                                title: 'Poin Saya',
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${user?.poin ?? 0}',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  context.pushNamed('points');
                                },
                              ),
                              const Divider(height: 1, indent: 56),
                              _buildActionTile(
                                icon: Icons.notifications_none_outlined,
                                title: 'Notifikasi',
                                trailing: StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('notifications')
                                      .where('userId', isEqualTo: user?.uid)
                                      .where('read', isEqualTo: false)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                                      return Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                                onTap: () {
                                  context.push('/notifications');
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Logout Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          icon: const Icon(Icons.logout, size: 20),
                          label: const Text('Keluar / Logout'),
                          onPressed: () async {
                            final authService = context.read<AuthService>();
                            await authService.logout();
                          },
                        ),

                        const SizedBox(height: 32),

                        // Footer links
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Bantuan', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            const SizedBox(width: 8),
                            Text('•', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            const SizedBox(width: 8),
                            Text('Kebijakan Privasi', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            const SizedBox(width: 8),
                            Text('•', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            const SizedBox(width: 8),
                            Text('Syarat & Ketentuan', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 140),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({required IconData icon, required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textDark),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) trailing,
          if (trailing != null) const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }

  void _showTierInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informasi Tier Membership',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tier ditentukan dari total poin yang pernah kamu kumpulkan seumur hidup. Poin yang terpakai tidak akan menurunkan tier kamu.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              _buildTierItem('💎 Diamond Member', '5.000+ Poin', '2x Poin Belanja, Min Tukar 100 poin'),
              _buildTierItem('🛡️ Platinum Member', '2.500 - 4.999 Poin', '1.8x Poin Belanja, Min Tukar 100 poin'),
              _buildTierItem('🥇 Gold Member', '1.000 - 2.499 Poin', '1.5x Poin Belanja, Min Tukar 200 poin'),
              _buildTierItem('🥈 Silver Member', '300 - 999 Poin', '1.2x Poin Belanja, Min Tukar 200 poin'),
              _buildTierItem('🥉 Bronze Member', '0 - 299 Poin', '1x Poin Belanja, Min Tukar 300 poin'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tutup', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTierItem(String title, String poin, String benefit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(poin, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Benefit: $benefit',
            style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
