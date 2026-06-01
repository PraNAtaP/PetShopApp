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
import 'package:petshopapp/models/user_address_model.dart';
import 'package:petshopapp/ui/customer/profile/address_list_screen.dart';
import 'package:petshopapp/models/grooming_package_model.dart';

class GroomingServiceScreen extends StatefulWidget {
  const GroomingServiceScreen({super.key});

  @override
  State<GroomingServiceScreen> createState() => _GroomingServiceScreenState();
}

class _GroomingServiceScreenState extends State<GroomingServiceScreen> {
  final TextEditingController _alamatController = TextEditingController();
  bool _isHomeService = false;
  final List<UserPetModel> _selectedPets = [];
  Stream<List<UserPetModel>>? _petsStream;
  String? _currentUserId;
  // Services data is now fetched from GroomingPackageModel

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Hewan Kesayangan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Consumer<AuthService>(
              builder: (context, auth, _) {
                if (auth.currentUser == null) return const SizedBox();

                if (_currentUserId != auth.currentUser!.uid) {
                  _currentUserId = auth.currentUser!.uid;
                  _petsStream = FirestoreService.instance.getUserPets(
                    _currentUserId!,
                  );
                }

                return StreamBuilder<List<UserPetModel>>(
                  stream: _petsStream,
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
                                          child: const Icon(
                                            Icons.add,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Tambah',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final pet = pets[index];
                              final isSelected = _selectedPets.any(
                                (p) => p.id == pet.id,
                              );
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedPets.removeWhere(
                                        (p) => p.id == pet.id,
                                      );
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
                                        backgroundColor: isSelected
                                            ? AppColors.primary
                                            : Colors.grey.shade200,
                                        backgroundImage: pet.imageUrl != null
                                            ? NetworkImage(pet.imageUrl!)
                                            : null,
                                        child: pet.imageUrl == null
                                            ? FaIcon(
                                                pet.type == 'Anjing'
                                                    ? FontAwesomeIcons.dog
                                                    : FontAwesomeIcons.cat,
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.grey,
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
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const Text(
              'Lokasi Layanan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
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
                onTap: () async {
                  final UserAddressModel? result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddressListScreen(isSelectionMode: true)),
                  );
                  if (result != null) {
                    provider.updateLocationInfo(
                      isHome: true,
                      alamat: result.fullAddress,
                      lat: result.latitude,
                      lng: result.longitude,
                    );
                  }
                },
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedPets.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Text('Silakan pilih minimal 1 hewan di atas terlebih dahulu.', style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedPets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final pet = _selectedPets[index];
                  final selectedPackageName = provider.petPackages[pet.id];
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selectedPackageName != null ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selectedPackageName != null ? AppColors.primary : Colors.grey.shade300,
                        width: selectedPackageName != null ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: pet.imageUrl != null ? NetworkImage(pet.imageUrl!) : null,
                              child: pet.imageUrl == null
                                  ? FaIcon(pet.type == 'Anjing' ? FontAwesomeIcons.dog : FontAwesomeIcons.cat, color: Colors.grey, size: 14)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                pet.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            Text('${pet.weight} kg', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (selectedPackageName != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(selectedPackageName, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _currencyFormat.format(
                                          GroomingPackageModel.availablePackages.firstWhere((p) => p.name == selectedPackageName).calculatePrice(pet.weight)
                                        ),
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _showPackageSelector(context, provider, pet),
                                  child: const Text('Ganti', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => _showPackageSelector(context, provider, pet),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Pilih Paket'),
                            ),
                          ),
                        ]
                      ],
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
                      const SnackBar(
                        content: Text(
                          'Harap pilih minimal satu hewan peliharaan',
                        ),
                      ),
                    );
                    return;
                  }
                  bool allPetsHavePackage = true;
                  for (var pet in _selectedPets) {
                    if (!provider.petPackages.containsKey(pet.id)) {
                      allPetsHavePackage = false;
                      break;
                    }
                  }

                  if (!allPetsHavePackage) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Pilih paket grooming untuk setiap hewan yang dipilih',
                        ),
                      ),
                    );
                    return;
                  }
                  if (_isHomeService && provider.alamatLengkap.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Harap pilih lokasi pada peta untuk Home Service',
                        ),
                      ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  _selectedPets.length > 1
                      ? 'Lanjutkan (${_selectedPets.length} Hewan)'
                      : 'Lanjutkan Pilih Jadwal',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
            color: isSelected ? AppColors.primary : Colors.white,
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
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      size: 32,
                    )
                  : FaIcon(
                      icon,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      size: 28, // FA icons are sometimes larger
                    ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPackageSelector(BuildContext context, GroomingProvider provider, UserPetModel pet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      children: [
                        Text('Pilih Paket untuk ${pet.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        const SizedBox(height: 4),
                        Text('Berat: ${pet.weight} kg', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: GroomingPackageModel.availablePackages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final service = GroomingPackageModel.availablePackages[index];
                        final price = service.calculatePrice(pet.weight);
                        final duration = service.calculateDuration(pet.weight);
                        final isSelected = provider.petPackages[pet.id] == service.name;
                        
                        return GestureDetector(
                          onTap: () {
                            provider.setPetPackage(pet.id!, service.name);
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300, width: isSelected ? 2 : 1),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(service.icon, color: isSelected ? Colors.white : Colors.grey.shade600, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            _currencyFormat.format(price),
                                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(Icons.schedule, size: 12, color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text('$duration mnt', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(service.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4)),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Icon(Icons.check_circle, color: AppColors.primary),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
