import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/providers/grooming_provider.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:petshopapp/services/auth_service.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'package:petshopapp/models/user_pet_model.dart';

class GroomingServiceScreen extends StatefulWidget {
  const GroomingServiceScreen({super.key});

  @override
  State<GroomingServiceScreen> createState() => _GroomingServiceScreenState();
}

class _GroomingServiceScreenState extends State<GroomingServiceScreen> {
  final TextEditingController _alamatController = TextEditingController();
  bool _isHomeService = false;
  final List<UserPetModel> _selectedPets = [];
  final List<Map<String, dynamic>> _services = [
    {
      'name': 'Mandi Dasar',
      'price': 50000.0,
      'icon': Icons.shower,
    },
    {
      'name': 'Mandi Kutu/Jamur',
      'price': 80000.0,
      'icon': Icons.bug_report,
    },
    {
      'name': 'Potong Kuku',
      'price': 20000.0,
      'icon': Icons.cut,
    },
    {
      'name': 'Potong Bulu',
      'price': 60000.0,
      'icon': Icons.content_cut,
    },
    {
      'name': 'Bersih Telinga',
      'price': 25000.0,
      'icon': Icons.hearing,
    },
    {
      'name': 'Paket Lengkap',
      'price': 150000.0,
      'icon': Icons.stars,
    },
  ];

  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void dispose() {
    _alamatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GroomingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Layanan Grooming'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Hewan Kesayangan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Consumer<AuthService>(
              builder: (context, auth, _) {
                if (auth.currentUser == null) return const SizedBox();
                return StreamBuilder<List<UserPetModel>>(
                  stream: FirestoreService.instance.getUserPets(auth.currentUser!.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final pets = snapshot.data ?? [];

                    if (pets.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Kamu belum mendaftarkan hewan peliharaan.',
                              style: TextStyle(fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/user-pets'),
                              icon: const Icon(Icons.add),
                              label: const Text('Daftarkan Hewan Sekarang'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Horizontal Selection (Quick Pick)
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: pets.length + 1,
                            itemBuilder: (context, index) {
                              if (index == pets.length) {
                                return GestureDetector(
                                  onTap: () => context.push('/user-pets'),
                                  child: Container(
                                    width: 80,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundColor: Colors.grey.shade100,
                                          child: const Icon(Icons.add, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text('Tambah', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final pet = pets[index];
                              final isSelected = _selectedPets.any((p) => p.id == pet.id);
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedPets.removeWhere((p) => p.id == pet.id);
                                    } else {
                                      _selectedPets.add(pet);
                                    }
                                  });
                                },
                                child: Container(
                                  width: 80,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: isSelected ? AppColors.primary : Colors.grey.shade200,
                                        backgroundImage: pet.imageUrl != null ? NetworkImage(pet.imageUrl!) : null,
                                        child: pet.imageUrl == null
                                            ? FaIcon(
                                                pet.type == 'Anjing' ? FontAwesomeIcons.dog : FontAwesomeIcons.cat,
                                                color: isSelected ? Colors.white : Colors.grey,
                                                size: 24,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        pet.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? AppColors.primary : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Selected Pet Info Card (Premium replacement for dropdown)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _selectedPets.isEmpty
                              ? Container(
                                  key: const ValueKey('no-selection'),
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Silakan pilih satu atau lebih hewan di atas',
                                      style: TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                  ),
                                )
                              : Container(
                                  key: ValueKey(_selectedPets.length),
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        padding: const EdgeInsets.all(10),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.pets, color: Colors.white, size: 24),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _selectedPets.length == 1 
                                                ? _selectedPets.first.name 
                                                : '${_selectedPets.length} Hewan Terpilih',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _selectedPets.length == 1
                                                ? '${_selectedPets.first.type} • ${_selectedPets.first.breed}'
                                                : _selectedPets.map((p) => p.name).join(', '),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const Divider(height: 30, thickness: 1),
            const Text(
              'Lokasi Layanan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSelectableCard(
                  label: 'Bawa ke Petshop',
                  icon: Icons.storefront,
                  isSelected: !_isHomeService,
                  onTap: () {
                    setState(() => _isHomeService = false);
                    _alamatController.clear();
                  },
                ),
                const SizedBox(width: 12),
                _buildSelectableCard(
                  label: 'Home Service',
                  icon: Icons.home_work_outlined,
                  isSelected: _isHomeService,
                  onTap: () => setState(() => _isHomeService = true),
                ),
              ],
            ),
            if (_isHomeService) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => context.push('/grooming-location'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          provider.alamatLengkap.isEmpty
                              ? 'Ketuk untuk pilih lokasi di peta'
                              : provider.alamatLengkap,
                          style: TextStyle(
                            color: provider.alamatLengkap.isEmpty
                                ? Colors.grey.shade600
                                : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
            const Divider(height: 40, thickness: 1),
            const Text(
              'Pilih Paket Grooming',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: _services.length,
              itemBuilder: (context, index) {
                final service = _services[index];
                final isSelected = provider.selectedServices.contains(service['name']);

                return GestureDetector(
                  onTap: () {
                    provider.toggleService(service['name'], service['price']);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey.shade300,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(service['icon'], color: isSelected ? AppColors.primary : Colors.grey.shade600, size: 32),
                        const SizedBox(height: 12),
                        Text(
                          service['name'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isSelected ? AppColors.primary : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currencyFormat.format(service['price']),
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedPets.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Harap pilih minimal satu hewan peliharaan')),
                    );
                    return;
                  }
                  if (provider.selectedServices.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pilih minimal satu layanan grooming terlebih dahulu')),
                    );
                    return;
                  }
                  if (_isHomeService && provider.alamatLengkap.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Harap pilih lokasi pada peta untuk Home Service')),
                    );
                    return;
                  }

                  provider.updatePetsInfo(_selectedPets);
                  // Location is already updated via Map Picker
                  context.push('/grooming-schedule');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: Text(
                  _selectedPets.length > 1
                    ? 'Lanjutkan (${_selectedPets.length} Hewan)'
                    : 'Lanjutkan Pilih Jadwal',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectableCard({
    required String label,
    required dynamic icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              icon is IconData
                  ? Icon(
                      icon,
                      color: isSelected ? AppColors.primary : Colors.grey.shade600,
                      size: 32,
                    )
                  : FaIcon(
                      icon,
                      color: isSelected ? AppColors.primary : Colors.grey.shade600,
                      size: 28, // FA icons are sometimes larger
                    ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
