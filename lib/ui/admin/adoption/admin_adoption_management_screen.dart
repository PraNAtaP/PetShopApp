import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/animal_model.dart';
import 'package:petshopapp/services/adoption_service.dart';
import 'package:petshopapp/ui/admin/adoption/admin_add_animal_screen.dart';
import 'package:petshopapp/ui/admin/adoption/admin_edit_animal_screen.dart';

import 'package:petshopapp/ui/admin/adoption/admin_adoption_orders_view.dart';
import 'package:petshopapp/ui/admin/adoption/admin_adoption_history_view.dart';

class AdminAdoptionManagementScreen extends StatefulWidget {
  const AdminAdoptionManagementScreen({super.key});

  @override
  State<AdminAdoptionManagementScreen> createState() => _AdminAdoptionManagementScreenState();
}

class _AdminAdoptionManagementScreenState extends State<AdminAdoptionManagementScreen> {
  final AdoptionService _adoptionService = AdoptionService();

  Future<void> _deleteAnimal(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Hewan?'),
        content: const Text('Apakah Anda yakin ingin menghapus data hewan ini dari katalog adopsi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adoptionService.deleteAnimal(id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hewan berhasil dihapus.')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('Kelola Adopsi', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary,
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Katalog Hewan'),
              Tab(text: 'Pesanan Adopsi'),
              Tab(text: 'Riwayat Adopsi'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Katalog Hewan
            Scaffold(
              backgroundColor: Colors.transparent,
              body: StreamBuilder<List<AnimalModel>>(
                stream: _adoptionService.getAnimals(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
                  }

                  final animals = snapshot.data ?? [];

                  if (animals.isEmpty) {
                    return const Center(
                      child: Text(
                        'Belum ada hewan di katalog adopsi.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: animals.length,
                    itemBuilder: (context, index) {
                      final animal = animals[index];
                      return _buildAnimalTile(context, animal);
                    },
                  );
                },
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminAddAnimalScreen()),
                  );
                },
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
            
            // Tab 2: Pesanan Adopsi
            const AdminAdoptionOrdersView(),

            // Tab 3: Riwayat Adopsi
            const AdminAdoptionHistoryView(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalTile(BuildContext context, AnimalModel animal) {
    Color statusColor;
    switch (animal.status) {
      case 'available':
        statusColor = Colors.green;
        break;
      case 'booked':
        statusColor = Colors.orange;
        break;
      case 'adopted':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: animal.imageUrl,
                width: 80,
                memCacheWidth: 200,
                maxWidthDiskCache: 400,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.pets, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${animal.type} • ${animal.breed} • ${animal.age}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  // Tappable status badge
                  GestureDetector(
                    onTap: () => _showStatusPicker(context, animal),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            animal.status.toUpperCase(),
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.swap_horiz, size: 14, color: statusColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AdminEditAnimalScreen(animal: animal)),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => _deleteAnimal(context, animal.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusPicker(BuildContext context, AnimalModel animal) {
    final statuses = ['available', 'booked', 'adopted'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Ubah Status — ${animal.name}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                ...statuses.map((status) {
                  final isSelected = animal.status == status;
                  Color color;
                  IconData icon;
                  switch (status) {
                    case 'available':
                      color = Colors.green;
                      icon = Icons.check_circle_outline;
                      break;
                    case 'booked':
                      color = Colors.orange;
                      icon = Icons.schedule;
                      break;
                    case 'adopted':
                      color = Colors.grey;
                      icon = Icons.home_outlined;
                      break;
                    default:
                      color = Colors.blue;
                      icon = Icons.info_outline;
                  }

                  return ListTile(
                    leading: Icon(icon, color: color),
                    title: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? color : Colors.black87,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check, color: color)
                        : null,
                    onTap: () async {
                      Navigator.pop(context);
                      if (isSelected) return;
                      try {
                        final updateData = <String, dynamic>{'status': status};
                        // Clear booking info if resetting to available
                        if (status == 'available') {
                          updateData['bookedBy'] = null;
                          updateData['pickupDate'] = null;
                          updateData['pickupTime'] = null;
                        }
                        await _adoptionService.updateAnimal(animal.id, updateData);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Status ${animal.name} diubah ke ${status.toUpperCase()}')),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal mengubah status: $e')),
                        );
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
