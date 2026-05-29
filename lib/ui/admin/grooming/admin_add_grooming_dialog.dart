import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/grooming_booking_model.dart';
import 'package:petshopapp/services/grooming_service.dart';

class AdminAddGroomingDialog extends StatefulWidget {
  const AdminAddGroomingDialog({super.key});

  @override
  State<AdminAddGroomingDialog> createState() => _AdminAddGroomingDialogState();
}

class _AdminAddGroomingDialogState extends State<AdminAddGroomingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameCtrl = TextEditingController(text: 'Customer Kasir');
  final _petNameCtrl = TextEditingController();
  final _petTypeCtrl = TextEditingController(text: 'Offline');
  
  final List<Map<String, dynamic>> _groomingServices = [
    {'id': 'g1', 'name': 'Mandi Dasar', 'price': 50000.0},
    {'id': 'g2', 'name': 'Mandi Kutu/Jamur', 'price': 80000.0},
    {'id': 'g3', 'name': 'Potong Kuku', 'price': 20000.0},
    {'id': 'g4', 'name': 'Potong Bulu', 'price': 60000.0},
    {'id': 'g5', 'name': 'Bersih Telinga', 'price': 25000.0},
    {'id': 'g6', 'name': 'Paket Lengkap', 'price': 150000.0},
  ];
  
  Map<String, dynamic>? _selectedService;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  
  List<String> _bookedSlots = [];
  bool _isLoadingSlots = false;
  bool _isSaving = false;

  final List<String> _allTimeSlots = [
    '08:00',
    '10:00',
    '12:00',
    '14:00',
    '16:00',
    '18:00',
  ];

  @override
  void initState() {
    super.initState();
    _fetchBookedSlots(_selectedDate);
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _petNameCtrl.dispose();
    _petTypeCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchBookedSlots(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _selectedTimeSlot = null; // Reset slot when date changes
    });
    try {
      final slots = await GroomingService.instance.getBookedSlots(date);
      if (mounted) {
        setState(() {
          _bookedSlots = slots;
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSlots = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchBookedSlots(picked);
    }
  }

  Future<void> _saveBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap pilih layanan grooming!')));
      return;
    }
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap pilih jam layanan!')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final booking = GroomingBookingModel(
        bookingId: '',
        userId: 'OFFLINE_CUSTOMER',
        customerName: _customerNameCtrl.text.trim(),
        petName: _petNameCtrl.text.trim(),
        petType: _petTypeCtrl.text.trim(),
        serviceType: _selectedService!['name'],
        bookingDate: _selectedDate,
        timeSlot: _selectedTimeSlot!,
        totalPrice: _selectedService!['price'] as double,
        isHomeService: false,
        status: 'Confirmed', // Automatically confirmed for offline bookings
        metodePembayaran: 'Tunai Kasir',
        createdAt: DateTime.now(),
      );

      await GroomingService.instance.createBooking(booking);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking berhasil ditambahkan! Jam telah diblokir.'), backgroundColor: Colors.green));
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Booking Manual (Offline)'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _customerNameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Pelanggan', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _petNameCtrl,
                        decoration: const InputDecoration(labelText: 'Nama Hewan', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _petTypeCtrl,
                        decoration: const InputDecoration(labelText: 'Jenis Hewan', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: const InputDecoration(labelText: 'Pilih Layanan', border: OutlineInputBorder()),
                  value: _selectedService,
                  items: _groomingServices.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text('${s['name']} (Rp ${NumberFormat('#,###').format(s['price'])})'),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedService = val),
                ),
                const SizedBox(height: 24),
                const Text('Jadwal Layanan', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate)),
                              const Icon(Icons.calendar_month, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Pilih Jam', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _isLoadingSlots 
                  ? const Center(child: CircularProgressIndicator())
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allTimeSlots.map((slot) {
                        final isBooked = _bookedSlots.contains(slot);
                        final isSelected = _selectedTimeSlot == slot;
                        return ChoiceChip(
                          label: Text(slot),
                          selected: isSelected,
                          onSelected: isBooked ? null : (selected) {
                            if (selected) setState(() => _selectedTimeSlot = slot);
                          },
                          backgroundColor: isBooked ? Colors.grey.shade300 : Colors.white,
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade400),
                          labelStyle: TextStyle(
                            color: isBooked ? Colors.grey : (isSelected ? AppColors.primary : Colors.black87),
                            decoration: isBooked ? TextDecoration.lineThrough : null,
                          ),
                        );
                      }).toList(),
                    ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveBooking,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan & Blokir Jam'),
        ),
      ],
    );
  }
}
