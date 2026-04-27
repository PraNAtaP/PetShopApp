import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/services/auth_service.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'package:petshopapp/models/user_pet_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:petshopapp/services/imgbb_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AddEditPetScreen extends StatefulWidget {
  final UserPetModel? pet;
  const AddEditPetScreen({super.key, this.pet});

  @override
  State<AddEditPetScreen> createState() => _AddEditPetScreenState();
}

class _AddEditPetScreenState extends State<AddEditPetScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _breedController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late String _selectedType;
  late String _selectedGender;
  bool _isLoading = false;
  File? _imageFile;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pet?.name);
    _breedController = TextEditingController(text: widget.pet?.breed);
    _ageController = TextEditingController(text: widget.pet?.age);
    _weightController = TextEditingController(text: widget.pet?.weight?.toString());
    _selectedType = widget.pet?.type ?? 'Kucing';
    _selectedGender = widget.pet?.gender ?? 'Jantan';
    _currentImageUrl = widget.pet?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pet == null ? 'Tambah Hewan' : 'Edit Data Hewan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto Section
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                          image: _imageFile != null
                              ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                              : (_currentImageUrl != null
                                  ? DecorationImage(image: NetworkImage(_currentImageUrl!), fit: BoxFit.cover)
                                  : null),
                        ),
                        child: (_imageFile == null && _currentImageUrl == null)
                            ? Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey.shade400)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Informasi Identitas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Hewan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.pets),
                ),
                validator: (v) => v!.isEmpty ? 'Nama harus diisi' : null,
              ),
              const SizedBox(height: 20),
              const Text('Jenis Hewan:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTypeChoice('Kucing'),
                  const SizedBox(width: 12),
                  _buildTypeChoice('Anjing'),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Jenis Kelamin',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ['Jantan', 'Betina']
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedGender = v!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _breedController,
                decoration: InputDecoration(
                  labelText: 'Jenis Ras',
                  hintText: 'Misal: Persia, Golden Retriever, dll',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? 'Ras harus diisi' : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: InputDecoration(
                        labelText: 'Usia',
                        hintText: 'Misal: 2 Tahun',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v!.isEmpty ? 'Usia harus diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Berat (kg)',
                        hintText: 'Misal: 4.5',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Simpan Data Hewan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChoice(String type) {
    final isSelected = _selectedType == type;
    final IconData? icon = null;
    final dynamic faIcon = type == 'Anjing' ? FontAwesomeIcons.dog : FontAwesomeIcons.cat;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              FaIcon(
                faIcon,
                color: isSelected ? AppColors.primary : Colors.grey.shade600,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                type,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text('Pilih Sumber Foto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Kamera'),
            onTap: () async {
              Navigator.pop(context);
              final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
              if (pickedFile != null) {
                setState(() => _imageFile = File(pickedFile.path));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Galeri'),
            onTap: () async {
              Navigator.pop(context);
              final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
              if (pickedFile != null) {
                setState(() => _imageFile = File(pickedFile.path));
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _savePet() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      debugPrint('SavePet: Form validated, starting save...');
      
      final user = context.read<AuthService>().currentUser;
      if (user == null) {
        debugPrint('SavePet: User is null, stopping.');
        setState(() => _isLoading = false);
        return;
      }

      try {
        String? finalImageUrl = _currentImageUrl;

        // Upload baru jika ada file gambar yang dipilih
        if (_imageFile != null) {
          debugPrint('SavePet: Uploading image to ImgBB...');
          finalImageUrl = await ImgbbService.uploadImage(_imageFile!);
          debugPrint('SavePet: Image upload success: $finalImageUrl');
        }

        final petData = UserPetModel(
          id: widget.pet?.id,
          userId: user.uid,
          name: _nameController.text,
          type: _selectedType,
          gender: _selectedGender,
          breed: _breedController.text,
          age: _ageController.text,
          weight: double.tryParse(_weightController.text),
          imageUrl: finalImageUrl,
        );

        debugPrint('SavePet: Saving to Firestore (isEdit: ${widget.pet != null})');
        if (widget.pet == null) {
          await FirestoreService.instance.addUserPet(petData);
        } else {
          await FirestoreService.instance.updateUserPet(petData);
        }
        
        debugPrint('SavePet: Success!');
        if (mounted) Navigator.pop(context);
      } catch (e) {
        debugPrint('SavePet Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
