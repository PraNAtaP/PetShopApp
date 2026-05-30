import 'package:flutter/material.dart';
import 'package:petshopapp/models/grooming_booking_model.dart';
import 'package:petshopapp/services/grooming_service.dart';
import 'package:petshopapp/services/auth_service.dart';
import 'package:petshopapp/models/user_pet_model.dart';
import 'package:petshopapp/models/grooming_package_model.dart';

class GroomingProvider with ChangeNotifier {
  final GroomingService _groomingService = GroomingService.instance;

  // Selected Service Details
  List<String> _selectedServices = [];
  
  // Pet Details
  List<UserPetModel> _selectedPets = [];

  // Location / Service Type
  bool _isHomeService = false;
  String _alamatLengkap = '';
  double? _latitude;
  double? _longitude;


  // Schedule Details
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  // Available slots logic
  List<String> _bookedSlots = [];
  bool _isLoadingSlots = false;

  // Getters
  List<String> get selectedServices => _selectedServices;

  double get selectedPrice {
    double total = 0.0;
    for (var serviceName in _selectedServices) {
      final package = GroomingPackageModel.availablePackages.firstWhere(
        (p) => p.name == serviceName,
        orElse: () => GroomingPackageModel.availablePackages.first,
      );
      
      for (var pet in _selectedPets) {
        total += package.calculatePrice(pet.weight);
      }
    }
    return total;
  }

  List<UserPetModel> get selectedPets => _selectedPets;
  bool get isHomeService => _isHomeService;
  String get alamatLengkap => _alamatLengkap;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  DateTime? get selectedDate => _selectedDate;
  String? get selectedTimeSlot => _selectedTimeSlot;
  List<String> get bookedSlots => _bookedSlots;
  bool get isLoadingSlots => _isLoadingSlots;

  double get shippingFee {
    if (!_isHomeService || _alamatLengkap.isEmpty) return 0.0;

    final address = _alamatLengkap.toLowerCase();
    
    // Check if within Kabupaten Malang
    final bool isKabupaten = address.contains('kabupaten malang') || 
                             address.contains('kab. malang') || 
                             address.contains('kab malang');

    if (isKabupaten) {
      if (address.contains('pujon') || address.contains('ngantang') || address.contains('kasembon') || 
          address.contains('dampit') || address.contains('turen') || address.contains('gondanglegi') || 
          address.contains('bantur') || address.contains('sumbermanjing') || address.contains('donomulyo') ||
          address.contains('gedangan') || address.contains('ampelgading') || address.contains('tirtoyudo')) {
        return 20000.0;
      } else if (address.contains('lawang') || address.contains('tumpang') || address.contains('bululawang') || 
                 address.contains('tajinan') || address.contains('kepanjen') || address.contains('jabung') ||
                 address.contains('poncokusumo') || address.contains('pagak') || address.contains('kalipare')) {
        return 15000.0;
      } else if (address.contains('dau') || address.contains('singosari') || address.contains('pakisaji') || 
                 address.contains('karangploso') || address.contains('wagir') || address.contains('pakis')) {
        return 12000.0;
      } else {
        final int hashVal = address.codeUnits.fold(0, (sum, char) => sum + char);
        return 10000.0 + (hashVal % 11) * 1000.0;
      }
    }
    
    return 0.0;
  }

  // Setters
  void toggleService(String service) {
    if (_selectedServices.contains(service)) {
      _selectedServices.remove(service);
    } else {
      _selectedServices.add(service);
    }
    notifyListeners();
  }

  void updatePetsInfo(List<UserPetModel> pets) {
    _selectedPets = pets;
    notifyListeners();
  }

  void updateLocationInfo({required bool isHome, required String alamat, double? lat, double? lng}) {
    _isHomeService = isHome;
    _alamatLengkap = alamat;
    _latitude = lat;
    _longitude = lng;
    notifyListeners();
  }

  Future<void> selectDate(DateTime date) async {
    _selectedDate = date;
    _selectedTimeSlot = null; // Reset time slot when date changes
    _isLoadingSlots = true;
    notifyListeners();

    _bookedSlots = await _groomingService.getBookedSlots(date);
    
    _isLoadingSlots = false;
    notifyListeners();
  }

  void selectTimeSlot(String slot) {
    _selectedTimeSlot = slot;
    notifyListeners();
  }

  /// Finalize booking and save to Firestore
  Future<void> confirmBooking(String userId, String customerName, {String? buktiBayarUrl, required String metodePembayaran}) async {
    if (_selectedServices.isEmpty || _selectedDate == null || _selectedTimeSlot == null || _selectedPets.isEmpty) {
      throw Exception('Harap lengkapi data booking');
    }

    final double feePerPet = shippingFee / _selectedPets.length;

    // Create a separate booking for each pet
    for (var pet in _selectedPets) {
      double petServicesPrice = 0.0;
      for (var serviceName in _selectedServices) {
        final package = GroomingPackageModel.availablePackages.firstWhere(
          (p) => p.name == serviceName,
          orElse: () => GroomingPackageModel.availablePackages.first,
        );
        petServicesPrice += package.calculatePrice(pet.weight);
      }

      final booking = GroomingBookingModel(
        bookingId: '', // Auto-generated by Firestore
        userId: userId,
        customerName: customerName,
        petName: pet.name,
        petType: pet.type,
        serviceType: _selectedServices.join(', '),
        bookingDate: _selectedDate!,
        timeSlot: _selectedTimeSlot!,
        totalPrice: petServicesPrice + feePerPet, // Price for THIS pet + distributed shipping fee
        isHomeService: _isHomeService,
        alamatLengkap: _isHomeService ? _alamatLengkap : null,
        latitude: _isHomeService ? _latitude : null,
        longitude: _isHomeService ? _longitude : null,
        status: 'Pending',
        buktiBayarUrl: buktiBayarUrl,
        metodePembayaran: metodePembayaran,
        createdAt: DateTime.now(),
      );

      await _groomingService.createBooking(booking);
    }
    reset();
  }

  void reset() {
    _selectedServices = [];
    _selectedPets = [];
    _isHomeService = false;
    _alamatLengkap = '';
    _latitude = null;
    _longitude = null;
    _selectedDate = null;
    _selectedTimeSlot = null;
    _bookedSlots = [];
    notifyListeners();
  }
}
