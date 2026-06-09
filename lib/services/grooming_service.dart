import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petshopapp/models/grooming_booking_model.dart';
import 'package:petshopapp/models/grooming_booking_model.dart';
import 'package:flutter/foundation.dart';
import 'package:petshopapp/services/fcm_service.dart';
import 'package:petshopapp/services/admin_log_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  /// Returns a list of maps containing 'timeSlot' (String) and 'durationMinutes' (int).
  Future<List<Map<String, dynamic>>> getBookedSlots(DateTime date) async {
    try {
      // Start of day
      final startOfDay = DateTime(date.year, date.month, date.day);
      // End of day
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _bookingsRef
          .where('bookingDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('bookingDate', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      // Filter locally to avoid Firestore composite index requirement
      final validStatuses = ['Pending', 'Confirmed', 'Completed'];
      final bookedSlots = snapshot.docs
          .map((doc) => doc.data())
          .where((booking) => validStatuses.contains(booking.status))
          .map((booking) => {
                'timeSlot': booking.timeSlot,
                'durationMinutes': booking.durationMinutes,
              })
          .toList();

      return bookedSlots;
    } catch (e) {
      debugPrint('Error fetching booked slots: $e');
      return [];
    }
  }

  /// Saves a new grooming booking to Firestore.
  /// Also triggers a notification record for the Admin.
  Future<String> createBooking(GroomingBookingModel booking) async {
    try {
      final docRef = await _bookingsRef.add(booking);
      
      // Update the bookingId inside the model
      final bookingId = docRef.id;
      await docRef.update({'bookingId': bookingId});
      
      // Trigger Notification for Admin (Mock)
      await _db.collection('notifications').add({
        'title': 'Booking Grooming Baru!',
        'body': '${booking.customerName} baru saja memesan grooming untuk ${booking.petName}.',
        'type': 'grooming_booking',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
      
      return bookingId;
    } catch (e) {
      throw Exception('Gagal membuat booking: $e');
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      final bookingDoc = await _bookingsRef.doc(bookingId).get();
      final booking = bookingDoc.data();
      await _bookingsRef.doc(bookingId).update({
        'status': status});

        if (booking != null) {
      await AdminLogService.instance.logAction(
        adminName: 'Min Pet',
        actionType: 'UPDATE_GROOMING_STATUS',
        description:
            'Mengubah status grooming ${booking.petName} milik ${booking.customerName} menjadi $status',
      );
    }
      

      // -- Trigger Push Notification ke Customer --
      try {
        final bookingDoc = await _bookingsRef.doc(bookingId).get();
        final booking = bookingDoc.data();
        if (booking != null) {
          final customerDoc = await _db.collection('users').doc(booking.userId).get();
          final fcmToken = customerDoc.data()?['fcm_token'] as String?;
          if (fcmToken != null && fcmToken.isNotEmpty) {
            String title = 'Status Grooming Diperbarui';
            String body = 'Status pesanan grooming untuk ${booking.petName} menjadi: $status';
            
            if (status == 'Groomer Menuju Lokasi' || status == 'Menuju Lokasi') {
              title = 'Groomer Sedang OTW! 🛵';
              body = 'Siap-siap! Groomer kami sedang menuju ke lokasimu untuk grooming ${booking.petName}.';
            } else if (status == 'Completed' || status == 'Selesai') {
              title = 'Grooming Selesai ✨';
              body = '${booking.petName} sudah wangi dan bersih! Terima kasih sudah menggunakan layanan kami.';
            }

            await FCMService.instance.sendNotification(
              targetFCMToken: fcmToken,
              title: title,
              body: body,
            );
          }
        }
      } catch (e) {
        debugPrint('Gagal kirim notif status grooming: $e');
      }

    } catch (e) {
      throw Exception('Gagal memperbarui status: $e');
    }
  }

  /// Returns a real-time stream of all grooming bookings for the Admin Dashboard.
  Stream<List<GroomingBookingModel>> getAdminBookingsStream({DateTime? startDate}) {
    Query<GroomingBookingModel> query = _bookingsRef;
    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    return query
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) => doc.data()).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Returns a real-time stream of grooming bookings for a specific customer.
  Stream<List<GroomingBookingModel>> getCustomerBookingsStream(String userId) {
    try {
      return _bookingsRef
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs.map((doc) => doc.data()).toList();
            // Sort by createdAt descending
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list;
          });
    } catch (e) {
      throw Exception('Gagal stream data booking: $e');
    }
  }

  /// Submits a request to cancel a grooming booking.
  Future<void> requestCancelBooking({
    required String bookingId,
    String? bankName,
    String? bankAccount,
    String? accountHolder,
  }) async {
    try {
      final updates = <String, dynamic>{
        'cancel_request': true,
        'status': 'Menunggu Persetujuan Pembatalan',
      };
      if (bankName != null) updates['cancel_bank_name'] = bankName;
      if (bankAccount != null) updates['cancel_bank_account'] = bankAccount;
      if (accountHolder != null) updates['cancel_account_holder'] = accountHolder;

      await _db.collection('grooming_bookings').doc(bookingId).update(updates);
    } catch (e) {
      throw Exception('Gagal mengajukan pembatalan booking: $e');
    }
  }
}
