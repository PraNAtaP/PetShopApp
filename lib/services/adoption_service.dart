import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/animal_model.dart';

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

  /// Adds a new animal to the catalog.
  Future<void> addAnimal(AnimalModel animal) async {
    try {
      await _firestore.collection(_collectionPath).add(animal.toMap());
    } catch (e) {
      throw Exception('Failed to add animal: $e');
    }
  }

  /// Updates an existing animal's data.
  Future<void> updateAnimal(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collectionPath).doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update animal: $e');
    }
  }

  /// Deletes an animal from the catalog.
  Future<void> deleteAnimal(String id) async {
    try {
      await _firestore.collection(_collectionPath).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete animal: $e');
    }
  }

  /// UC-003: Customer books an animal.
  /// Uses a transaction to ensure first-come-first-served logic and prevents double-booking.
  Future<void> requestAdoption(String animalId, String userId) async {
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

        transaction.update(docRef, {
          'status': 'booked',
          'bookedBy': userId,
        });
      });
    } catch (e) {
      throw Exception('Failed to request adoption: $e');
    }
  }

  /// UC-010: Admin verifies and marks adoption as complete.
  Future<void> markAsAdopted(String animalId) async {
    try {
      await _firestore.collection(_collectionPath).doc(animalId).update({
        'status': 'adopted',
      });
    } catch (e) {
      throw Exception('Failed to mark as adopted: $e');
    }
  }

  /// UC-010: Admin cancels the adoption and resets status.
  Future<void> cancelAdoption(String animalId) async {
    try {
      await _firestore.collection(_collectionPath).doc(animalId).update({
        'status': 'available',
        'bookedBy': FieldValue.delete(),
      });
    } catch (e) {
      throw Exception('Failed to cancel adoption: $e');
    }
  }
}
