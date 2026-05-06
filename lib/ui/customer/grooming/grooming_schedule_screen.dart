import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/providers/grooming_provider.dart';
import 'package:intl/intl.dart';

class GroomingScheduleScreen extends StatefulWidget {
  const GroomingScheduleScreen({super.key});

  @override
  State<GroomingScheduleScreen> createState() => _GroomingScheduleScreenState();
}

class _GroomingScheduleScreenState extends State<GroomingScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  final List<String> _allTimeSlots = [
    '09:00', '10:00', '11:00', '13:00', 
    '14:00', '15:00', '16:00', '17:00'
  ];

  Widget _buildLegendItem(Color color, String label, {Color? borderColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: borderColor != null ? Border.all(color: borderColor) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    // Fetch initial slots for today or current selected date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GroomingProvider>();
      provider.selectDate(provider.selectedDate ?? DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GroomingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Jadwal'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Pilih Tanggal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 30)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(provider.selectedDate, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                  provider.selectDate(selectedDay);
                },
                calendarStyle: const CalendarStyle(
                  selectedDecoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                  markerDecoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pilih Jam', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  if (provider.isLoadingSlots)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildLegendItem(Colors.grey.shade300, 'Terisi'),
                  const SizedBox(width: 16),
                  _buildLegendItem(Colors.white, 'Tersedia', borderColor: AppColors.primary),
                  const SizedBox(width: 16),
                  _buildLegendItem(AppColors.secondary, 'Dipilih'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (provider.selectedDate == null)
              const Center(child: Text('Harap pilih tanggal terlebih dahulu'))
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _allTimeSlots.map((slot) {
                    final isBooked = provider.bookedSlots.contains(slot);
                    final isSelected = provider.selectedTimeSlot == slot;

                    return GestureDetector(
                      onTap: isBooked ? null : () => provider.selectTimeSlot(slot),
                      child: Container(
                        width: (MediaQuery.of(context).size.width - 60) / 3,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isBooked 
                              ? Colors.grey.shade200 
                              : (isSelected ? AppColors.secondary : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isBooked 
                                ? Colors.grey.shade300 
                                : (isSelected ? AppColors.secondary : AppColors.primary.withOpacity(0.5)),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            slot,
                            style: TextStyle(
                              color: isBooked 
                                  ? Colors.grey 
                                  : (isSelected ? Colors.white : AppColors.primary),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: provider.selectedDate == null || provider.selectedTimeSlot == null
                      ? null
                      : () => context.push('/grooming-summary'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Ringkasan Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
