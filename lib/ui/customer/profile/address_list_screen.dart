import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/user_address_model.dart';
import 'package:petshopapp/services/auth_service.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'package:petshopapp/ui/customer/profile/add_address_screen.dart';

class AddressListScreen extends StatelessWidget {
  final bool isSelectionMode;

  const AddressListScreen({super.key, this.isSelectionMode = false});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Buku Alamat')),
        body: const Center(child: Text('Harap login terlebih dahulu')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isSelectionMode ? 'Pilih Alamat' : 'Buku Alamat'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<UserAddressModel>>(
        stream: FirestoreService.instance.getUserAddressesStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          final addresses = snapshot.data ?? [];

          if (addresses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.location_city_rounded,
                          size: 60,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Buku Alamat Kosong',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Kamu belum menyimpan alamat apapun. Tambahkan alamat sekarang untuk mempermudah checkout pesananmu!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddAddressScreen()),
                          );
                        },
                        icon: const Icon(Icons.add_location_alt, size: 22),
                        label: const Text('Tambah Alamat Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              return _buildAddressCard(context, user.uid, address);
            },
          );
        },
      ),
      floatingActionButton: StreamBuilder<List<UserAddressModel>>(
        stream: FirestoreService.instance.getUserAddressesStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddAddressScreen()),
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Alamat'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, String uid, UserAddressModel address) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: address.isPrimary ? AppColors.primary : Colors.grey.shade300, width: address.isPrimary ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isSelectionMode) {
            Navigator.pop(context, address);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(address.label.toLowerCase() == 'kantor' ? Icons.work : Icons.home, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    address.label,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (address.isPrimary) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Utama', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                address.fullAddress,
                style: const TextStyle(color: AppColors.textDark, height: 1.4),
              ),
              if (address.latitude != null && address.longitude != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.check_circle, size: 14, color: Colors.green),
                    SizedBox(width: 4),
                    Text('Titik GPS tersemat', style: TextStyle(color: Colors.green, fontSize: 12)),
                  ],
                )
              ],
              if (!isSelectionMode) ...[
                const SizedBox(height: 16),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!address.isPrimary)
                      TextButton(
                        onPressed: () {
                          FirestoreService.instance.setPrimaryAddress(uid, address.id);
                        },
                        child: const Text('Jadikan Utama', style: TextStyle(color: AppColors.primary)),
                      ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AddAddressScreen(existingAddress: address)),
                        );
                      },
                      child: const Text('Edit', style: TextStyle(color: AppColors.textLight)),
                    ),
                    TextButton(
                      onPressed: () {
                        _showDeleteConfirm(context, uid, address.id);
                      },
                      child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, String uid, String addressId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Alamat?'),
        content: const Text('Alamat ini akan dihapus dari buku alamat Anda.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              FirestoreService.instance.deleteUserAddress(uid, addressId);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
