import 'dart:async';
import 'package:flutter/material.dart';
import 'package:petshopapp/models/product_model.dart';
import 'package:petshopapp/models/cart_model.dart';
import 'package:petshopapp/services/firestore_service.dart';

class CartProvider with ChangeNotifier {
  String? _userId;
  List<CartModel> _items = [];
  StreamSubscription<List<CartModel>>? _cartSubscription;

  CartProvider();

  /// Updates the provider with the current user ID and re-initializes the stream.
  void update(String? newUserId) {
    if (_userId == newUserId) return;
    
    debugPrint('[CART_DEBUG] User ID updated: $newUserId');
    _userId = newUserId;
    _initCartListener();
  }

  List<CartModel> get items => _items;

  int get totalItems => _items.fold(0, (sum, item) => sum + item.jumlah);

  double get totalPrice => _items.fold(0.0, (sum, item) => sum + (item.hargaSatuan * item.jumlah));

  void _initCartListener() {
    _cartSubscription?.cancel();
    _cartSubscription = null;

    if (_userId != null && _userId!.isNotEmpty) {
      debugPrint('[CART_DEBUG] Starting Firestore stream for UID: $_userId');
      _cartSubscription = FirestoreService.instance.getCartStream(_userId!).listen(
        (items) {
          debugPrint('[CART_DEBUG] Received ${items.length} items from Firestore');
          _items = items;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('[CART_DEBUG] Firestore Stream Error: $error');
        },
      );
    } else {
      debugPrint('[CART_DEBUG] No active UID, clearing cart items.');
      _items = [];
      notifyListeners();
    }
  }

  /// Manually refreshes the cart listener. Useful when opening the cart UI.
  void refresh() {
    debugPrint('[CART_DEBUG] Manual refresh triggered');
    _initCartListener();
  }

  Future<void> addItem(ProductModel product) async {
    if (_userId == null) {
      debugPrint('[CART_DEBUG] Cannot add item: userId is null');
      return;
    }

    final cartItem = CartModel(
      cartId: '',
      customerId: _userId!,
      productId: product.productId,
      nama: product.namaProduk,
      hargaSatuan: product.harga.toDouble(),
      jumlah: 1,
      fotoUrl: product.fotoUrl,
    );

    debugPrint('[CART_DEBUG] Adding item to Firestore: ${product.namaProduk}');
    await FirestoreService.instance.addToCart(cartItem);
  }

  Future<void> incrementQuantity(String cartId) async {
    await FirestoreService.instance.updateCartQuantity(cartId, 1);
  }

  Future<void> decrementQuantity(CartModel item) async {
    if (item.jumlah > 1) {
      await FirestoreService.instance.updateCartQuantity(item.cartId, -1);
    } else {
      await FirestoreService.instance.removeFromCart(item.cartId);
    }
  }

  Future<void> removeItem(String cartId) async {
    await FirestoreService.instance.removeFromCart(cartId);
  }

  Future<void> clearCart() async {
    if (_userId != null) {
      await FirestoreService.instance.clearCart(_userId!);
    }
  }

  @override
  void dispose() {
    debugPrint('[CART_DEBUG] Disposing CartProvider');
    _cartSubscription?.cancel();
    super.dispose();
  }
}
