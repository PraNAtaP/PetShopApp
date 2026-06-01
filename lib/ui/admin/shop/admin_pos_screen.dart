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
import 'package:petshopapp/services/pdf_invoice_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:universal_html/html.dart' as html;
import 'package:petshopapp/models/grooming_package_model.dart';

class AdminPosScreen extends StatefulWidget {
  const AdminPosScreen({super.key});

  @override
  State<AdminPosScreen> createState() => _AdminPosScreenState();
}

class _AdminPosScreenState extends State<AdminPosScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  
  // Local cart for POS
  final Map<String, int> _cart = {}; // productId -> quantity
  final List<Map<String, dynamic>> _groomingCart = []; // [{package: GroomingPackageModel, petName: String, weight: double, price: double, duration: int}]
  List<ProductModel> _allProducts = [];
  
  String _searchQuery = '';
  int _selectedTab = 0; // 0 = Produk, 1 = Grooming
  
  // Payment calculations
  double _uangDiterima = 0;
  final TextEditingController _paymentController = TextEditingController();
  final TextEditingController _waNumberController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController(); // Added for checkout

  // Grooming Schedule State
  DateTime _selectedGroomingDate = DateTime.now();
  String? _selectedGroomingTimeSlot;
  List<Map<String, dynamic>> _bookedSlots = [];
  bool _isLoadingSlots = false;

  /// Parses "HH:mm" into minutes from midnight
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// Formats minutes from midnight into "HH:mm"
  String _minutesToTime(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  List<Map<String, dynamic>> _generateSlots() {
    final int openTime = 8 * 60;
    final int closeTime = 20 * 60;
    final int maxOrderTime = 19 * 60;
    final int interval = 30;

    int estimatedDuration = 60; // Default estimate for POS if no specific package selected yet
    if (_groomingCart.isNotEmpty) {
      estimatedDuration = 0;
      for (var item in _groomingCart) {
         estimatedDuration += item['duration'] as int;
      }
    }
    
    List<Map<String, int>> bookedRanges = [];
    for (var b in _bookedSlots) {
      final start = _timeToMinutes(b['timeSlot'] as String);
      final duration = (b['durationMinutes'] as int?) ?? 60;
      bookedRanges.add({'start': start, 'end': start + duration});
    }

    List<Map<String, dynamic>> slots = [];
    for (int t = openTime; t <= maxOrderTime; t += interval) {
      final slotEndTime = t + estimatedDuration;
      bool isBooked = false;

      if (slotEndTime > closeTime) {
        isBooked = true;
      }

      if (!isBooked) {
        for (var b in bookedRanges) {
          bool overlap = !(slotEndTime <= b['start']! || t >= b['end']!);
          if (overlap) {
            isBooked = true;
            break;
          }
        }
      }

      if (!isBooked) {
        if (_selectedGroomingDate.year == DateTime.now().year && 
            _selectedGroomingDate.month == DateTime.now().month && 
            _selectedGroomingDate.day == DateTime.now().day) {
          final now = DateTime.now();
          final currentMinutes = now.hour * 60 + now.minute;
          if (t < currentMinutes + 60) {
            isBooked = true;
          }
        }
      }

      slots.add({
        'time': _minutesToTime(t),
        'isBooked': isBooked,
      });
    }
    return slots;
  }

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

  void _showAddPetToGroomingDialog(GroomingPackageModel package) {
    final petNameController = TextEditingController();
    final weightController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Detail Hewan - ${package.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: petNameController,
                decoration: const InputDecoration(labelText: 'Nama Hewan (Contoh: Miko)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(labelText: 'Berat Badan (kg)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final petName = petNameController.text.trim();
                final weightText = weightController.text.trim();
                if (petName.isEmpty || weightText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama dan berat badan harus diisi!')));
                  return;
                }
                final weight = double.tryParse(weightText.replaceAll(',', '.')) ?? 0.0;
                if (weight <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berat badan tidak valid!')));
                  return;
                }

                final price = package.calculatePrice(weight);
                final duration = package.calculateDuration(weight);

                setState(() {
                  _groomingCart.add({
                    'package': package,
                    'petName': petName,
                    'weight': weight,
                    'price': price,
                    'duration': duration,
                  });
                });

                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      }
    );
  }

  double _calculateTotal() {
    double total = 0;
    for (var entry in _cart.entries) {
      final product = _allProducts.firstWhere((p) => p.productId == entry.key);
      total += product.harga * entry.value;
    }
    for (var item in _groomingCart) {
      total += item['price'] as double;
    }
    return total;
  }

  Future<void> _generatePdfReceipt({
    required String? customerName,
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
                ..._groomingCart.map((item) {
                  final service = item['package'] as GroomingPackageModel;
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(child: pw.Text('${service.name} (${item['petName']})', style: const pw.TextStyle(fontSize: 9))),
                      pw.Text(currencyFormatter.format(item['price']), style: const pw.TextStyle(fontSize: 9)),
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
          customerId: (customerName != null && customerName.isNotEmpty) 
              ? 'OFFLINE_CUSTOMER_$customerName' 
              : 'OFFLINE_CUSTOMER', 
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
        for (var item in _groomingCart) {
          final serviceModel = item['package'] as GroomingPackageModel;
          final petName = item['petName'] as String;
          final price = item['price'] as double;
          final duration = item['duration'] as int;

          final booking = GroomingBookingModel(
            bookingId: '',
            userId: 'OFFLINE_CUSTOMER',
            customerName: customerName ?? 'Customer Kasir',
            petName: petName,
            petType: 'Offline',
            serviceType: serviceModel.name,
            bookingDate: _selectedGroomingDate,
            timeSlot: _selectedGroomingTimeSlot ?? 'Sekarang',
            durationMinutes: duration,
            totalPrice: price,
            isHomeService: false,
            status: 'Completed',
            metodePembayaran: 'Tunai Kasir',
            createdAt: DateTime.now(),
          );
          await GroomingService.instance.createBooking(booking);
        }
      }
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        final kembalian = _uangDiterima - total;
        
        // 1. Generate & Share/Download PDF
        await _generatePdfReceipt(
          customerName: customerName,
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

  void _showCheckoutDialog() {
    if (_groomingCart.isNotEmpty && _selectedGroomingTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih jadwal jam grooming terlebih dahulu!')));
      return;
    }

    final formKey = GlobalKey<FormState>();
    final customerNameCtrl = TextEditingController(text: 'Customer Kasir');
    _waNumberController.clear();
    _paymentController.clear();
    
    double uangTunai = 0;
    final total = _calculateTotal();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Checkout & Pembayaran'),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Pembelian:', style: TextStyle(fontSize: 16)),
                            Text(currencyFormatter.format(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: customerNameCtrl,
                          decoration: const InputDecoration(labelText: 'Nama Pelanggan', border: OutlineInputBorder()),
                          validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _waNumberController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'No. WhatsApp (Opsional, kirim nota)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone_android),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _paymentController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Uang Diterima (Rp)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.money),
                          ),
                          onChanged: (val) {
                            setStateDialog(() {
                              uangTunai = double.tryParse(val) ?? 0;
                            });
                          },
                          validator: (v) {
                            if (uangTunai < total) return 'Uang kurang dari total belanja';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Kembali:', style: TextStyle(fontSize: 16)),
                            Text(
                              currencyFormatter.format((uangTunai - total).clamp(0, double.infinity)), 
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
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
                    // Pass uangTunai to state before calling executeCheckout
                    setState(() {
                      _uangDiterima = uangTunai;
                      _customerNameController.text = customerNameCtrl.text;
                    });
                    
                    _executeCheckout(customerName: customerNameCtrl.text);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text('Bayar & Selesai'),
                )
              ],
            );
          },
        );
      },
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
                                  ..._groomingCart.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final item = entry.value;
                                    final service = item['package'] as GroomingPackageModel;
                                    return ListTile(
                                      leading: const Icon(Icons.pets, color: Colors.purple),
                                      title: Text('${service.name} (${item['petName']})', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('${item['weight']} kg - ${currencyFormatter.format(item['price'])}', style: const TextStyle(color: Colors.purple)),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            _groomingCart.removeAt(index);
                                          });
                                        },
                                      ),
                                    );
                                  }).toList(),
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
                          ElevatedButton.icon(
                            onPressed: (_cart.isEmpty && _groomingCart.isEmpty) ? null : _showCheckoutDialog,
                            icon: const Icon(Icons.shopping_cart_checkout),
                            label: const Text('Checkout', style: TextStyle(fontSize: 16)),
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
                                ? CachedNetworkImage(
                                    imageUrl: product.fotoUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator())),
                                    errorWidget: (context, url, error) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)),
                                  )
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
            : Builder(
                builder: (context) {
                  final dynamicSlots = _generateSlots();
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dynamicSlots.map((slotData) {
                      final slot = slotData['time'] as String;
                      final isBooked = slotData['isBooked'] as bool;
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
                  );
                }
              ),
        ],
      ),
    );
  }

  Widget _buildGroomingGrid() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: GroomingPackageModel.availablePackages.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final package = GroomingPackageModel.availablePackages[index];
        // Check if there's any item in the cart that uses this package
        final isSelected = _groomingCart.any((item) => (item['package'] as GroomingPackageModel).name == package.name);
        
        return InkWell(
          onTap: () => _showAddPetToGroomingDialog(package),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300, width: isSelected ? 2 : 1),
              borderRadius: BorderRadius.circular(12),
              color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(package.icon, color: Colors.grey.shade600, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(package.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      const SizedBox(height: 4),
                      Text(
                        '${currencyFormatter.format(package.priceSmall)} - ${currencyFormatter.format(package.priceLarge)}', 
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        package.description, 
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.check_circle, color: AppColors.primary, size: 28),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
