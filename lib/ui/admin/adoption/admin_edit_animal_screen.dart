import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/animal_model.dart';
import 'package:petshopapp/services/adoption_service.dart';
import 'package:petshopapp/services/imgbb_service.dart';

class AdminEditAnimalScreen extends StatefulWidget {
  final AnimalModel animal;

  const AdminEditAnimalScreen({super.key, required this.animal});

  @override
  State<AdminEditAnimalScreen> createState() => _AdminEditAnimalScreenState();
}

class _AdminEditAnimalScreenState extends State<AdminEditAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _breedController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _descriptionController;
  late String _selectedType;
  late String _selectedGender;
  late String _selectedStatus;
  
  XFile? _imageFile;
  bool _isLoading = false;

  final List<String> _animalTypes = ['Kucing', 'Anjing', 'Burung', 'Lainnya'];
  final List<String> _genderOptions = ['Jantan', 'Betina'];
  final List<String> _statusOptions = ['available', 'booked', 'adopted'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.animal.name);
    _breedController = TextEditingController(text: widget.animal.breed);
    _ageController = TextEditingController(text: widget.animal.age);
    _weightController = TextEditingController(text: widget.animal.weight?.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.animal.description);
    _selectedType = _animalTypes.contains(widget.animal.type) ? widget.animal.type : 'Lainnya';
    _selectedGender = _genderOptions.contains(widget.animal.gender) ? widget.animal.gender : 'Jantan';
    _selectedStatus = _statusOptions.contains(widget.animal.status) ? widget.animal.status : 'available';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String imageUrl = widget.animal.imageUrl;

      // 1. Upload new image if selected
      if (_imageFile != null) {
        if (kIsWeb) {
          final bytes = await _imageFile!.readAsBytes();
          imageUrl = await ImgbbService.uploadImageBytes(bytes, _imageFile!.name);
        } else {
          imageUrl = await ImgbbService.uploadImage(File(_imageFile!.path));
        }
      }

      // 2. Update metadata in Firestore
      final updatedData = {
        'name': _nameController.text.trim(),
        'type': _selectedType,
        'gender': _selectedGender,
        'breed': _breedController.text.trim(),
        'age': _ageController.text.trim(),
        'weight': double.tryParse(_weightController.text.trim()),
        'description': _descriptionController.text.trim(),
        'status': _selectedStatus,
        'imageUrl': imageUrl,
      };

      // Clear bookedBy if status is set back to available manually
      if (_selectedStatus == 'available' && widget.animal.status != 'available') {
        await AdoptionService().cancelAdoption(widget.animal.id);
      } else {
        await AdoptionService().updateAnimal(widget.animal.id, updatedData);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data hewan berhasil diperbarui!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui hewan: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Hewan Adopsi', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: kIsWeb
                                    ? Image.network(_imageFile!.path, fit: BoxFit.cover, width: double.infinity)
                                    : Image.file(File(_imageFile!.path), fit: BoxFit.cover, width: double.infinity),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: widget.animal.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) => Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo, size: 48, color: Colors.grey.shade400),
                                      const SizedBox(height: 8),
                                      Text('Ubah Foto', style: TextStyle(color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text('Ketuk foto untuk mengubahnya', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Hewan',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        labelText: 'Jenis Hewan',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _animalTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Jenis Kelamin',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _genderOptions.map((gender) {
                        return DropdownMenuItem(value: gender, child: Text(gender));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedGender = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _breedController,
                      decoration: InputDecoration(
                        labelText: 'Ras (Misal: Persia, Golden)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Ras tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            decoration: InputDecoration(
                              labelText: 'Umur (Misal: 2 Bulan)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Umur tidak boleh kosong' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Berat (kg)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi (Misal: Sehat, lincah, sudah vaksin)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _statusOptions.map((status) {
                        return DropdownMenuItem(value: status, child: Text(status.toUpperCase()));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedStatus = value);
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Simpan Perubahan',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
