import 'package:flutter/material.dart';
import 'package:osm_search_and_pick/open_street_map_search_and_pick.dart';
import 'package:provider/provider.dart';
import 'package:petshopapp/providers/grooming_provider.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

class GroomingLocationScreen extends StatefulWidget {
  const GroomingLocationScreen({super.key});

  @override
  State<GroomingLocationScreen> createState() => _GroomingLocationScreenState();
}

class _GroomingLocationScreenState extends State<GroomingLocationScreen> {
  late TextEditingController _addressController;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    final provider = context.read<GroomingProvider>();
    _addressController = TextEditingController(text: provider.alamatLengkap);
    _lat = provider.latitude;
    _lng = provider.longitude;
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GroomingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Lokasi Grooming'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Bagian 1: Input Alamat Manual
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alamat Lengkap (Manual)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Perumahan Bunga Melati No. 123, Blok C...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Klik titik di peta untuk sinkronisasi GPS',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          
          // Bagian 2: Map GPS Picker (HD & Auto-location)
          Expanded(
            child: OpenStreetMapSearchAndPick(
              buttonColor: AppColors.primary,
              buttonText: 'Gunakan Koordinat Ini',
              userAgentPackageName: 'com.prana.pet_point',
              initialCenter: LatLong(-7.9839, 112.6214), // Pusat di Malang
              initialZoom: 13.0, // Zoom lebih dekat agar fokus ke kota
              tileUrlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png',
              onPicked: (pickedData) {
                setState(() {
                  _lat = pickedData.latLong.latitude;
                  _lng = pickedData.latLong.longitude;
                  // Jika field manual kosong, otomatis isi dari peta
                  if (_addressController.text.isEmpty) {
                    _addressController.text = pickedData.addressName;
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Koordinat GPS berhasil disematkan')),
                );
              },
            ),
          ),
        ],
      ),
      // Tombol Simpan Final
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              if (_addressController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Harap lengkapi alamat manual Anda')),
                );
                return;
              }
              if (_lat == null || _lng == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Harap tentukan titik GPS pada peta')),
                );
                return;
              }
              
              provider.updateLocationInfo(
                isHome: true,
                alamat: _addressController.text,
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
