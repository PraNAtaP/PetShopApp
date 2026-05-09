import 'package:flutter/material.dart';
import 'package:petshopapp/models/funfact_banner_model.dart';
import 'package:petshopapp/services/firestore_service.dart';
import 'widgets/funfact_form.dart';

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
            /// FORM INPUT
            FunFactForm(
              onSubmit: (banner) async {
                print("SUBMIT KE FIRESTORE");

                await firestoreService.addFunFact(banner);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Berhasil publish FunFact"),
                  ),
                );
              },
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
                        gradient: LinearGradient(
                          colors: item.gradientColors
                              .map((e) => Color(e))
                              .toList(),
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
                              const SizedBox(width: 10),
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