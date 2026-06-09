import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/user_model.dart';
import 'package:petshopapp/services/admin_user_service.dart';
import 'package:petshopapp/services/auth_service.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _launchWhatsApp(String phone, String name) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    } else if (!cleanPhone.startsWith('62') && cleanPhone.isNotEmpty) {
      cleanPhone = '62$cleanPhone';
    }

    final message = Uri.encodeComponent('Halo kak $name, saya dari admin Pet Point.');
    final url = Uri.parse('https://wa.me/$cleanPhone?text=$message');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
        );
      }
    }
  }

  void _toggleBlock(UserModel user) async {
    final authService = context.read<AuthService>();
    final adminName = authService.currentUser?.nama ?? 'Admin';
    final isCurrentlyBlocked = user.isBlocked;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCurrentlyBlocked ? 'Buka Blokir Akun?' : 'Blokir Akun?'),
        content: Text(
          isCurrentlyBlocked
              ? 'Apakah Anda yakin ingin membuka blokir akun ${user.nama}?'
              : 'Apakah Anda yakin ingin memblokir akun ${user.nama}? User tidak akan bisa login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyBlocked ? Colors.green : AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(isCurrentlyBlocked ? 'Ya, Buka Blokir' : 'Ya, Blokir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AdminUserService.instance.toggleBlockUser(user, adminName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isCurrentlyBlocked ? 'Blokir dibuka' : 'Akun diblokir'),
              backgroundColor: isCurrentlyBlocked ? Colors.green : AppColors.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  void _showUserDetails(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: user.fotoUrl != null && user.fotoUrl!.isNotEmpty
                      ? NetworkImage(user.fotoUrl!)
                      : null,
                  child: user.fotoUrl == null || user.fotoUrl!.isEmpty
                      ? const Icon(Icons.person, size: 50, color: AppColors.primary)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user.nama,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              if (user.isBlocked)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(12)),
                    child: const Text('DIBLOKIR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              const SizedBox(height: 24),
              _buildDetailRow(Icons.email, 'Email', user.email),
              const Divider(),
              _buildDetailRow(Icons.phone, 'Nomor WA', user.nomorWa ?? '-'),
              const Divider(),
              _buildDetailRow(Icons.location_on, 'Alamat', user.alamat ?? '-'),
              const Divider(),
              _buildDetailRow(Icons.stars, 'Total Poin Saat Ini', user.poin.toStringAsFixed(0)),
              const Divider(),
              _buildDetailRow(
                Icons.calendar_today,
                'Member Sejak',
                user.createdAt != null ? DateFormat('dd MMM yyyy, HH:mm').format(user.createdAt!) : '-',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Tutup', style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Kelola Pelanggan', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari nama, email, atau no WA...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: AdminUserService.instance.getAllCustomersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
                }

                final users = snapshot.data ?? [];
                
                final filteredUsers = users.where((u) {
                  final nameMatch = u.nama.toLowerCase().contains(_searchQuery);
                  final emailMatch = u.email.toLowerCase().contains(_searchQuery);
                  final phoneMatch = (u.nomorWa ?? '').toLowerCase().contains(_searchQuery);
                  return nameMatch || emailMatch || phoneMatch;
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text('Tidak ada pelanggan ditemukan.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () => _showUserDetails(user),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                backgroundImage: user.fotoUrl != null && user.fotoUrl!.isNotEmpty
                                    ? NetworkImage(user.fotoUrl!)
                                    : null,
                                child: user.fotoUrl == null || user.fotoUrl!.isEmpty
                                    ? const Icon(Icons.person, color: AppColors.primary)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            user.nama,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (user.isBlocked)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            margin: const EdgeInsets.only(left: 8),
                                            decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(4)),
                                            child: const Text('BLOKIR', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(user.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                    if (user.nomorWa != null && user.nomorWa!.isNotEmpty)
                                      Text(user.nomorWa!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  ],
                                ),
                              ),
                              
                              // Actions
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (user.nomorWa != null && user.nomorWa!.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.wechat, color: Colors.green),
                                      tooltip: 'Hubungi WA',
                                      onPressed: () => _launchWhatsApp(user.nomorWa!, user.nama),
                                    ),
                                  IconButton(
                                    icon: Icon(
                                      user.isBlocked ? Icons.lock_open : Icons.block,
                                      color: user.isBlocked ? Colors.green : AppColors.error,
                                    ),
                                    tooltip: user.isBlocked ? 'Buka Blokir' : 'Blokir Akun',
                                    onPressed: () => _toggleBlock(user),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
