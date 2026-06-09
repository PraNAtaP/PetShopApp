import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/animal_model.dart';
import '../services/admin_log_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to handle Animal and Adoption related business logic and CRUD operations.
class AdoptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'animals';

  /// Stream of all animals in the catalog.
  Stream<List<AnimalModel>> getAnimals() {
    return _firestore.collection(_collectionPath).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AnimalModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Stream of animals filtered by status.
  Stream<List<AnimalModel>> getAnimalsByStatus(String status) {
    return _firestore
        .collection(_collectionPath)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AnimalModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Stream of animals filtered by multiple statuses.
  Stream<List<AnimalModel>> getAnimalsByStatuses(List<String> statuses) {
    return _firestore
        .collection(_collectionPath)
        .where('status', whereIn: statuses)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AnimalModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Adds a new animal to the catalog.
  Future<void> addAnimal(AnimalModel animal) async {
    try {
      await _firestore.collection(_collectionPath).add(animal.toMap());

      await AdminLogService.instance.logAction(
        adminName: FirebaseAuth.instance.currentUser?.displayName ?? 'Min Pet',
        actionType: 'ADD_ANIMAL',
        description: 'Menambahkan hewan adopsi ${animal.name}',
      );
    } catch (e) {
      throw Exception('Failed to add animal: $e');
    }
  }

  /// Updates an existing animal's data.
  Future<void> updateAnimal(String id, Map<String, dynamic> data) async {
    try {
      final animalDoc = await _firestore.collection(_collectionPath).doc(id).get();
      final animalName = animalDoc.data()?['name'] ?? 'Hewan';

      await _firestore.collection(_collectionPath).doc(id).update(data);

      await AdminLogService.instance.logAction(
        adminName: FirebaseAuth.instance.currentUser?.displayName ?? 'Min Pet',
        actionType: 'UPDATE_ANIMAL',
        description: 'Mengubah data hewan adopsi $animalName',
      );
    } catch (e) {
      throw Exception('Failed to update animal: $e');
    }
  }

  /// Deletes an animal from the catalog.
  Future<void> deleteAnimal(String id) async {
    try {
      final animalDoc = await _firestore.collection(_collectionPath).doc(id).get();
      final animalName = animalDoc.data()?['name'] ?? 'Hewan';

      await _firestore.collection(_collectionPath).doc(id).delete();

      await AdminLogService.instance.logAction(
        adminName: FirebaseAuth.instance.currentUser?.displayName ?? 'Min Pet',
        actionType: 'DELETE_ANIMAL',
        description: 'Menghapus hewan adopsi $animalName',
      );
    } catch (e) {
      throw Exception('Failed to delete animal: $e');
    }
  }

  /// UC-003: Customer books an animal.
  /// Uses a transaction to ensure first-come-first-served logic and prevents double-booking.
  Future<void> requestAdoption(String animalId, String userId, {DateTime? pickupDate, String? pickupTime}) async {
    final docRef = _firestore.collection(_collectionPath).doc(animalId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('Animal does not exist.');
        }

        final data = snapshot.data()!;
        final status = data['status'] ?? 'available';

        if (status != 'available') {
          throw Exception('Animal is no longer available.');
        }

        final updateData = <String, dynamic>{
          'status': 'booked',
          'bookedBy': userId,
        };
        if (pickupDate != null) {
          updateData['pickupDate'] = Timestamp.fromDate(pickupDate);
        }
        if (pickupTime != null) {
          updateData['pickupTime'] = pickupTime;
        }

        transaction.update(docRef, updateData);
      });
    } catch (e) {
      throw Exception('Failed to request adoption: $e');
    }
  }

  /// UC-010: Admin verifies and marks adoption as complete.
  Future<void> markAsAdopted(String animalId) async {
    try {
      final animalDoc = await _firestore.collection(_collectionPath).doc(animalId).get();
      final animalName = animalDoc.data()?['name'] ?? 'Hewan';

      await _firestore.collection(_collectionPath).doc(animalId).update({
        'status': 'adopted',
      });

      await AdminLogService.instance.logAction(
        adminName: FirebaseAuth.instance.currentUser?.displayName ?? 'Min Pet',
        actionType: 'APPROVE_ADOPTION',
        description: 'Menyetujui adopsi hewan $animalName',
      );
    } catch (e) {
      throw Exception('Failed to mark as adopted: $e');
    }
  }

  /// UC-010: Admin cancels the adoption and resets status to available.
  Future<void> cancelAdoption(String animalId) async {
    try {
      final animalDoc = await _firestore.collection(_collectionPath).doc(animalId).get();
      final animalName = animalDoc.data()?['name'] ?? 'Hewan';

      // PERBAIKAN: Update status di Firestore menjadi available kembali dan hapus data booking
      await _firestore.collection(_collectionPath).doc(animalId).update({
        'status': 'available',
        'bookedBy': FieldValue.delete(),
        'pickupDate': FieldValue.delete(),
        'pickupTime': FieldValue.delete(),
      });

      await AdminLogService.instance.logAction(
        adminName: FirebaseAuth.instance.currentUser?.displayName ?? 'Min Pet',
        actionType: 'CANCEL_ADOPTION',
        description: 'Membatalkan proses adopsi hewan $animalName',
      );
    } catch (e) {
      throw Exception('Failed to cancel adoption: $e');
    }
  }

  /// Admin denies the cancellation request and resets status back to booked.
  Future<void> denyCancelAdoption(String animalId) async {
    try {
      // PERBAIKAN: Mengambil data dokumen terlebih dahulu agar mendapatkan variabel animalName
      final animalDoc = await _firestore.collection(_collectionPath).doc(animalId).get();
      final animalName = animalDoc.data()?['name'] ?? 'Hewan';

      // PERBAIKAN: Memastikan status tetap/kembali 'booked' jika permintaan pembatalan ditolak
      await _firestore.collection(_collectionPath).doc(animalId).update({
        'status': 'booked',
      });

      await AdminLogService.instance.logAction(
        adminName: FirebaseAuth.instance.currentUser?.displayName ?? 'Min Pet',
        actionType: 'DENY_CANCEL_ADOPTION',
        description: 'Menolak pembatalan adopsi hewan $animalName',
      );
    } catch (e) {
      throw Exception('Failed to deny cancellation: $e');
    }
  }

  /// Stream of animals adopted/booked by a specific user.
  Stream<List<AnimalModel>> getAdoptionsByUser(String userId) {
    return _firestore
        .collection(_collectionPath)
        .where('bookedBy', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AnimalModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}