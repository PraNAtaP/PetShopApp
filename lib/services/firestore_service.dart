import 'package:flutter/foundation.dart';
import 'package:petshopapp/models/user_model.dart';
import 'package:petshopapp/models/user_address_model.dart';
import 'package:petshopapp/models/product_model.dart';
import 'package:petshopapp/models/user_pet_model.dart';

import 'package:petshopapp/models/cart_model.dart';
import 'package:petshopapp/models/order_model.dart';
import 'package:petshopapp/models/funfact_banner_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petshopapp/services/fcm_service.dart';


/// Service to handle Cloud Firestore CRUD operations for Pet Point.
/// Utilizes the Repository pattern and `.withConverter` for type safety.
///
/// Example Usage:
/// ```dart
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

  CollectionReference<ProductModel> get _productsRef =>
      _db.collection('products').withConverter<ProductModel>(
        fromFirestore: (snapshot, _) => ProductModel.fromFirestore(snapshot),
        toFirestore: (model, _) => model.toMap(),
      );

  CollectionReference<CartModel> get _cartsRef =>
      _db.collection('carts').withConverter<CartModel>(
        fromFirestore: (snapshot, _) => CartModel.fromFirestore(snapshot),
        toFirestore: (model, _) => model.toMap(),
      );

  CollectionReference<OrderModel> get _ordersRef =>
      _db.collection('orders').withConverter<OrderModel>(
        fromFirestore: (snapshot, _) => OrderModel.fromFirestore(snapshot),
        toFirestore: (model, _) => model.toMap(),
      );

  CollectionReference<UserPetModel> get _userPetsRef =>
      _db.collection('user_pets').withConverter<UserPetModel>(
        fromFirestore: (snapshot, _) => UserPetModel.fromFirestore(snapshot),
        toFirestore: (model, _) => model.toMap(),
      );

  CollectionReference<FunFactBannerModel> get _funFactBannersRef =>
      _db.collection('funfact').withConverter<FunFactBannerModel>(
        fromFirestore: (snapshot, _) => FunFactBannerModel.fromFirestore(snapshot),
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

  /// Updates the user's FCM token in Firestore.
  Future<void> updateUserFcmToken(String uid, String token) async {
    try {
      await _db.collection('users').doc(uid).update({
        'fcm_token': token,
      });
    } catch (e) {
      throw Exception('Gagal memperbarui FCM token: $e');
    }
  }

  // ==========================================
  // Address Book Management
  // ==========================================

  CollectionReference<UserAddressModel> _userAddressesRef(String uid) =>
      _db.collection('users').doc(uid).collection('addresses').withConverter<UserAddressModel>(
        fromFirestore: (snapshot, _) => UserAddressModel.fromFirestore(snapshot),
        toFirestore: (model, _) => model.toMap(),
      );

  Stream<List<UserAddressModel>> getUserAddressesStream(String uid) {
    try {
      return _userAddressesRef(uid)
          .orderBy('is_primary', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      throw Exception('Gagal stream data alamat: $e');
    }
  }

  Future<void> addUserAddress(String uid, UserAddressModel address) async {
    try {
      if (address.isPrimary) {
        // If this new address is primary, we should unset others
        final query = await _userAddressesRef(uid).where('is_primary', isEqualTo: true).get();
        final batch = _db.batch();
        for (var doc in query.docs) {
          batch.update(doc.reference, {'is_primary': false});
        }
        await batch.commit();
      }
      
      if (address.id.isEmpty) {
        await _userAddressesRef(uid).add(address);
      } else {
        await _userAddressesRef(uid).doc(address.id).set(address);
      }
    } catch (e) {
      throw Exception('Gagal menyimpan alamat: $e');
    }
  }

  Future<void> deleteUserAddress(String uid, String addressId) async {
    try {
      await _userAddressesRef(uid).doc(addressId).delete();
    } catch (e) {
      throw Exception('Gagal menghapus alamat: $e');
    }
  }

  Future<void> setPrimaryAddress(String uid, String addressId) async {
    try {
      final batch = _db.batch();
      // Unset all primary
      final query = await _userAddressesRef(uid).get();
      for (var doc in query.docs) {
        batch.update(doc.reference, {'is_primary': doc.id == addressId});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Gagal mengubah alamat utama: $e');
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

  /// Adds a new product to the database.
  Future<void> addProduct(ProductModel product) async {
    try {
      if (product.productId.isEmpty) {
        await _productsRef.add(product);
      } else {
        await _productsRef.doc(product.productId).set(product);
      }
    } catch (e) {
      throw Exception('Gagal menambahkan produk: $e');
    }
  }

  /// Deletes a product from the database.
  Future<void> deleteProduct(String productId) async {
    try {
      await _productsRef.doc(productId).delete();
    } catch (e) {
      throw Exception('Gagal menghapus produk: $e');
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
  // Cart Management
  // ==========================================

  /// Returns a real-time stream of cart items for a specific customer.
  Stream<List<CartModel>> getCartStream(String customerId) {
    try {
      debugPrint('Firestore: Streaming cart for customerId: $customerId');
      return _cartsRef
          .where('customer_id', isEqualTo: customerId)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      debugPrint('Firestore Error (getCartStream): $e');
      throw Exception('Gagal stream data keranjang: $e');
    }
  }

  /// Adds an item to the cart or increments quantity if it already exists.
  Future<void> addToCart(CartModel item) async {
    try {
      final existingItems = await _cartsRef
          .where('customer_id', isEqualTo: item.customerId)
          .where('product_id', isEqualTo: item.productId)
          .limit(1)
          .get();

      if (existingItems.docs.isNotEmpty) {
        final docId = existingItems.docs.first.id;
        await _cartsRef.doc(docId).update({
          'jumlah': FieldValue.increment(item.jumlah),
        });
      } else {
        await _cartsRef.add(item);
      }
    } catch (e) {
      throw Exception('Gagal menambahkan ke keranjang: $e');
    }
  }

  /// Updates the quantity of a specific cart item.
  /// Use a negative [quantity] to reduce.
  Future<void> updateCartQuantity(String cartId, int quantity) async {
    try {
      await _cartsRef.doc(cartId).update({
        'jumlah': FieldValue.increment(quantity),
      });
    } catch (e) {
      throw Exception('Gagal memperbarui jumlah keranjang: $e');
    }
  }

  /// Removes a specific item from the cart.
  Future<void> removeFromCart(String cartId) async {
    try {
      await _cartsRef.doc(cartId).delete();
    } catch (e) {
      throw Exception('Gagal menghapus item keranjang: $e');
    }
  }

  /// Clears all cart items for a specific customer.
  Future<void> clearCart(String customerId) async {
    try {
      final snapshot = await _cartsRef
          .where('customer_id', isEqualTo: customerId)
          .get();

      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Gagal mengosongkan keranjang: $e');
    }
  }

  // ==========================================
  // Order Management
  // ==========================================

  /// Creates a new order in Firestore. Returns the generated document ID.
  Future<String> createOrder(OrderModel order) async {
    try {
      final docRef = _ordersRef.doc();
      final newOrder = order.copyWith(orderId: docRef.id);

      await _db.runTransaction((transaction) async {
        final productRefs = newOrder.items.map((item) => _productsRef.doc(item.productId)).toList();
        final List<DocumentSnapshot<ProductModel>> snapshots = [];
        
        for (final ref in productRefs) {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) {
            throw Exception('Produk tidak ditemukan atau sudah dihapus.');
          }
          snapshots.add(snapshot);
        }

        for (int i = 0; i < newOrder.items.length; i++) {
          final item = newOrder.items[i];
          final product = snapshots[i].data()!;
          if (product.stok < item.jumlah) {
            throw Exception('Stok tidak mencukupi untuk ${product.namaProduk} (Sisa: ${product.stok})');
          }
        }

        for (int i = 0; i < newOrder.items.length; i++) {
          final item = newOrder.items[i];
          final ref = productRefs[i];
          final product = snapshots[i].data()!;
          
          transaction.update(ref, {
            'stok': product.stok - item.jumlah,
            'terjual': product.terjual + item.jumlah,
          });
        }
        
        transaction.set(docRef, newOrder);
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Gagal membuat pesanan: $e');
    }
  }

  /// Updates the payment status of an order.
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'status_bayar': status,
      });
    } catch (e) {
      throw Exception('Gagal memperbarui status pesanan: $e');
    }
  }

  /// Updates both payment and shipping status of an order (Admin).
  Future<void> updateOrderFullStatus({
    required String orderId, 
    String? statusBayar, 
    String? statusPengiriman
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (statusBayar != null) updates['status_bayar'] = statusBayar;
      if (statusPengiriman != null) updates['status_pengiriman'] = statusPengiriman;
      
      if (updates.isNotEmpty) {
        await _db.collection('orders').doc(orderId).update(updates);

        // -- Trigger FCM Notification ke Customer --
        if (statusPengiriman != null) {
          try {
            final orderDoc = await _db.collection('orders').doc(orderId).get();
            final uid = orderDoc.data()?['customer_id'] as String?;
            
            if (uid != null) {
              final customerDoc = await _db.collection('users').doc(uid).get();
              final fcmToken = customerDoc.data()?['fcm_token'] as String?;
              
              if (fcmToken != null && fcmToken.isNotEmpty) {
                String title = 'Status Pesanan Diperbarui';
                String body = 'Status pengiriman pesananmu (#${orderId.substring(0, 5)}) menjadi: $statusPengiriman';

                if (statusPengiriman == 'Dikirim' || statusPengiriman == 'Sedang Dikirim') {
                  title = 'Pesanan Sedang Diantar! 📦';
                  body = 'Siap-siap! Pesanan dari Pet Point sedang dalam perjalanan menuju alamatmu.';
                } else if (statusPengiriman == 'Selesai' || statusPengiriman == 'Terkirim') {
                  title = 'Pesanan Telah Sampai 🎉';
                  body = 'Hore! Pesananmu sudah tiba. Terima kasih telah berbelanja di Pet Point.';
                }

                await FCMService.instance.sendNotification(
                  targetFCMToken: fcmToken,
                  title: title,
                  body: body,
                );
              }
            }
          } catch (e) {
            print('Gagal kirim notif order status: $e');
          }
        }
      }
    } catch (e) {
      throw Exception('Gagal memperbarui status pesanan: $e');
    }
  }

  /// Saves the payment proof URL to an existing order.
  Future<void> updateOrderPaymentProof(String orderId, String url) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'bukti_bayar_url': url,
      });
    } catch (e) {
      throw Exception('Gagal menyimpan bukti pembayaran: $e');
    }
  }

  /// Submits a request to cancel a shop order.
  Future<void> requestCancelOrder({
    required String orderId,
    String? bankName,
    String? bankAccount,
    String? accountHolder,
  }) async {
    try {
      final updates = <String, dynamic>{
        'cancel_request': true,
        'status_pengiriman': 'Menunggu Persetujuan Pembatalan',
      };
      if (bankName != null) updates['cancel_bank_name'] = bankName;
      if (bankAccount != null) updates['cancel_bank_account'] = bankAccount;
      if (accountHolder != null) updates['cancel_account_holder'] = accountHolder;

      await _db.collection('orders').doc(orderId).update(updates);
    } catch (e) {
      throw Exception('Gagal mengajukan pembatalan pesanan: $e');
    }
  }

  /// Returns a real-time stream of orders for a specific customer.
  Stream<List<OrderModel>> getOrdersStream(String customerId) {
    try {
      return _ordersRef
          .where('customer_id', isEqualTo: customerId)
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs.map((doc) => doc.data()).toList();
            list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
            return list;
          });
    } catch (e) {
      throw Exception('Gagal stream data pesanan: $e');
    }
  }

  /// Returns a real-time stream of ALL orders (for Admin).
  Stream<List<OrderModel>> getAllOrdersStream() {
    try {
      return _ordersRef
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      // If index is missing, fallback to unordered
      return _ordersRef
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs.map((doc) => doc.data()).toList();
            list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
            return list;
          });
    }
  }

  // ==========================================
  // User Pet Management
  // ==========================================

  /// Adds a new user pet to Firestore.
  Future<void> addUserPet(UserPetModel pet) async {
    try {
      await _userPetsRef.add(pet);
    } catch (e) {
      throw Exception('Gagal mendaftarkan hewan: $e');
    }
  }

  /// Returns a real-time stream of pets for a specific user.
  Stream<List<UserPetModel>> getUserPets(String userId) {
    try {
      return _userPetsRef
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      throw Exception('Gagal stream data hewan user: $e');
    }
  }

  /// Updates an existing user pet.
  Future<void> updateUserPet(UserPetModel pet) async {
    try {
      if (pet.id == null) throw Exception('Pet ID tidak ditemukan');
      await _userPetsRef.doc(pet.id).update(pet.toMap());
    } catch (e) {
      throw Exception('Gagal memperbarui data hewan: $e');
    }
  }

  /// Deletes a user pet.
  Future<void> deleteUserPet(String petId) async {
    try {
      await _userPetsRef.doc(petId).delete();
    } catch (e) {
      throw Exception('Gagal menghapus data hewan: $e');
    }
  }

  // =========================
  // GET FUNFACTS
  // =========================

  Stream<List<FunFactBannerModel>>
      getFunFact() {

    return _db
        .collection('funfact')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map((snapshot) {

      return snapshot.docs.map((doc) {

        return FunFactBannerModel
            .fromFirestore(doc);

      }).toList();
    });
  }

  // =========================
  // ADD
  // =========================

  Future<void> addFunFact(
    FunFactBannerModel banner,
  ) async {

    await _db
        .collection('funfact')
        .add(
          banner.toMap(),
        );
  }

  // =========================
  // UPDATE
  // =========================

  Future<void> updateFunFact(
    FunFactBannerModel banner,
  ) async {
    await _db
        .collection('funfact')
        .doc(banner.id)
        .update(
          banner.toMap(),
        );
  }

  // =========================
  // DELETE
  // =========================

  Future<void> deleteFunFact(
    String id,
  ) async {

    await _db
        .collection('funfact')
        .doc(id)
        .delete();
  }

  // =========================
  // TOGGLE ACTIVE
  // =========================

  Future<void> toggleFunFactStatus(
    String id,
    bool currentStatus,
  ) async {

    await _db
        .collection('funfact')
        .doc(id)
        .update({

      'isActive':
          !currentStatus,
    });
  }
}