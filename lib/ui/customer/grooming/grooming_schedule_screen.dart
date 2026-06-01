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

  /// Parses "HH:mm" into minutes from midnight
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// Formats minutes from midnight into "HH:mm"
  String _minutesToTime(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Generates available time slots and checks for overlaps
  List<Map<String, dynamic>> _generateSlots(GroomingProvider provider) {
    final int openTime = 8 * 60; // 08:00
    final int closeTime = 20 * 60; // 20:00 (last completion time)
    final int maxOrderTime = 19 * 60; // 19:00 (last start time)
    final int interval = 30; // 30 minutes interval

    final estimatedDuration = provider.estimatedDuration;
    
    // Parse booked slots into ranges
    List<Map<String, int>> bookedRanges = [];
    for (var b in provider.bookedSlots) {
      final start = _timeToMinutes(b['timeSlot'] as String);
      final duration = (b['durationMinutes'] as int?) ?? 60; // default to 60 if missing
      bookedRanges.add({'start': start, 'end': start + duration});
    }

    List<Map<String, dynamic>> slots = [];
    for (int t = openTime; t <= maxOrderTime; t += interval) {
      final slotEndTime = t + estimatedDuration;
      bool isBooked = false;

      // 1. Check if it exceeds closing time
      if (slotEndTime > closeTime) {
        isBooked = true;
      }

      // 2. Check for overlaps with existing bookings
      // To avoid overlap: newEnd <= bookedStart OR newStart >= bookedEnd
      if (!isBooked) {
        for (var b in bookedRanges) {
          bool overlap = !(slotEndTime <= b['start']! || t >= b['end']!);
          if (overlap) {
            isBooked = true;
            break;
          }
        }
      }

      // 3. For today, disable past time slots with a 1 hour buffer
      if (!isBooked && provider.selectedDate != null) {
        if (isSameDay(provider.selectedDate, DateTime.now())) {
          final now = DateTime.now();
          final currentMinutes = now.hour * 60 + now.minute;
          if (t < currentMinutes + 60) {
            isBooked = true;
          }
        }
      }

      slots.add({
        'time': _minutesToTime(t),
        'isBooked': isBooked,
      });
    }
    return slots;
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 30)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) =>
                    isSameDay(provider.selectedDate, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                  provider.selectDate(selectedDay);
                },
                calendarStyle: const CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
            ),
            if (provider.estimatedDuration > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Estimasi Waktu Pengerjaan: ${provider.estimatedDuration ~/ 60} Jam ${provider.estimatedDuration % 60} Menit',
                          style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pilih Jam',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (provider.isLoadingSlots)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
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
                  _buildLegendItem(
                    Colors.white,
                    'Tersedia',
                    borderColor: AppColors.primary,
                  ),
                  const SizedBox(width: 16),
                  _buildLegendItem(AppColors.secondary, 'Dipilih'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (provider.selectedDate == null)
              const Center(child: Text('Harap pilih tanggal terlebih dahulu'))
            else
              Builder(
                builder: (context) {
                  final dynamicSlots = _generateSlots(provider);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.0, // Adjust this ratio as needed for height
                      ),
                      itemCount: dynamicSlots.length,
                      itemBuilder: (context, index) {
                        final slotData = dynamicSlots[index];
                        final slot = slotData['time'] as String;
                        final isBooked = slotData['isBooked'] as bool;
                        final isSelected = provider.selectedTimeSlot == slot;

                        return GestureDetector(
                          onTap: isBooked
                              ? null
                              : () => provider.selectTimeSlot(slot),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isBooked
                                  ? Colors.grey.shade200
                                  : (isSelected
                                        ? AppColors.secondary
                                        : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isBooked
                                    ? Colors.grey.shade300
                                    : (isSelected
                                          ? AppColors.secondary
                                          : AppColors.primary.withOpacity(0.5)),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                slot,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isBooked
                                      ? Colors.grey
                                      : (isSelected
                                            ? Colors.white
                                            : AppColors.primary),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
              ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed:
                      provider.selectedDate == null ||
                          provider.selectedTimeSlot == null
                      ? null
                      : () => context.push('/grooming-summary'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Ringkasan Booking',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
