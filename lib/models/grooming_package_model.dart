import 'package:flutter/material.dart';

class GroomingPackageModel {
  final String name;
  final String description;
  final double priceSmall; // <= 5 kg
  final double priceMedium; // 5.1 - 10 kg
  final double priceLarge; // > 10 kg
  final int durationSmall; // in minutes
  final int durationMedium; 
  final int durationLarge; 
  final IconData icon;

  const GroomingPackageModel({
    required this.name,
    required this.description,
    required this.priceSmall,
    required this.priceMedium,
    required this.priceLarge,
    required this.durationSmall,
    required this.durationMedium,
    required this.durationLarge,
    required this.icon,
  });

  /// Calculates the price based on the pet's weight.
  /// Defaults to [priceSmall] if weight is unknown (null).
  double calculatePrice(double? weight) {
    if (weight == null) {
      return priceSmall; // Default estimate
    }
    
    if (weight <= 5.0) {
      return priceSmall;
    } else if (weight <= 10.0) {
      return priceMedium;
    } else {
      return priceLarge;
    }
  }

  /// Calculates the estimated duration based on the pet's weight.
  /// Defaults to [durationSmall] if weight is unknown (null).
  int calculateDuration(double? weight) {
    if (weight == null) {
      return durationSmall; 
    }
    
    if (weight <= 5.0) {
      return durationSmall;
    } else if (weight <= 10.0) {
      return durationMedium;
    } else {
      return durationLarge;
    }
  }

  static const List<GroomingPackageModel> availablePackages = [
    GroomingPackageModel(
      name: 'Paket Kenalan Mandi',
      description: 'Potong kuku + usap telinga lembut + mandi air hangat sampo hypoallergenic + blow dry suhu rendah + sisir halus',
      priceSmall: 40000.0,
      priceMedium: 50000.0,
      priceLarge: 60000.0,
      durationSmall: 45,
      durationMedium: 60,
      durationLarge: 75,
      icon: Icons.baby_changing_station,
    ),
    GroomingPackageModel(
      name: 'Paket Mandi Instan',
      description: 'Potong kuku + bersihin telinga + bersihin badan pakai dry foam tanpa air + lap handuk hangat + sisir rapi + parfum',
      priceSmall: 40000.0,
      priceMedium: 55000.0,
      priceLarge: 70000.0,
      durationSmall: 30,
      durationMedium: 45,
      durationLarge: 60,
      icon: Icons.timer,
    ),
    GroomingPackageModel(
      name: 'Paket Segar Harian',
      description: 'Potong kuku + bersihin telinga + cukur area sanitasi perut/pantat + mandi sampo normal + blow dry + sisir rapi',
      priceSmall: 50000.0,
      priceMedium: 65000.0,
      priceLarge: 80000.0,
      durationSmall: 60,
      durationMedium: 75,
      durationLarge: 90,
      icon: Icons.shower,
    ),
    GroomingPackageModel(
      name: 'Paket Basmi Tuntas',
      description: 'Potong kuku + bersihin telinga + mandi sampo medis + perendaman 10 menit + cabut kutu manual + blow dry',
      priceSmall: 80000.0,
      priceMedium: 115000.0,
      priceLarge: 150000.0,
      durationSmall: 90,
      durationMedium: 105,
      durationLarge: 120,
      icon: Icons.bug_report,
    ),
    GroomingPackageModel(
      name: 'Paket Ganti Gaya',
      description: 'Potong kuku + bersihin telinga + cukur bulu seluruh badan pakai mesin atau gunting model + mandi + blow dry',
      priceSmall: 150000.0,
      priceMedium: 225000.0,
      priceLarge: 300000.0,
      durationSmall: 120,
      durationMedium: 150,
      durationLarge: 180,
      icon: Icons.content_cut,
    ),
    GroomingPackageModel(
      name: 'Paket Manja Total',
      description: 'Potong kuku + bersihin telinga + mandi air hangat ozon + sampo premium + masker bulu + pijat + pelembap telapak kaki',
      priceSmall: 150000.0,
      priceMedium: 250000.0,
      priceLarge: 350000.0,
      durationSmall: 120,
      durationMedium: 150,
      durationLarge: 180,
      icon: Icons.spa,
    ),
  ];
}
