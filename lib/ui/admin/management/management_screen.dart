import 'package:flutter/material.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'package:petshopapp/models/pet_model.dart';
import 'package:petshopapp/core/theme/app_colors.dart';

class ManagementScreen extends StatelessWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: StreamBuilder<List<PetModel>>(
        stream: FirestoreService.instance.getAllPets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }

          final pets = snapshot.data ?? [];

          if (pets.isEmpty) {
            return const Center(child: Text('No pets found in inventory.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: DataTable(
                headingRowColor: WidgetStateProperty.resolveWith((states) => AppColors.primary.withValues(alpha: 0.1)),
                columns: const [
                  DataColumn(label: Text('ID / Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Breed', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Age', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: pets.map((pet) {
                  return DataRow(
                    cells: [
                      DataCell(Text(pet.namaHewan)),
                      DataCell(Text(pet.jenis)),
                      DataCell(Text(pet.umur)),
                      DataCell(
                        Chip(
                          label: Text(pet.status, style: const TextStyle(fontSize: 12)),
                          backgroundColor: pet.status.toLowerCase() == 'available' 
                            ? AppColors.secondary 
                            : Colors.grey.shade300,
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                              onPressed: () {
                                // TODO: Edit Pet logic
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
                              onPressed: () {
                                // TODO: Delete Pet logic
                              },
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
      ),
    );
  }
}
