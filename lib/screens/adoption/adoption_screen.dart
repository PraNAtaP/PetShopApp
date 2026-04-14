import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/pet_model.dart';
import '../../services/firestore_service.dart';

class AdoptionScreen extends StatelessWidget {
  const AdoptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Adopsi Hewan'),
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
                snapshot.error.toString(),
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            );
          }

          final pets = snapshot.data ?? [];
          
          if (pets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 64, color: AppColors.textLight.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada anabul yang tersedia',
                    style: TextStyle(color: AppColors.textLight, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              final isAvailable = pet.status.toLowerCase() == 'available' || pet.status.toLowerCase() == 'tersedia';

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          pet.fotoUrls.isNotEmpty
                              ? Image.network(
                                  pet.fotoUrls.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    child: const Icon(Icons.broken_image, color: AppColors.textLight),
                                  ),
                                )
                              : Container(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  child: const Icon(Icons.pets, size: 40, color: AppColors.primary),
                                ),
                          if (!isAvailable)
                            Container(
                              color: Colors.black.withValues(alpha: 0.5),
                              alignment: Alignment.center,
                              child: const Text(
                                'Diadopsi',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isAvailable ? AppColors.secondary : AppColors.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isAvailable ? 'Available' : 'Adopted',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              pet.namaHewan,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${pet.jenis} • ${pet.umur}',
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
