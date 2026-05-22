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
          Navigator.pop(context, pickedData);
        },
      ),
    );
  }
}
