import 'package:flutter/material.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/animal_model.dart';
import 'package:petshopapp/models/user_model.dart';
import 'package:petshopapp/services/adoption_service.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'package:intl/intl.dart';

class AdminAdoptionOrdersView extends StatefulWidget {
  const AdminAdoptionOrdersView({super.key});

  @override
  State<AdminAdoptionOrdersView> createState() => _AdminAdoptionOrdersViewState();
}

class _AdminAdoptionOrdersViewState extends State<AdminAdoptionOrdersView> {
  final AdoptionService _adoptionService = AdoptionService();
  final FirestoreService _firestoreService = FirestoreService.instance;

  Future<void> _handleAction(BuildContext context, AnimalModel animal, bool isAccept) async {
    final actionName = isAccept ? 'terima' : 'tolak';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi ${isAccept ? 'Penerimaan' : 'Penolakan'}'),
        content: Text('Apakah Anda yakin ingin meng-$actionName pesanan adopsi untuk ${animal.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isAccept ? Colors.green : AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(isAccept ? 'Terima' : 'Tolak'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (isAccept) {
          await _adoptionService.markAsAdopted(animal.id);
        } else {
          await _adoptionService.cancelAdoption(animal.id);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pesanan berhasil di-$actionName')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Terjadi kesalahan: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AnimalModel>>(
      stream: _adoptionService.getAnimalsByStatus('booked'),
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
              'Belum ada pesanan adopsi.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
              columns: const [
                DataColumn(label: Text('Hewan', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Pelanggan', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Jadwal Jemput', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: animals.map((animal) {
                // Fetch customer details based on bookedBy
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              animal.imageUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(width: 40, height: 40, color: Colors.grey.shade300, child: const Icon(Icons.pets, size: 20)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(animal.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text('${animal.type} • ${animal.breed}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      animal.bookedBy != null
                          ? FutureBuilder<UserModel?>(
                              future: _firestoreService.getUserProfile(animal.bookedBy!),
                              builder: (context, userSnapshot) {
                                if (userSnapshot.connectionState == ConnectionState.waiting) {
                                  return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
                                }
                                final userName = userSnapshot.data?.nama ?? 'Unknown Customer';
                                return Text(userName);
                              },
                            )
                          : const Text('-', style: TextStyle(color: Colors.grey)),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (animal.pickupDate != null)
                            Text(DateFormat('dd MMM yyyy').format(animal.pickupDate!), style: const TextStyle(fontWeight: FontWeight.w500)),
                          if (animal.pickupTime != null)
                            Text(animal.pickupTime!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          if (animal.pickupDate == null && animal.pickupTime == null)
                            const Text('-', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                            tooltip: 'Terima & Tandai Diadopsi',
                            onPressed: () => _handleAction(context, animal, true),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                            tooltip: 'Tolak Pesanan',
                            onPressed: () => _handleAction(context, animal, false),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
