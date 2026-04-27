import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petshopapp/models/grooming_booking_model.dart';
import 'package:flutter/foundation.dart';

/// Service to handle all Firestore operations related to Grooming Bookings.
class GroomingService {
  GroomingService._privateConstructor();
  static final GroomingService instance = GroomingService._privateConstructor();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<GroomingBookingModel> get _bookingsRef =>
      _db.collection('grooming_bookings').withConverter<GroomingBookingModel>(
            fromFirestore: (snapshot, _) => GroomingBookingModel.fromFirestore(snapshot),
            toFirestore: (model, _) => model.toMap(),
          );

  /// Fetches booked time slots for a specific date.
  /// Used to disable taken slots in the UI.
  Future<List<String>> getBookedSlots(DateTime date) async {
    try {
      // Start of day
      final startOfDay = DateTime(date.year, date.month, date.day);
      // End of day
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _bookingsRef
          .where('bookingDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('bookingDate', isLessThan: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['Pending', 'Confirmed', 'Completed'])
          .get();

      return snapshot.docs.map((doc) => doc.data().timeSlot).toList();
    } catch (e) {
      debugPrint('Error fetching booked slots: $e');
      return [];
    }
  }

  /// Saves a new grooming booking to Firestore.
  /// Also triggers a notification record for the Admin.
  Future<void> createBooking(GroomingBookingModel booking) async {
    try {
      await _bookingsRef.add(booking);
      
      // Trigger Notification for Admin (Mock)
      await _db.collection('notifications').add({
        'title': 'Booking Grooming Baru!',
        'body': '${booking.customerName} baru saja memesan grooming untuk ${booking.petName}.',
        'type': 'grooming_booking',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      throw Exception('Gagal membuat booking: $e');
    }
  }

  /// Updates the status of a specific booking.
  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _bookingsRef.doc(bookingId).update({'status': status});
    } catch (e) {
      throw Exception('Gagal memperbarui status: $e');
    }
  }

  /// Returns a real-time stream of all grooming bookings for the Admin Dashboard.
  Stream<List<GroomingBookingModel>> getAdminBookingsStream() {
    // Temporarily remove orderBy to avoid index requirement issues during debug
    return _bookingsRef
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
