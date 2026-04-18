import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petshopapp/models/product_model.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'package:petshopapp/services/imgbb_service.dart';
import 'package:petshopapp/core/theme/app_colors.dart';

class AddProductDialog extends StatefulWidget {
  final ProductModel? productToEdit;

  const AddProductDialog({super.key, this.productToEdit});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedCategory = 'Makanan';
  final List<String> _categories = ['Makanan', 'Aksesoris', 'Obat'];

  Uint8List? _imageBytes;
  String? _imageName;
  String? _existingImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.productToEdit != null) {
      final p = widget.productToEdit!;
      _nameController.text = p.namaProduk;
      _priceController.text = p.harga.toInt().toString();
      _stockController.text = p.stok.toString();
      _descController.text = p.deskripsi;
      if (_categories.contains(p.kategori)) {
        _selectedCategory = p.kategori;
      }
      _existingImageUrl = p.fotoUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      final bytes = await xFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = xFile.name;
        _existingImageUrl = null;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null && _existingImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih foto produk terlebih dahulu!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String fotoUrl = _existingImageUrl ?? '';
      if (_imageBytes != null) {
        fotoUrl = await ImgbbService.uploadImageBytes(_imageBytes!, _imageName ?? 'product.jpg');
      }

      final product = ProductModel(
        productId: widget.productToEdit?.productId ?? '',
        namaProduk: _nameController.text.trim(),
        kategori: _selectedCategory,
        harga: double.parse(_priceController.text.trim()),
        stok: int.parse(_stockController.text.trim()),
        deskripsi: _descController.text.trim(),
        fotoUrl: fotoUrl,
        terjual: widget.productToEdit?.terjual ?? 0,
      );

      await FirestoreService.instance.addProduct(product);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.productToEdit == null ? 'Tambah Produk' : 'Edit Produk'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: InkWell(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                        image: _imageBytes != null
                            ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                            : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                                ? DecorationImage(image: NetworkImage(_existingImageUrl!), fit: BoxFit.cover)
                                : null,
                      ),
                      child: (_imageBytes == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty))
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Pilih Foto Foto', style: TextStyle(color: Colors.grey)),
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama Produk', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedCategory = v);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Harga (Rp)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        decoration: const InputDecoration(labelText: 'Stok', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder()),
                  maxLines: 3,
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProduct,
          child: _isLoading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
