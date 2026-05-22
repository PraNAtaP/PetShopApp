import 'package:flutter/material.dart';
import 'package:osm_search_and_pick/open_street_map_search_and_pick.dart';
import 'package:provider/provider.dart';
import 'package:petshopapp/providers/cart_provider.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:petshopapp/ui/customer/shared/map_picker_screen.dart';

class CheckoutLocationScreen extends StatefulWidget {
  const CheckoutLocationScreen({super.key});

  @override
  State<CheckoutLocationScreen> createState() => _CheckoutLocationScreenState();
}

class _CheckoutLocationScreenState extends State<CheckoutLocationScreen> {
  late TextEditingController _kotaController;
  late TextEditingController _kecamatanController;
  late TextEditingController _kelurahanController;
  late TextEditingController _kodeposController;
  late TextEditingController _detailController;

  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    final provider = context.read<CartProvider>();
    
    // We try to parse the existing alamatLengkap if any, but since it's just a concatenated string,
    // we'll just put the whole string in _detailController for existing data, or leave it blank.
    _kotaController = TextEditingController();
    _kecamatanController = TextEditingController();
    _kelurahanController = TextEditingController();
    _kodeposController = TextEditingController();
    _detailController = TextEditingController(text: provider.alamatLengkap);
    
    _lat = provider.latitude;
    _lng = provider.longitude;
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Lokasi Pengiriman'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alamat Lengkap',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            
            _buildTextField('Kota/Kabupaten', _kotaController, hint: 'Contoh: Kota Malang'),
            _buildTextField('Kecamatan', _kecamatanController, hint: 'Contoh: Lowokwaru'),
            _buildTextField('Kelurahan', _kelurahanController, hint: 'Contoh: Dinoyo'),
            _buildTextField('Kode Pos', _kodeposController, hint: 'Contoh: 65144'),
            _buildTextField('Detail Jalan / Patokan', _detailController, maxLines: 3, hint: 'Contoh: Perumahan Bunga Melati No. 123, Blok C (Rumah cat hijau)'),

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
                      // Autofill city if empty
                      if (_kotaController.text.isEmpty && result.addressName.isNotEmpty) {
                        _detailController.text += '\n[Peta]: ${result.addressName}';
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
            onPressed: () {
              // Validasi Alamat (GPS boleh kosong)
              if (_kotaController.text.isEmpty || _detailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kota dan Detail Jalan wajib diisi!')),
                );
                return;
              }

              // Gabungkan alamat
              final addressParts = [
                _detailController.text.trim(),
                if (_kelurahanController.text.isNotEmpty) 'Kel. ${_kelurahanController.text.trim()}',
                if (_kecamatanController.text.isNotEmpty) 'Kec. ${_kecamatanController.text.trim()}',
                _kotaController.text.trim(),
                if (_kodeposController.text.isNotEmpty) _kodeposController.text.trim(),
              ];

              final fullAddress = addressParts.join(', ');

              provider.updateLocationInfo(
                isDelivery: true,
                alamat: fullAddress,
                lat: _lat,
                lng: _lng,
              );
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Simpan Lokasi', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

