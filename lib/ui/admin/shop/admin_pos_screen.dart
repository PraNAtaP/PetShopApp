import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/order_model.dart';
import 'package:petshopapp/models/product_model.dart';
import 'package:petshopapp/models/grooming_booking_model.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'package:petshopapp/services/grooming_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;

class AdminPosScreen extends StatefulWidget {
  const AdminPosScreen({super.key});

  @override
  State<AdminPosScreen> createState() => _AdminPosScreenState();
}

class _AdminPosScreenState extends State<AdminPosScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  
  // Local cart for POS
  final Map<String, int> _cart = {}; // productId -> quantity
  final Map<String, int> _groomingCart = {}; // serviceId -> 1
  List<ProductModel> _allProducts = [];
  
  String _searchQuery = '';
  int _selectedTab = 0; // 0 = Produk, 1 = Grooming
  
  // Payment calculations
  double _uangDiterima = 0;
  final TextEditingController _paymentController = TextEditingController();
  final TextEditingController _waNumberController = TextEditingController();

  // Grooming Schedule State
  DateTime _selectedGroomingDate = DateTime.now();
  String? _selectedGroomingTimeSlot;
  List<String> _bookedSlots = [];
  bool _isLoadingSlots = false;
  final List<String> _allTimeSlots = ['08:00', '10:00', '12:00', '14:00', '16:00', '18:00'];

  final List<Map<String, dynamic>> _groomingServices = [
    {'id': 'g1', 'name': 'Mandi Dasar', 'price': 50000.0, 'icon': Icons.shower},
    {'id': 'g2', 'name': 'Mandi Kutu/Jamur', 'price': 80000.0, 'icon': Icons.bug_report},
    {'id': 'g3', 'name': 'Potong Kuku', 'price': 20000.0, 'icon': Icons.cut},
    {'id': 'g4', 'name': 'Potong Bulu', 'price': 60000.0, 'icon': Icons.content_cut},
    {'id': 'g5', 'name': 'Bersih Telinga', 'price': 25000.0, 'icon': Icons.hearing},
    {'id': 'g6', 'name': 'Paket Lengkap', 'price': 150000.0, 'icon': Icons.stars},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSlots();
    });
  }

  @override
  void dispose() {
    _paymentController.dispose();
    _waNumberController.dispose();
    super.dispose();
  }

  Future<void> _fetchSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _selectedGroomingTimeSlot = null;
    });
    try {
      final slots = await GroomingService.instance.getBookedSlots(_selectedGroomingDate);
      if (mounted) {
        setState(() {
          _bookedSlots = slots;
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSlots = false);
    }
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
      total += service['price'] as double;
    }
    return total;
  }

  Future<void> _generatePdfReceipt({
    required String? customerName,
    required String? petName,
    required double total,
    required double kembalian,
  }) async {
    final pdf = pw.Document();
    
    // Load logo image
    pw.MemoryImage? logoImage;
    try {
      final ByteData bytes = await rootBundle.load('lib/assets/img/1776076564947.png');
      logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('Could not load logo image: $e');
    }

    final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final dateStr = DateFormat('dd MMM yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Receipt printer format
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoImage != null)
                pw.Center(
                  child: pw.Image(logoImage, width: 60, height: 60),
                ),
              pw.SizedBox(height: 8),
              pw.Center(child: pw.Text('PET POINT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 4),
              pw.Center(child: pw.Text('Nota Pembayaran Kasir', style: const pw.TextStyle(fontSize: 10))),
              pw.SizedBox(height: 12),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('No Nota:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(invoiceNumber, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ]
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tanggal:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(dateStr, style: const pw.TextStyle(fontSize: 9)),
                ]
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Pelanggan:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(customerName ?? 'Offline', style: const pw.TextStyle(fontSize: 9)),
                ]
              ),
              if (petName != null && petName.isNotEmpty) 
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Hewan:', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(petName, style: const pw.TextStyle(fontSize: 9)),
                  ]
                ),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              if (_cart.isNotEmpty) ...[
                pw.Text('Produk Fisik', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.SizedBox(height: 4),
                ..._cart.entries.map((entry) {
                  final product = _allProducts.firstWhere((p) => p.productId == entry.key);
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(child: pw.Text('${product.namaProduk} (${entry.value}x)', style: const pw.TextStyle(fontSize: 9))),
                      pw.Text(currencyFormatter.format(product.harga * entry.value), style: const pw.TextStyle(fontSize: 9)),
                    ],
                  );
                }).toList(),
              ],
              if (_groomingCart.isNotEmpty) ...[
                if (_cart.isNotEmpty) pw.SizedBox(height: 8),
                pw.Text('Layanan Grooming', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text('Jadwal: ${DateFormat('dd MMM').format(_selectedGroomingDate)} - $_selectedGroomingTimeSlot', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                pw.SizedBox(height: 4),
                ..._groomingCart.entries.map((entry) {
                  final service = _groomingServices.firstWhere((s) => s['id'] == entry.key);
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(child: pw.Text(service['name'], style: const pw.TextStyle(fontSize: 9))),
                      pw.Text(currencyFormatter.format(service['price']), style: const pw.TextStyle(fontSize: 9)),
                    ],
                  );
                }).toList(),
              ],
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Bayar', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text(currencyFormatter.format(total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tunai', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(currencyFormatter.format(_uangDiterima), style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Kembali', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(currencyFormatter.format(kembalian), style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Center(child: pw.Text('Terima kasih!', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
              pw.Center(child: pw.Text('Barang yang sudah dibeli tidak dapat ditukar', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700))),
            ],
          );
        },
      ),
    );

    try {
      final bytes = await pdf.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'Nota_PetPoint_${customerName}.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch(e) {
      debugPrint("Error saving PDF: $e");
    }
  }

  Future<void> _executeCheckout({
    String? customerName,
    String? petName,
  }) async {
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

      // Process Grooming Services (Combined into one booking)
      if (_groomingCart.isNotEmpty) {
        List<String> serviceNames = [];
        double totalGroomingPrice = 0;

        for (var entry in _groomingCart.entries) {
          final service = _groomingServices.firstWhere((s) => s['id'] == entry.key);
          serviceNames.add(service['name']);
          totalGroomingPrice += service['price'] as double;
        }

        final booking = GroomingBookingModel(
          bookingId: '',
          userId: 'OFFLINE_CUSTOMER',
          customerName: customerName ?? 'Customer Kasir',
          petName: petName ?? 'Hewan',
          petType: 'Offline', 
          serviceType: serviceNames.join(', '),
          bookingDate: _selectedGroomingDate,
          timeSlot: _selectedGroomingTimeSlot ?? 'Sekarang',
          totalPrice: totalGroomingPrice,
          isHomeService: false,
          status: 'Completed',
          metodePembayaran: 'Tunai Kasir',
          createdAt: DateTime.now(),
        );
        await GroomingService.instance.createBooking(booking);
      }
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        final kembalian = _uangDiterima - total;
        
        // 1. Generate & Share/Download PDF
        await _generatePdfReceipt(
          customerName: customerName,
          petName: petName,
          total: total,
          kembalian: kembalian,
        );

        // 2. Open WhatsApp Logic
        final waNumber = _waNumberController.text;
        if (waNumber.isNotEmpty) {
          String formattedWa = waNumber.replaceAll(RegExp(r'[^0-9]'), '');
          if (formattedWa.startsWith('0')) {
            formattedWa = '62${formattedWa.substring(1)}';
          }
          
          String receiptIntro = "Halo ${customerName ?? 'Kak'}! \nTerima kasih telah berbelanja di Pet Point. Berikut kami lampirkan file Nota Pembayaran Anda.";
          
          final String waUrl = "https://wa.me/$formattedWa?text=${Uri.encodeComponent(receiptIntro)}";
          
          try {
            await launchUrl(Uri.parse(waUrl), mode: LaunchMode.externalApplication);
          } catch(e) {
             // ignore if fails to launch
          }
        }
        
        _showSuccessDialog(kembalian);

        setState(() {
          _cart.clear();
          _groomingCart.clear();
          _uangDiterima = 0;
          _paymentController.clear();
          _waNumberController.clear();
          _selectedGroomingTimeSlot = null; // reset slot
          _fetchSlots(); // refresh slots to reflect new bookings
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showCheckoutGroomingDetailsDialog() {
    final formKey = GlobalKey<FormState>();
    final customerNameCtrl = TextEditingController(text: 'Customer Kasir');
    final petNameCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Detail Pelanggan Grooming'),
        content: SizedBox(
          width: 500,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ada paket grooming di keranjang. Lengkapi data pelanggan:', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: customerNameCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Pelanggan', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Wajib' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: petNameCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Hewan', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Wajib' : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              
              Navigator.pop(context);
              _executeCheckout(
                customerName: customerNameCtrl.text,
                petName: petNameCtrl.text,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Lanjutkan Proses & Bayar'),
          )
        ],
      ),
    );
  }

  void _showConfirmationDialog() {
    if (_groomingCart.isNotEmpty && _selectedGroomingTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih jadwal jam grooming terlebih dahulu!')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.accent, size: 28),
            SizedBox(width: 8),
            Text('Konfirmasi Pesanan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pastikan semua item dan layanan grooming sudah benar sebelum diproses.', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            const Divider(),
            if (_cart.isNotEmpty)
              Text('• ${_cart.length} jenis produk fisik', style: const TextStyle(fontWeight: FontWeight.bold)),
            if (_groomingCart.isNotEmpty)
              Text('• ${_groomingCart.length} layanan grooming', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Pembelian:'),
                Text(currencyFormatter.format(_calculateTotal()), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Uang Diterima:'),
                Text(currencyFormatter.format(_uangDiterima), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              
              if (_groomingCart.isNotEmpty) {
                // If there's grooming, ask for customer details first
                _showCheckoutGroomingDetailsDialog();
              } else {
                // Physical products only, just checkout
                _executeCheckout();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Proses Pembayaran'),
          ),
        ],
      ),
    );
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
                    
                    // Main Content (Grid View or Grooming Content)
                    Expanded(
                      child: _selectedTab == 0 ? _buildProductGrid() : _buildGroomingContent(),
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
                                      title: Text(service['name'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text(currencyFormatter.format(service['price']), style: const TextStyle(color: Colors.purple)),
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
                            controller: _waNumberController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'No. WhatsApp (Opsional, kirim nota)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone_android),
                            ),
                          ),
                          const SizedBox(height: 12),
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
                            onPressed: (_cart.isEmpty && _groomingCart.isEmpty) || _uangDiterima < _calculateTotal() ? null : _showConfirmationDialog,
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

  Widget _buildGroomingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildGroomingSchedulePicker(),
        Expanded(child: _buildGroomingGrid()),
      ],
    );
  }

  Widget _buildGroomingSchedulePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cek Jadwal & Pilih Jam Layanan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 16)),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedGroomingDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    _selectedGroomingDate = picked;
                    _fetchSlots();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.purple.shade200),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month, color: Colors.purple.shade400, size: 18),
                      const SizedBox(width: 8),
                      Text(DateFormat('dd MMM yyyy', 'id_ID').format(_selectedGroomingDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _isLoadingSlots 
            ? const Center(child: CircularProgressIndicator())
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allTimeSlots.map((slot) {
                  final isBooked = _bookedSlots.contains(slot);
                  final isSelected = _selectedGroomingTimeSlot == slot;
                  return ChoiceChip(
                    label: Text(slot),
                    selected: isSelected,
                    onSelected: isBooked ? null : (selected) {
                      if (selected) setState(() => _selectedGroomingTimeSlot = slot);
                    },
                    backgroundColor: isBooked ? Colors.grey.shade300 : Colors.white,
                    selectedColor: Colors.purple.withOpacity(0.2),
                    side: BorderSide(color: isSelected ? Colors.purple : Colors.grey.shade400),
                    labelStyle: TextStyle(
                      color: isBooked ? Colors.grey : (isSelected ? Colors.purple : Colors.black87),
                      decoration: isBooked ? TextDecoration.lineThrough : null,
                    ),
                  );
                }).toList(),
              ),
        ],
      ),
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
