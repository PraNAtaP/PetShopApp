import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:petshopapp/ui/customer/shared/map_picker_screen.dart';
import 'package:petshopapp/models/user_address_model.dart';
import 'package:petshopapp/services/auth_service.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'package:osm_search_and_pick/open_street_map_search_and_pick.dart';

class AddAddressScreen extends StatefulWidget {
  final UserAddressModel? existingAddress;

  const AddAddressScreen({super.key, this.existingAddress});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  late TextEditingController _labelController;
  late TextEditingController _kotaController;
  late TextEditingController _kecamatanController;
  late TextEditingController _kelurahanController;
  late TextEditingController _kodeposController;
  late TextEditingController _detailController;

  double? _lat;
  double? _lng;
  bool _isPrimary = false;
  bool _isLoading = false;
  String _selectedKota = 'Kota Malang';

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.existingAddress?.label ?? 'Rumah');
    _kotaController = TextEditingController(text: 'Kota Malang');
    _kecamatanController = TextEditingController();
    _kelurahanController = TextEditingController();
    _kodeposController = TextEditingController();
    _detailController = TextEditingController(text: widget.existingAddress?.fullAddress ?? '');
    
    _lat = widget.existingAddress?.latitude;
    _lng = widget.existingAddress?.longitude;
    _isPrimary = widget.existingAddress?.isPrimary ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _kotaController.dispose();
    _kecamatanController.dispose();
    _kelurahanController.dispose();
    _kodeposController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, String hint = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _saveAddress() async {
    if (_labelController.text.isEmpty || _detailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Label dan Detail Jalan wajib diisi!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthService>().currentUser;
      if (user == null) throw Exception('User not logged in');

      // Gabungkan alamat jika ada tambahan
      final addressParts = [
        _detailController.text.trim(),
        if (_kelurahanController.text.isNotEmpty) 'Kel. ${_kelurahanController.text.trim()}',
        if (_kecamatanController.text.isNotEmpty) 'Kec. ${_kecamatanController.text.trim()}',
        if (_kotaController.text.isNotEmpty) _kotaController.text.trim(),
        if (_kodeposController.text.isNotEmpty) _kodeposController.text.trim(),
      ];

      final fullAddress = addressParts.join(', ');

      final newAddress = UserAddressModel(
        id: widget.existingAddress?.id ?? '',
        label: _labelController.text.trim(),
        fullAddress: fullAddress,
        latitude: _lat,
        longitude: _lng,
        isPrimary: _isPrimary,
      );

      await FirestoreService.instance.addUserAddress(user.uid, newAddress);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alamat berhasil disimpan')),
        );
        Navigator.pop(context); // Go back to address list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingAddress == null ? 'Tambah Alamat Baru' : 'Edit Alamat'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField('Label Alamat', _labelController, hint: 'Contoh: Rumah, Kantor, Kos'),
                const Divider(),
                const SizedBox(height: 16),
                
                const Text(
                  'Alamat Lengkap',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                
                _buildTextField('Detail Jalan / Patokan (Wajib)', _detailController, maxLines: 3, hint: 'Contoh: Perumahan Bunga Melati No. 123, Blok C (Rumah cat hijau)'),
                
                if (widget.existingAddress == null) ...[
                  // Hanya tampilkan form ekstra jika ini alamat baru. Kalau edit, cukup edit full address di atas.
                  _buildDropdownField(
                    label: 'Kota/Kabupaten',
                    value: _selectedKota,
                    items: const ['Kota Malang', 'Kabupaten Malang'],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedKota = val;
                          _kotaController.text = val;
                        });
                      }
                    },
                  ),
                  _buildTextField('Kecamatan', _kecamatanController, hint: 'Contoh: Lowokwaru'),
                  _buildTextField('Kelurahan', _kelurahanController, hint: 'Contoh: Dinoyo'),
                  _buildTextField('Kode Pos', _kodeposController, hint: 'Contoh: 65144'),
                ],

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                const Text(
                  'Titik Peta GPS (Opsional)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Jika kamu ingin kurir lebih mudah menemukan rumahmu, kamu bisa menandai titik GPS.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final PickedData? result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MapPickerScreen()),
                      );
                      if (result != null) {
                        setState(() {
                          _lat = result.latLong.latitude;
                          _lng = result.latLong.longitude;
                          if (_detailController.text.isEmpty && result.addressName.isNotEmpty) {
                            _detailController.text = result.addressName;
                          }
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Titik GPS berhasil disematkan')),
                          );
                        }
                      }
                    },
                    icon: Icon(_lat != null ? Icons.check_circle : Icons.map, color: _lat != null ? Colors.green : AppColors.primary),
                    label: Text(
                      _lat != null ? 'Titik GPS Tersimpan' : 'Pilih Titik di Peta',
                      style: TextStyle(color: _lat != null ? Colors.green : AppColors.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _lat != null ? Colors.green : AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                CheckboxListTile(
                  title: const Text('Jadikan sebagai Alamat Utama'),
                  value: _isPrimary,
                  onChanged: (val) {
                    setState(() => _isPrimary = val ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveAddress,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Simpan Alamat', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
