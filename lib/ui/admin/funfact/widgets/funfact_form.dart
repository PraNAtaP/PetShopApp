import 'package:flutter/material.dart';
import 'package:petshopapp/models/funfact_banner_model.dart';
import 'emoji_selector.dart';
import 'gradient_selector.dart';


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

  String selectedEmoji = '🐱';

  List<Color> selectedGradient = [
    Colors.blue,
    Colors.lightBlueAccent,
  ];

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
            'Pilih Emoji',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          EmojiSelector(
            onSelect: (emoji) {
              setState(() {
                selectedEmoji = emoji;
              });
            },
          ),
          const SizedBox(height: 25),
          const Text(
            'Background Gradient',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          GradientSelector(
            onSelect: (gradient) {
              setState(() {
                selectedGradient = gradient;
              });
            },
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: selectedGradient,
              ),
            ),
            child: Row(
              children: [
                Text(
                  selectedEmoji,
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleController.text.isEmpty
                            ? 'Preview Banner'
                            : titleController.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        descController.text.isEmpty
                            ? 'Preview deskripsi banner'
                            : descController.text,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
            onPressed: () {
              print("CLICKED BUTTON");

                if (titleController.text.isEmpty ||
                    descController.text.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Semua field wajib diisi"),
                    ),
                );
                    return;
                }

                 widget.onSubmit(
                   FunFactBannerModel(
                    id: '', // Firestore auto ID
                    title: titleController.text,
                    description: descController.text,
                    emoji: selectedEmoji,
                    gradientColors: 
                        selectedGradient.map((e) => e.value).toList(),
                    topic: topicController.text,
                    createdAt: DateTime.now(),
                    isActive: true,
                    ),
                );
              },
               style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Publish Banner',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}