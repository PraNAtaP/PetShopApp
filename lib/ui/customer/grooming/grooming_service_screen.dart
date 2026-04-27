import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/providers/grooming_provider.dart';
import 'package:intl/intl.dart';

class GroomingServiceScreen extends StatefulWidget {
  const GroomingServiceScreen({super.key});

  @override
  State<GroomingServiceScreen> createState() => _GroomingServiceScreenState();
}

class _GroomingServiceScreenState extends State<GroomingServiceScreen> {
  final TextEditingController _petNameController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  String _selectedPetType = 'Anjing';
  bool _isHomeService = false;
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
    _petNameController.dispose();
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
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Informasi Hewan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _petNameController,
              decoration: InputDecoration(
                labelText: 'Nama Hewan',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.pets),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Jenis Hewan:', style: TextStyle(fontWeight: FontWeight.w500)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Anjing'),
                    value: 'Anjing',
                    groupValue: _selectedPetType,
                    onChanged: (val) => setState(() => _selectedPetType = val!),
                    activeColor: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Kucing'),
                    value: 'Kucing',
                    groupValue: _selectedPetType,
                    onChanged: (val) => setState(() => _selectedPetType = val!),
                    activeColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 30, thickness: 1),
            const Text(
              'Lokasi Layanan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Bawa ke Petshop'),
                    value: false,
                    groupValue: _isHomeService,
                    onChanged: (val) {
                      setState(() => _isHomeService = val!);
                      _alamatController.clear();
                    },
                    activeColor: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Home Service'),
                    value: true,
                    groupValue: _isHomeService,
                    onChanged: (val) => setState(() => _isHomeService = val!),
                    activeColor: AppColors.primary,
                  ),
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
                  if (_petNameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Harap masukkan nama hewan')),
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

                  provider.updatePetInfo(_petNameController.text, _selectedPetType);
                  // Location is already updated via Map Picker
                  context.push('/grooming-schedule');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: const Text('Lanjutkan Pilih Jadwal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
