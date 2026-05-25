import 'dart:async';
import 'package:flutter/material.dart';
import 'package:petshopapp/models/product_model.dart';
import 'package:petshopapp/models/cart_model.dart';
import 'package:petshopapp/services/firestore_service.dart';

class CartProvider with ChangeNotifier {
  String? _userId;
  List<CartModel> _items = [];
  StreamSubscription<List<CartModel>>? _cartSubscription;

  // Checkout State
  bool _isDelivery = false;
  String _alamatLengkap = '';
  double? _latitude;
  double? _longitude;

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

  double get subtotal => _items.fold(0.0, (sum, item) => sum + (item.hargaSatuan * item.jumlah));

  double get shippingFee {
    if (!_isDelivery || _alamatLengkap.isEmpty) return 0.0;

    final address = _alamatLengkap.toLowerCase();
    
    // Check if within Kabupaten Malang
    final bool isKabupaten = address.contains('kabupaten malang') || 
                             address.contains('kab. malang') || 
                             address.contains('kab malang');

    if (isKabupaten) {
      if (address.contains('pujon') || address.contains('ngantang') || address.contains('kasembon') || 
          address.contains('dampit') || address.contains('turen') || address.contains('gondanglegi') || 
          address.contains('bantur') || address.contains('sumbermanjing') || address.contains('donomulyo') ||
          address.contains('gedangan') || address.contains('ampelgading') || address.contains('tirtoyudo')) {
        return 20000.0;
      } else if (address.contains('lawang') || address.contains('tumpang') || address.contains('bululawang') || 
                 address.contains('tajinan') || address.contains('kepanjen') || address.contains('jabung') ||
                 address.contains('poncokusumo') || address.contains('pagak') || address.contains('kalipare')) {
        return 15000.0;
      } else if (address.contains('dau') || address.contains('singosari') || address.contains('pakisaji') || 
                 address.contains('karangploso') || address.contains('wagir') || address.contains('pakis')) {
        return 12000.0;
      } else {
        final int hashVal = address.codeUnits.fold(0, (sum, char) => sum + char);
        return 10000.0 + (hashVal % 11) * 1000.0;
      }
    }
    
    return 0.0;
  }

  double get totalPrice => subtotal + shippingFee;

  bool get isDelivery => _isDelivery;
  String get alamatLengkap => _alamatLengkap;
  double? get latitude => _latitude;
  double? get longitude => _longitude;

  void setDelivery(bool value) {
    _isDelivery = value;
    notifyListeners();
  }

  void updateLocationInfo({
    required bool isDelivery,
    required String alamat,
    double? lat,
    double? lng,
  }) {
    _isDelivery = isDelivery;
    _alamatLengkap = alamat;
    _latitude = lat;
    _longitude = lng;
    notifyListeners();
  }

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

  Future<void> addItem(ProductModel product, {int quantity = 1}) async {
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
      jumlah: quantity,
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
