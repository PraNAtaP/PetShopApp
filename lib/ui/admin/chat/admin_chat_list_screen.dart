import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/chat_room_model.dart';
import 'package:petshopapp/services/chat_service.dart';
import 'package:petshopapp/ui/customer/chat/chat_screen.dart';

class AdminChatListScreen extends StatelessWidget {
  const AdminChatListScreen({super.key});

  Future<Map<String, String>> _fetchUserInfo(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'nama': data['nama'] ?? 'Tanpa Nama',
          'fotoUrl': data['foto_url'] ?? '',
        };
      }
      return {'nama': 'Pelanggan', 'fotoUrl': ''};
    } catch (_) {
      return {'nama': 'Pelanggan', 'fotoUrl': ''};
    }
  }

  @override
  Widget build(BuildContext context) {
    final ChatService chatService = ChatService();
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      // 1. DIKOSONGKAN/DIHAPUS APPBAR-NYA AGAR TIDAK DOUBLE ATAU TERPOTONG DI WEB DASHBOARD
      body: Padding(
        padding: const EdgeInsets.all(24.0), // Jarak luar konten agar tidak menempel ke tepi
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. TITLE BARU DI DALAM BODY UTAMA
            Padding(
              padding: EdgeInsets.only(
                left: MediaQuery.of(context).size.width * 0.35, // Memberikan jarak kiri sebesar 35% dari lebar layar web
              ),
              child: const Text(
                'Chat Pelanggan',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlue, // Warna biru muda
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 16), // Jarak antara title dengan garis pembatas
            
            // Garis tipis pembatas estetik bawah judul
            Container(
              height: 1,
              color: Colors.grey[200],
            ),
            const SizedBox(height: 12), // Jarak antara garis dengan list chat

            // 3. DAFTAR LIST CHAT KAMU YANG DIBUNGKUS EXPANDED
            Expanded(
              child: StreamBuilder<List<ChatRoomModel>>(
                stream: chatService.getChatRooms(currentUid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final rooms = snapshot.data ?? [];

                  if (rooms.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text('Belum ada chat dari pelanggan.', 
                            style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    // Padding internal list dinonaktifkan karena sudah dihandle padding atas Scaffold
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: rooms.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      final otherUid = room.participants.firstWhere(
                        (id) => id != currentUid, 
                        orElse: () => room.participants.isNotEmpty ? room.participants.first : 'User'
                      );
                      
                      return FutureBuilder<Map<String, String>>(
                        future: _fetchUserInfo(otherUid),
                        builder: (context, infoSnapshot) {
                          final info = infoSnapshot.data;
                          final displayName = info?['nama'] ?? room.customerName ?? 'Loading...';
                          final photoUrl = info?['fotoUrl'] ?? '';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                              child: photoUrl.isEmpty 
                                  ? const Icon(Icons.person, color: AppColors.primary) 
                                  : null,
                            ),
                            title: Text(
                              displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Row(
                              children: [
                                if (room.lastMessage?.contains('📷 Foto') ?? false)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Icon(Icons.camera_alt, size: 14, color: Colors.grey),
                                  ),
                                Expanded(
                                  child: Text(
                                    room.lastMessage ?? 'Belum ada pesan',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (room.lastTime != null)
                                  Text(
                                    DateFormat('HH:mm').format(room.lastTime!),
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                              ],
                            ),
                            onTap: () {
                              context.push('/chat', extra: {
                                'receiverId': otherUid,
                                'receiverName': displayName,
                              });
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}