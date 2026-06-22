import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/animal_model.dart';
import 'package:petshopapp/services/adoption_service.dart';
import 'package:petshopapp/services/auth_service.dart';

class AdoptionDetailScreen extends StatefulWidget {
  final AnimalModel animal;

  const AdoptionDetailScreen({super.key, required this.animal});

  @override
  State<AdoptionDetailScreen> createState() => _AdoptionDetailScreenState();
}

class _AdoptionDetailScreenState extends State<AdoptionDetailScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  bool _agreeToCare = false;
  bool _agreeNoSell = false;
  bool _agreeToCost = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (picked.hour < 9 || picked.hour >= 20) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jam pengambilan harus antara 09:00 - 20:00')),
        );
        return;
      }
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submitBooking() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal dan jam pengambilan terlebih dahulu!')),
      );
      return;
    }

    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu.')),
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final dateStr = DateFormat('dd MMMM yyyy', 'id').format(_selectedDate!);
        final timeStr = _selectedTime!.format(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Konfirmasi Booking Adopsi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hewan: ${widget.animal.name}'),
              const SizedBox(height: 4),
              Text('Tanggal: $dateStr'),
              Text('Jam: $timeStr'),
              const SizedBox(height: 12),
              const Text(
                'Apakah Anda yakin ingin booking adopsi ini?',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Ya, Booking!', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final timeStr = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

      await AdoptionService().requestAdoption(
        widget.animal.id,
        user.uid,
        pickupDate: _selectedDate,
        pickupTime: timeStr,
      );

      if (!mounted) return;

      // Show success & pop back
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Booking Berhasil!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Anda telah berhasil booking ${widget.animal.name}. Silakan datang ke Pet Point pada jadwal yang ditentukan.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // go back to catalog
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Kembali ke Katalog', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal booking: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // --- Hero Image ---
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                animal.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.pets, size: 80, color: Colors.grey),
                ),
              ),
            ),
          ),

          // --- Content ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          animal.name,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: const Text(
                          'Available',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${animal.type} • ${animal.breed}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),

                  const SizedBox(height: 24),

                  // Info Cards Row
                  Row(
                    children: [
                      _buildInfoCard(Icons.cake_outlined, 'Umur', animal.age),
                      const SizedBox(width: 12),
                      _buildInfoCard(
                        animal.gender == 'Jantan' ? Icons.male : Icons.female,
                        'Gender',
                        animal.gender,
                      ),
                      const SizedBox(width: 12),
                      _buildInfoCard(
                        Icons.monitor_weight_outlined,
                        'Berat',
                        animal.weight != null ? '${animal.weight} kg' : '-',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Deskripsi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    animal.description.isNotEmpty ? animal.description : 'Tidak ada deskripsi.',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.5),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // --- Schedule Picker ---
                  const Text(
                    'Pilih Jadwal Pengambilan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pilih tanggal dan jam kapan kamu mau mengambil hewan ini.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Date Picker
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: _selectedDate != null ? AppColors.primary : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: _selectedDate != null ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: _selectedDate != null ? AppColors.primary : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedDate != null
                                  ? DateFormat('EEEE, dd MMMM yyyy', 'id').format(_selectedDate!)
                                  : 'Pilih Tanggal Pengambilan',
                              style: TextStyle(
                                fontSize: 15,
                                color: _selectedDate != null ? Colors.black87 : Colors.grey,
                                fontWeight: _selectedDate != null ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Time Picker
                  InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: _selectedTime != null ? AppColors.primary : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: _selectedTime != null ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: _selectedTime != null ? AppColors.primary : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedTime != null
                                  ? _selectedTime!.format(context)
                                  : 'Pilih Jam Pengambilan',
                              style: TextStyle(
                                fontSize: 15,
                                color: _selectedTime != null ? Colors.black87 : Colors.grey,
                                fontWeight: _selectedTime != null ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Syarat & Ketentuan Adopsi
                  const Text(
                    'Syarat & Ketentuan Adopsi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildCheckboxItem(
                          value: _agreeToCare,
                          title: 'Saya bersedia merawat hewan ini dengan penuh kasih sayang dan komitmen jangka panjang.',
                          onChanged: (val) => setState(() => _agreeToCare = val ?? false),
                        ),
                        const SizedBox(height: 8),
                        _buildCheckboxItem(
                          value: _agreeNoSell,
                          title: 'Saya setuju bahwa hewan ini tidak akan diperjualbelikan kembali.',
                          onChanged: (val) => setState(() => _agreeNoSell = val ?? false),
                        ),
                        const SizedBox(height: 8),
                        _buildCheckboxItem(
                          value: _agreeToCost,
                          title: 'Saya bersedia menanggung biaya pakan, kesehatan (vaksinasi), dan kebutuhannya.',
                          onChanged: (val) => setState(() => _agreeToCost = val ?? false),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_isLoading || !_agreeToCare || !_agreeNoSell || !_agreeToCost) ? null : _submitBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Booking Adopsi',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxItem({
    required bool value,
    required String title,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Text(
              title,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
            ),
          ),
        ),
      ],
    );
  }
}
