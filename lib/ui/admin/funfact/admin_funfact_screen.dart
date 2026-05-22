import 'package:flutter/material.dart';
import 'package:petshopapp/models/funfact_banner_model.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'widgets/funfact_form.dart';
import 'widgets/edit_funfact_dialog.dart';
class AdminFunFactScreen extends StatelessWidget {
  const AdminFunFactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFDFF1FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF248EFC),
        elevation: 0,
        title: const Text('Kelola Banner FunFact'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// ADD BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) {
                      return Dialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: SizedBox(
                          width: 500,
                          child: SingleChildScrollView(
                            child: FunFactForm(
                              onSubmit: (banner) async {
                                Navigator.pop(dialogContext);
                                await firestoreService.addFunFact(banner);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Berhasil publish FunFact"),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.add, size: 24),
                label: const Text(
                  "Tambah Banner Baru",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF248EFC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            const SizedBox(height: 25),

            /// LIST DATA FIRESTORE
            StreamBuilder<List<FunFactBannerModel>>(
              stream: firestoreService.getFunFact(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final banners = snapshot.data!;

                if (banners.isEmpty) {
                  return const Text("Belum ada data");
                }

                return ListView.builder(
                  itemCount: banners.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final item = banners[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        image: DecorationImage(
                          image: NetworkImage(item.imageUrl.isNotEmpty 
                              ? item.imageUrl 
                              : 'https://via.placeholder.com/400x200?text=Fun+Fact'),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withAlpha(120),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// TITLE
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          /// DESCRIPTION
                          Text(
                            item.description,
                            style: const TextStyle(color: Colors.white),
                          ),

                          const SizedBox(height: 10),

                          /// TOPIC
                          Text(
                            'Topik: ${item.topic}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          /// DATE
                          Text(
                            'Dibuat: ${item.createdAt}',
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 15),

                          /// BUTTONS
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    firestoreService.toggleFunFactStatus(
                                      item.id,
                                      item.isActive,
                                    );
                                  },
                                  child: Text(
                                    item.isActive
                                        ? 'Nonaktifkan'
                                        : 'Aktifkan',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => EditFunFactDialog(funFact: item),
                                    );
                                  },
                                  child: const Text("Edit"),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () {
                                    firestoreService.deleteFunFact(item.id);
                                  },
                                  child: const Text("Delete"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}