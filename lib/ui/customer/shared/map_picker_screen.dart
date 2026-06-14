import 'package:flutter/material.dart';
import 'package:osm_search_and_pick/open_street_map_search_and_pick.dart';
import 'package:petshopapp/core/theme/app_colors.dart';

class MapPickerScreen extends StatelessWidget {
  const MapPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Titik Lokasi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: OpenStreetMapSearchAndPick(
        buttonColor: AppColors.primary,
        buttonText: 'Gunakan Koordinat Ini',
        userAgentPackageName: 'com.prana.pet_point',
        initialCenter: LatLong(-7.9839, 112.6214), // Pusat di Malang
        initialZoom: 13.0,
        tileUrlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png',
        onPicked: (pickedData) {
          final lat = pickedData.latLong.latitude;
          final lng = pickedData.latLong.longitude;
          final addressName = pickedData.addressName.toLowerCase();
          
          // Bounding box for Malang (Kota & Kabupaten Malang)
          final bool isInBoundingBox = (lat >= -8.5 && lat <= -7.7) && (lng >= 112.2 && lng <= 113.0);
          
          // Check if address name contains "malang"
          bool hasMalangText = addressName.contains('malang');


          // Check other address components in the map
          final addressMap = pickedData.address;
          for (var val in addressMap.values) {
            if (val != null && val.toString().toLowerCase().contains('malang')) {
              hasMalangText = true;
              break;
            }
          }

          // If address details are completely empty (e.g. offline/error), fallback to bounding box only
          final bool isAddressDetailsEmpty = addressName.isEmpty && addressMap.isEmpty;
          
          final bool isValid = isInBoundingBox && (hasMalangText || isAddressDetailsEmpty);

          if (!isValid) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Lokasi Tidak Didukung'),
                  content: const Text(
                    'Maaf, layanan kami saat ini hanya mencakup wilayah Kota Malang dan Kabupaten Malang. Silakan pilih titik lokasi di dalam area tersebut.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
            return;
          }

          Navigator.pop(context, pickedData);
        },
      ),
    );
  }
}
