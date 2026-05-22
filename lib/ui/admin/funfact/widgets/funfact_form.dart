import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petshopapp/models/funfact_banner_model.dart';
import 'package:petshopapp/services/imgbb_service.dart';

class FunFactForm extends StatefulWidget {
  final Function(FunFactBannerModel) onSubmit;

  const FunFactForm({
    super.key,
    required this.onSubmit,
  });

  @override
  State<FunFactForm> createState() => _FunFactFormState();
}

class _FunFactFormState extends State<FunFactForm> {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final topicController = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageName;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      final bytes = await xFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = xFile.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Banner Title',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: titleController,
            decoration: InputDecoration(
              hintText: 'Tahukah Kamu?',
              filled: true,
              fillColor: const Color(0xFFF1F5FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Description',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            maxLines: 4,
            controller: descController,
            decoration: InputDecoration(
               hintText: 'Masukkan deskripsi fun fact...',
              filled: true,
              fillColor: const Color(0xFFF1F5FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Topik Chat Admin',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: topicController,
            decoration: InputDecoration(
               hintText: 'Contoh: Tips grooming kucing',
              filled: true,
              fillColor: const Color(0xFFF1F5FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            'Background Image',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Center(
            child: InkWell(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade400),
                  image: _imageBytes != null
                      ? DecorationImage(
                          image: MemoryImage(_imageBytes!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imageBytes == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Pilih Background Fun Fact', style: TextStyle(color: Colors.grey)),
                        ],
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () async {
                if (titleController.text.isEmpty ||
                    descController.text.isEmpty ||
                    _imageBytes == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Semua field dan gambar wajib diisi"),
                    ),
                  );
                  return;
                }

                setState(() => _isLoading = true);

                try {
                  final imageUrl = await ImgbbService.uploadImageBytes(_imageBytes!, _imageName ?? 'funfact.jpg');
                  
                  widget.onSubmit(
                    FunFactBannerModel(
                      id: '', // Firestore auto ID
                      title: titleController.text,
                      description: descController.text,
                      imageUrl: imageUrl,
                      topic: topicController.text,
                      createdAt: DateTime.now(),
                      isActive: true,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Publish Banner',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
            ),
          )
        ],
      ),
    );
  }
}