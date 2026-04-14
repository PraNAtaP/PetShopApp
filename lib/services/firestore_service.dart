import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/pet_model.dart';
import '../models/product_model.dart';
import '../models/grooming_booking_model.dart';

/// Service to handle Cloud Firestore CRUD operations for Pet Point.
/// Utilizes the Repository pattern and `.withConverter` for type safety.
///
/// Example Usage:
/// ```dart
/// StreamBuilder<List<PetModel>>(
///   stream: FirestoreService.instance.getAllPets(),
///   builder: (context, snapshot) {
///     if (snapshot.connectionState == ConnectionState.waiting) {
///       return const CircularProgressIndicator();
///     }
///     if (snapshot.hasError) {
///       return Text('Error: ${snapshot.error}');
///     }
///     final pets = snapshot.data ?? [];
///     return ListView.builder(
///       itemCount: pets.length,
///       itemBuilder: (context, index) {
///         return Text(pets[index].namaHewan);
///       },
///     );
///   },
/// );
/// ```
class FirestoreService {
  FirestoreService._privateConstructor();
  
  /// Singleton instance of the FirestoreService.
  static final FirestoreService instance = FirestoreService._privateConstructor();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Collection References with Type Converters ---

  CollectionReference<UserModel> get _usersRef => 
      _db.collection('users').withConverter<UserModel>(
        fromFirestore: (snapshot, _) => UserModel.fromFirestore(snapshot),
        toFirestore: (model, _) => model.toFirestore(),
      );

  CollectionReference<PetModel> get _petsRef =>
      _db.collection('pets').withConverter<PetModel>(
        fromFirestore: (snapshot, _) => PetModel.fromFirestore(snapshot),
        toFirestore: (model, _) => model.toMap(),
      );

  CollectionReference<ProductModel> get _productsRef =>
      _db.collection('products').withConverter<ProductModel>(
        fromFirestore: (snapshot, _) => ProductModel.fromFirestore(snapshot),
        toFirestore: (model, _) => model.toMap(),
      );

  CollectionReference<GroomingBookingModel> get _bookingsRef =>
      _db.collection('grooming_bookings').withConverter<GroomingBookingModel>(
        fromFirestore: (snapshot, _) => GroomingBookingModel.fromFirestore(snapshot),
        toFirestore: (model, _) => model.toMap(),
      );

  // ==========================================
  // User Profile
  // ==========================================

  /// Fetches a user profile by UID.
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      return doc.data();
    } catch (e) {
      throw Exception('Gagal mengambil data profil pengguna: $e');
    }
  }

  // ==========================================
  // Pet Management
  // ==========================================

  /// Returns a stream of all pets for real-time updates.
  Stream<List<PetModel>> getAllPets() {
    try {
      return _petsRef
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      throw Exception('Gagal stream data hewan: $e');
    }
  }

  /// Adds a new pet to the database.
  Future<void> addPet(PetModel pet) async {
    try {
      if (pet.petId.isEmpty) {
        await _petsRef.add(pet);
      } else {
        await _petsRef.doc(pet.petId).set(pet);
      }
    } catch (e) {
      throw Exception('Gagal menambahkan hewan: $e');
    }
  }

  // ==========================================
  // Product Shop
  // ==========================================

  /// Fetches products filtered by category (Future).
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      final querySnapshot = await _productsRef
          .where('kategori', isEqualTo: category)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data produk: $e');
    }
  }

  /// Returns a real-time stream of all products, optionally filtered.
  Stream<List<ProductModel>> getProductsStream({String? category}) {
    try {
      Query<ProductModel> query = _productsRef;
      if (category != null && category.isNotEmpty && category != 'Semua') {
        query = query.where('kategori', isEqualTo: category);
      }
      return query.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      throw Exception('Gagal stream data produk: $e');
    }
  }

  /// Updates the stock quantity of a specific product.
  /// Use a negative [quantity] to reduce stock.
  Future<void> updateProductStock(String productId, int quantity) async {
    try {
      await _db.collection('products').doc(productId).update({
        'stok': FieldValue.increment(quantity),
      });
    } catch (e) {
      throw Exception('Gagal memperbarui stok produk: $e');
    }
  }

  // ==========================================
  // Booking
  // ==========================================

  /// Creates a new grooming booking.
  Future<void> createGroomingBooking(GroomingBookingModel booking) async {
    try {
      if (booking.bookingId.isEmpty) {
        await _bookingsRef.add(booking);
      } else {
        await _bookingsRef.doc(booking.bookingId).set(booking);
      }
    } catch (e) {
      throw Exception('Gagal membuat booking grooming: $e');
    }
  }
}
