import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/order_model.dart';
import 'package:petshopapp/models/product_model.dart';
import 'package:petshopapp/models/grooming_booking_model.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'package:petshopapp/services/grooming_service.dart';

class AdminPosScreen extends StatefulWidget {
  const AdminPosScreen({super.key});

  @override
  State<AdminPosScreen> createState() => _AdminPosScreenState();
}

class _AdminPosScreenState extends State<AdminPosScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  
  // Local cart for POS
  final Map<String, int> _cart = {}; // productId -> quantity
  final Map<String, int> _groomingCart = {}; // groomingId -> quantity
  List<ProductModel> _allProducts = [];
  
  String _searchQuery = '';
  int _selectedTab = 0; // 0 = Produk, 1 = Grooming
  
  // Payment calculations
  double _uangDiterima = 0;
  final TextEditingController _paymentController = TextEditingController();

  final List<Map<String, dynamic>> _groomingServices = [
    {'id': 'g1', 'name': 'Mandi Dasar', 'price': 50000.0, 'icon': Icons.shower},
    {'id': 'g2', 'name': 'Mandi Kutu/Jamur', 'price': 80000.0, 'icon': Icons.bug_report},
    {'id': 'g3', 'name': 'Potong Kuku', 'price': 20000.0, 'icon': Icons.cut},
    {'id': 'g4', 'name': 'Potong Bulu', 'price': 60000.0, 'icon': Icons.content_cut},
    {'id': 'g5', 'name': 'Bersih Telinga', 'price': 25000.0, 'icon': Icons.hearing},
    {'id': 'g6', 'name': 'Paket Lengkap', 'price': 150000.0, 'icon': Icons.stars},
  ];

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  void _addToCart(ProductModel product) {
    if (product.stok <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok habis!')));
      return;
    }
    setState(() {
      final currentQty = _cart[product.productId] ?? 0;
      if (currentQty < product.stok) {
        _cart[product.productId] = currentQty + 1;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok tidak mencukupi!')));
      }
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      final currentQty = _cart[productId] ?? 0;
      if (currentQty > 1) {
        _cart[productId] = currentQty - 1;
      } else {
        _cart.remove(productId);
      }
    });
  }

  void _toggleGroomingInCart(String serviceId) {
    setState(() {
      if (_groomingCart.containsKey(serviceId)) {
        _groomingCart.remove(serviceId);
      } else {
        _groomingCart[serviceId] = 1;
      }
    });
  }

  double _calculateTotal() {
    double total = 0;
    for (var entry in _cart.entries) {
      final product = _allProducts.firstWhere((p) => p.productId == entry.key);
      total += product.harga * entry.value;
    }
    for (var entry in _groomingCart.entries) {
      final service = _groomingServices.firstWhere((s) => s['id'] == entry.key);
      total += (service['price'] as double) * entry.value;
    }
    return total;
  }

  Future<void> _processCheckout() async {
    final total = _calculateTotal();
    
    if (_cart.isEmpty && _groomingCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keranjang masih kosong!')));
      return;
    }

    if (_uangDiterima < total) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uang diterima kurang dari total belanja!')));
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      // Process Physical Products
      if (_cart.isNotEmpty) {
        List<OrderItemModel> orderItems = [];
        for (var entry in _cart.entries) {
          final product = _allProducts.firstWhere((p) => p.productId == entry.key);
          orderItems.add(OrderItemModel(
            productId: product.productId,
            nama: product.namaProduk,
            jumlah: entry.value,
            hargaSatuan: product.harga,
          ));
        }

        final order = OrderModel(
          orderId: '', 
          customerId: 'OFFLINE_CUSTOMER', 
          items: orderItems,
          totalHarga: orderItems.fold(0, (sum, item) => sum + (item.hargaSatuan * item.jumlah)),
          statusBayar: 'Lunas',
          statusPengiriman: 'Selesai', 
          metodePengambilan: 'Offline',
          metodePembayaran: 'Tunai Kasir',
          createdAt: DateTime.now(),
        );
        await FirestoreService.instance.createOrder(order);
      }

      // Process Grooming Services
      if (_groomingCart.isNotEmpty) {
        // Gabungkan nama service
        List<String> serviceNames = [];
        double totalGroomingPrice = 0;
        for (var entry in _groomingCart.entries) {
          final service = _groomingServices.firstWhere((s) => s['id'] == entry.key);
          serviceNames.add('${service['name']} (x${entry.value})');
          totalGroomingPrice += (service['price'] as double) * entry.value;
        }

        final groomingBooking = GroomingBookingModel(
          bookingId: '',
          userId: 'OFFLINE_CUSTOMER',
          customerName: 'Customer Kasir',
          petName: 'Hewan Customer Offline',
          petType: 'Offline',
          serviceType: serviceNames.join(', '),
          bookingDate: DateTime.now(),
          timeSlot: 'Sekarang (Offline)',
          totalPrice: totalGroomingPrice,
          isHomeService: false,
          status: 'Completed',
          metodePembayaran: 'Tunai Kasir',
          createdAt: DateTime.now(),
        );
        await GroomingService.instance.createBooking(groomingBooking);
      }
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        final kembalian = _uangDiterima - total;
        _showSuccessDialog(kembalian);
        
        setState(() {
          _cart.clear();
          _groomingCart.clear();
          _uangDiterima = 0;
          _paymentController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showSuccessDialog(double kembalian) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30),
            SizedBox(width: 10),
            Text('Transaksi Berhasil!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pembayaran kasir offline telah dicatat.'),
            const SizedBox(height: 16),
            Text('Total Uang Kembalian:', style: TextStyle(color: Colors.grey[700])),
            Text(currencyFormatter.format(kembalian), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // LEFT SIDE: Product / Grooming List
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    // Tabs
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => setState(() => _selectedTab = 0),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedTab == 0 ? AppColors.primary : Colors.grey.shade200,
                                foregroundColor: _selectedTab == 0 ? Colors.white : Colors.black87,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(left: Radius.circular(12))),
                              ),
                              child: const Text('Produk Fisik', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => setState(() => _selectedTab = 1),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedTab == 1 ? Colors.purple : Colors.grey.shade200,
                                foregroundColor: _selectedTab == 1 ? Colors.white : Colors.black87,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(12))),
                              ),
                              child: const Text('Layanan Grooming', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search Bar (Only for products)
                    if (_selectedTab == 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Cari Produk...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.toLowerCase();
                            });
                          },
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Grid View
                    Expanded(
                      child: _selectedTab == 0 ? _buildProductGrid() : _buildGroomingGrid(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // RIGHT SIDE: Cart & Payment
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: const Text('Keranjang Kasir', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    
                    // Cart Items
                    Expanded(
                      child: (_cart.isEmpty && _groomingCart.isEmpty)
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text('Keranjang masih kosong', style: TextStyle(color: Colors.grey.shade500)),
                                ],
                              ),
                            )
                          : ListView(
                              children: [
                                // Products
                                if (_cart.isNotEmpty) ...[
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Produk', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                  ),
                                  ..._cart.entries.map((entry) {
                                    final product = _allProducts.firstWhere((p) => p.productId == entry.key);
                                    return ListTile(
                                      title: Text(product.namaProduk, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      subtitle: Text('${currencyFormatter.format(product.harga)} x ${entry.value}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                            onPressed: () => _removeFromCart(entry.key),
                                          ),
                                          Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                                            onPressed: () => _addToCart(product),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                                
                                // Grooming
                                if (_groomingCart.isNotEmpty) ...[
                                  if (_cart.isNotEmpty) const Divider(),
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Grooming', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                                  ),
                                  ..._groomingCart.entries.map((entry) {
                                    final service = _groomingServices.firstWhere((s) => s['id'] == entry.key);
                                    return ListTile(
                                      leading: Icon(service['icon'], color: Colors.purple),
                                      title: Text(service['name'], maxLines: 1, overflow: TextOverflow.ellipsis),
                                      subtitle: Text(currencyFormatter.format(service['price'])),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _toggleGroomingInCart(entry.key),
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            ),
                    ),
                    
                    // Payment Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(top: BorderSide(color: Colors.grey.shade200)),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Pembelian:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(currencyFormatter.format(_calculateTotal()), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _paymentController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Uang Diterima (Rp)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.money),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _uangDiterima = double.tryParse(val) ?? 0;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Kembali:', style: TextStyle(fontSize: 16)),
                              Text(
                                currencyFormatter.format((_uangDiterima - _calculateTotal()).clamp(0, double.infinity)), 
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: (_cart.isEmpty && _groomingCart.isEmpty) || _uangDiterima < _calculateTotal() ? null : _processCheckout,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Bayar & Selesai', style: TextStyle(fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.textDark,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    return StreamBuilder<List<ProductModel>>(
      stream: FirestoreService.instance.getProductsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        _allProducts = snapshot.data ?? [];
        
        // Filter products
        final filteredProducts = _allProducts.where((p) => p.namaProduk.toLowerCase().contains(_searchQuery)).toList();
        
        if (filteredProducts.isEmpty) {
          return const Center(child: Text('Produk tidak ditemukan.'));
        }

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final product = filteredProducts[index];
            final isOutOfStock = product.stok <= 0;
            
            return InkWell(
              onTap: isOutOfStock ? null : () => _addToCart(product),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: product.fotoUrl.isNotEmpty
                                ? Image.network(product.fotoUrl, fit: BoxFit.cover)
                                : Container(color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.namaProduk, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(currencyFormatter.format(product.harga), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Stok: ${product.stok}', style: TextStyle(color: isOutOfStock ? Colors.red : Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (isOutOfStock)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text('HABIS', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGroomingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _groomingServices.length,
      itemBuilder: (context, index) {
        final service = _groomingServices[index];
        final isSelected = _groomingCart.containsKey(service['id']);
        
        return InkWell(
          onTap: () => _toggleGroomingInCart(service['id']),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: isSelected ? Colors.purple : Colors.purple.shade200, width: isSelected ? 3 : 2),
              borderRadius: BorderRadius.circular(12),
              color: isSelected ? Colors.purple.shade100 : Colors.purple.shade50,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(service['icon'], size: 40, color: Colors.purple),
                const SizedBox(height: 8),
                Text(service['name'], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(currencyFormatter.format(service['price']), style: const TextStyle(color: Colors.purple)),
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Icon(Icons.check_circle, color: Colors.purple),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
