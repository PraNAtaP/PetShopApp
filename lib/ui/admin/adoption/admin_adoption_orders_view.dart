import 'package:flutter/material.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/animal_model.dart';
import 'package:petshopapp/models/user_model.dart';
import 'package:petshopapp/services/adoption_service.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petshopapp/services/fcm_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminAdoptionOrdersView extends StatefulWidget {
  const AdminAdoptionOrdersView({super.key});

  @override
  State<AdminAdoptionOrdersView> createState() =>
      _AdminAdoptionOrdersViewState();
}

class _AdminAdoptionOrdersViewState extends State<AdminAdoptionOrdersView> {
  final AdoptionService _adoptionService = AdoptionService();
  final FirestoreService _firestoreService = FirestoreService.instance;
  String _searchQuery = '';
  late Stream<List<AnimalModel>> _animalsStream;

  @override
  void initState() {
    super.initState();
    _animalsStream = _adoptionService.getAnimalsByStatuses(const [
      'booked',
      'cancel_requested',
    ]);
  }

  Future<void> _handleAction(
    BuildContext context,
    AnimalModel animal,
    bool isAccept,
  ) async {
    final isCancelRequest = animal.status == 'cancel_requested';

    String actionName;
    String confirmTitle;
    String confirmContent;

    if (isCancelRequest) {
      actionName = isAccept ? 'menyetujui pembatalan' : 'menolak pembatalan';
      confirmTitle = isAccept ? 'Setujui Pembatalan' : 'Tolak Pembatalan';
      confirmContent = isAccept
          ? 'Apakah Anda yakin ingin menyetujui pengajuan pembatalan adopsi untuk ${animal.name}? Hewan akan tersedia kembali untuk diadopsi.'
          : 'Apakah Anda yakin ingin menolak pengajuan pembatalan adopsi untuk ${animal.name}? Status hewan tetap booked.';
    } else {
      actionName = isAccept ? 'terima' : 'tolak';
      confirmTitle = isAccept
          ? 'Konfirmasi Penerimaan'
          : 'Konfirmasi Penolakan';
      confirmContent = isAccept
          ? 'Apakah Anda yakin ingin menerima pesanan adopsi untuk ${animal.name}?'
          : 'Apakah Anda yakin ingin menolak pesanan adopsi untuk ${animal.name}?';
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(confirmTitle),
        content: Text(confirmContent),
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
            child: Text(isAccept ? 'Setuju' : 'Tolak'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (isCancelRequest) {
          final customerId = animal.bookedBy;
          if (isAccept) {
            await _adoptionService.cancelAdoption(animal.id);
            if (customerId != null) {
              try {
                final customer = await _firestoreService.getUserProfile(
                  customerId,
                );
                final fcmToken = customer?.fcmToken;
                if (fcmToken != null && fcmToken.isNotEmpty) {
                  await FCMService.instance.sendNotification(
                    targetFCMToken: fcmToken,
                    title: 'Pembatalan Adopsi Disetujui 🐾',
                    body:
                        'Pengajuan pembatalan adopsi untuk ${animal.name} telah disetujui oleh Admin.',
                  );
                }

                await FirebaseFirestore.instance.collection('notifications').add({
                  'userId': customerId,
                  'title': 'Pembatalan Adopsi Disetujui 🐾',
                  'body':
                      'Pengajuan pembatalan adopsi untuk ${animal.name} telah disetujui oleh Admin.',
                  'type': 'adoption_cancellation',
                  'createdAt': FieldValue.serverTimestamp(),
                  'read': false,
                });
              } catch (notifErr) {
                debugPrint(
                  'Failed to send cancellation notification: $notifErr',
                );
              }
            }
          } else {
            await _adoptionService.denyCancelAdoption(animal.id);
          }
        } else {
          if (isAccept) {
            await _adoptionService.markAsAdopted(animal.id);
          } else {
            await _adoptionService.cancelAdoption(animal.id);
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pesanan berhasil di-$actionName')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0).copyWith(bottom: 0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Cari nama, jenis, atau ras hewan...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val.toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<List<AnimalModel>>(
            stream: _animalsStream,
            builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
        }

        var animals = snapshot.data ?? [];

        if (_searchQuery.isNotEmpty) {
          animals = animals.where((a) {
            return a.name.toLowerCase().contains(_searchQuery) ||
                a.type.toLowerCase().contains(_searchQuery) ||
                a.breed.toLowerCase().contains(_searchQuery);
          }).toList();
        }

        if (animals.isEmpty && _searchQuery.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada pesanan adopsi.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (animals.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Tidak ada pesanan adopsi yang sesuai.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: DataTable(
                        dataRowMinHeight: 75,
                        dataRowMaxHeight: 100,
                        headingRowColor: WidgetStateProperty.all(
                          Colors.grey.shade50,
                        ),
                        dividerThickness: 1,
                        horizontalMargin: 24,
                        columnSpacing: 24,
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Hewan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Pelanggan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Jadwal Jemput',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Aksi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                        rows: animals.map((animal) {
                          final isCancelRequest =
                              animal.status == 'cancel_requested';
                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: animal.imageUrl,
                                        width: 48,
                                        memCacheWidth: 200,
                                        maxWidthDiskCache: 400,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          width: 48,
                                          height: 48,
                                          color: Colors.grey.shade100,
                                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          width: 48,
                                          height: 48,
                                          color: Colors.grey.shade100,
                                          child: const Icon(
                                            Icons.pets,
                                            size: 24,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              animal.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                            if (isCancelRequest) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: Colors.red.shade200,
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Minta Batal',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${animal.type} • ${animal.breed}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        if (isCancelRequest &&
                                            animal.cancelReason != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              'Alasan: ${animal.cancelReason}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.redAccent,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                animal.bookedBy != null
                                    ? FutureBuilder<UserModel?>(
                                        future: _firestoreService
                                            .getUserProfile(animal.bookedBy!),
                                        builder: (context, userSnapshot) {
                                          if (userSnapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            );
                                          }
                                          final userName =
                                              userSnapshot.data?.nama ??
                                              'Unknown Customer';
                                          return Text(
                                            userName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textDark,
                                            ),
                                          );
                                        },
                                      )
                                    : const Text(
                                        '-',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (animal.pickupDate != null)
                                      Text(
                                        DateFormat(
                                          'dd MMM yyyy',
                                        ).format(animal.pickupDate!),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    if (animal.pickupTime != null)
                                      Text(
                                        animal.pickupTime!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    if (animal.pickupDate == null &&
                                        animal.pickupTime == null)
                                      const Text(
                                        '-',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.green,
                                        size: 22,
                                      ),
                                      tooltip: isCancelRequest
                                          ? 'Setujui Pembatalan'
                                          : 'Terima & Tandai Diadopsi',
                                      onPressed: () =>
                                          _handleAction(context, animal, true),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.cancel_outlined,
                                        color: AppColors.error,
                                        size: 22,
                                      ),
                                      tooltip: isCancelRequest
                                          ? 'Tolak Pembatalan'
                                          : 'Tolak Pesanan',
                                      onPressed: () =>
                                          _handleAction(context, animal, false),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          ),
            ],
          ),
        );
      },
          ),
        ),
      ],
    );
  }
}
