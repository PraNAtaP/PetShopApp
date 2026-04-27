import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/services/auth_service.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'package:petshopapp/models/user_pet_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:petshopapp/ui/customer/profile/add_edit_pet_screen.dart';

class UserPetsScreen extends StatelessWidget {
  const UserPetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Hewan Peliharaan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(child: Text('Silakan login terlebih dahulu'))
          : StreamBuilder<List<UserPetModel>>(
              stream: FirestoreService.instance.getUserPets(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final pets = snapshot.data ?? [];

                if (pets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum ada hewan terdaftar',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: pets.length,
                  itemBuilder: (context, index) {
                    final pet = pets[index];
                    return _buildPetCard(context, pet);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-edit-pet'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Hewan', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildPetCard(BuildContext context, UserPetModel pet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
            image: pet.imageUrl != null
                ? DecorationImage(image: NetworkImage(pet.imageUrl!), fit: BoxFit.cover)
                : null,
          ),
          child: pet.imageUrl == null
              ? Center(
                  child: pet.type == 'Anjing'
                      ? const FaIcon(FontAwesomeIcons.dog, color: AppColors.primary, size: 24)
                      : const FaIcon(FontAwesomeIcons.cat, color: AppColors.primary, size: 24),
                )
              : null,
        ),
        title: Text(
          pet.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text('${pet.type} • ${pet.breed} • ${pet.gender}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              context.push('/add-edit-pet', extra: pet);
            } else if (value == 'delete') {
              _confirmDelete(context, pet);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, UserPetModel pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Hewan?'),
        content: Text('Apakah Anda yakin ingin menghapus ${pet.name} dari daftar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              await FirestoreService.instance.deleteUserPet(pet.id!);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
