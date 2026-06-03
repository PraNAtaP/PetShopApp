import 'package:flutter/material.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/animal_model.dart';
import 'package:petshopapp/models/user_model.dart';
import 'package:petshopapp/services/adoption_service.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAdoptionHistoryView extends StatefulWidget {
  const AdminAdoptionHistoryView({super.key});

  @override
  State<AdminAdoptionHistoryView> createState() => _AdminAdoptionHistoryViewState();
}

class _AdminAdoptionHistoryViewState extends State<AdminAdoptionHistoryView> {
  final AdoptionService _adoptionService = AdoptionService();
  final FirestoreService _firestoreService = FirestoreService.instance;
  final Map<String, String> _userNames = {};
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;
  late Stream<List<AnimalModel>> _animalsStream;

  @override
  void initState() {
    super.initState();
    _animalsStream = _adoptionService.getAnimalsByStatus('adopted');
    _fetchAllUserNames();
  }

  Future<void> _fetchAllUserNames() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      if (mounted) {
        setState(() {
          for (var doc in snapshot.docs) {
            _userNames[doc.id] = doc.data()['nama'] ?? 'Unknown User';
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching user names: $e');
    }
  }

  String _getSyncUserName(String? uid) {
    if (uid == null) return '';
    return _userNames[uid] ?? '';
  }

  String _formatWhatsAppNumber(String phone) {
    String clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('0')) {
      clean = '62${clean.substring(1)}';
    }
    return clean;
  }

  Future<void> _launchWhatsApp(String phone, String animalName) async {
    final cleanPhone = _formatWhatsAppNumber(phone);
    final message = Uri.encodeComponent(
      'Halo, saya dari Pet Point ingin menanyakan kabar mengenai adopsi $animalName. Bagaimana keadaannya sekarang? 🐾',
    );
    final url = 'https://wa.me/$cleanPhone?text=$message';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka WhatsApp: $e')),
        );
      }
    }
  }

  void _showAdopterDetails(BuildContext context, UserModel user, AnimalModel animal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.person, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text(
              'Detail Pengadopsi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(Icons.account_circle, 'Nama Lengkap', user.nama),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.email_outlined, 'Alamat Email', user.email),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.phone_android,
                'Nomor WhatsApp / HP',
                user.nomorWa ?? 'Tidak mencantumkan nomor',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.location_on_outlined,
                'Alamat Rumah',
                user.alamat ?? 'Tidak mencantumkan alamat',
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Mengadopsi: ${animal.name} (${animal.type} • ${animal.breed})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
          ),
          if (user.nomorWa != null && user.nomorWa!.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _launchWhatsApp(user.nomorWa!, animal.name);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.chat, size: 16),
              label: const Text('Hubungi via WA'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari nama hewan atau pengadopsi...',
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
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: () async {
                    final picked = await _showDateRangePopup(context, _selectedDateRange);
                    if (picked != null) {
                      setState(() => _selectedDateRange = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedDateRange == null 
                                ? 'Filter Tanggal' 
                                : '${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_selectedDateRange != null)
                          GestureDetector(
                            onTap: () => setState(() => _selectedDateRange = null),
                            child: const Icon(Icons.close, size: 16),
                          )
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
                animals = animals.where((animal) {
                  final animalNameMatch = animal.name.toLowerCase().contains(_searchQuery);
                  final adopterName = _getSyncUserName(animal.bookedBy).toLowerCase();
                  final adopterNameMatch = adopterName.contains(_searchQuery);
                  return animalNameMatch || adopterNameMatch;
                }).toList();
              }

              if (_selectedDateRange != null) {
                animals = animals.where((animal) {
                  if (animal.pickupDate == null) return false;
                  final pickup = DateTime(animal.pickupDate!.year, animal.pickupDate!.month, animal.pickupDate!.day);
                  final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
                  final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day);
                  return pickup.isAtSameMomentAs(start) || pickup.isAtSameMomentAs(end) || (pickup.isAfter(start) && pickup.isBefore(end));
                }).toList();
              }

              Widget content;
              if (animals.isEmpty) {
                content = const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Belum ada riwayat adopsi hewan.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                );
              } else {
                content = Padding(
                  padding: const EdgeInsets.all(24),
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
                                      'Pengadopsi',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Jadwal Penjemputan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Aksi / Kontak',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: animals.map((animal) {
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
                                                width: 48,
                                                height: 48,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (context, error, stackTrace) =>
                                                        Container(
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
                                                Text(
                                                  animal.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: AppColors.textDark,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${animal.type} • ${animal.breed}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
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
                                                  final user = userSnapshot.data;
                                                  if (user == null) {
                                                    return const Text(
                                                      'Pelanggan Tidak Ditemukan',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey,
                                                      ),
                                                    );
                                                  }
                                                  return Text(
                                                    user.nama,
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
                                                    );
                                                  }
                                                  final user = userSnapshot.data;
                                                  if (user == null) return const SizedBox();
                                                  return Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.info_outline,
                                                          color: AppColors.primary,
                                                          size: 22,
                                                        ),
                                                        tooltip: 'Lihat Info Detail',
                                                        onPressed: () =>
                                                            _showAdopterDetails(
                                                              context,
                                                              user,
                                                              animal,
                                                            ),
                                                      ),
                                                      if (user.nomorWa != null &&
                                                          user.nomorWa!.isNotEmpty) ...[
                                                        const SizedBox(width: 8),
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.chat,
                                                            color: Colors.green,
                                                            size: 22,
                                                          ),
                                                          tooltip: 'Hubungi via WhatsApp',
                                                          onPressed: () =>
                                                              _launchWhatsApp(
                                                                user.nomorWa!,
                                                                animal.name,
                                                              ),
                                                        ),
                                                      ],
                                                    ],
                                                  );
                                                },
                                              )
                                            : const SizedBox(),
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
                );
              }

              return content;
            },
          ),
        ),
      ],
    );
  }
  
  Future<DateTimeRange?> _showDateRangePopup(BuildContext context, DateTimeRange? initialDateRange) async {
    DateTime? start = initialDateRange?.start;
    DateTime? end = initialDateRange?.end;
    
    return await showDialog<DateTimeRange>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Pilih Rentang Tanggal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tanggal Mulai', style: TextStyle(fontSize: 14)),
                    subtitle: Text(start != null ? DateFormat('dd MMM yyyy').format(start!) : 'Pilih Tanggal', style: TextStyle(color: start != null ? AppColors.primary : Colors.grey, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.calendar_today, size: 20),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: start ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          start = picked;
                          if (end != null && start!.isAfter(end!)) end = null;
                        });
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tanggal Akhir', style: TextStyle(fontSize: 14)),
                    subtitle: Text(end != null ? DateFormat('dd MMM yyyy').format(end!) : 'Pilih Tanggal', style: TextStyle(color: end != null ? AppColors.primary : Colors.grey, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.calendar_today, size: 20),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: end ?? start ?? DateTime.now(),
                        firstDate: start ?? DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => end = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: start != null && end != null
                      ? () => Navigator.pop(context, DateTimeRange(start: start!, end: end!))
                      : null,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text('Terapkan'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
