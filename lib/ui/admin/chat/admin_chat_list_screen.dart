import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/chat_room_model.dart';
import 'package:petshopapp/services/chat_service.dart';

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
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. MODIFIKASI: MENAMBAHKAN BACKGROUND BANNER PADA TULISAN CHAT PELANGGAN
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  // Menggunakan warna dasar tema dengan transparansi lembut agar terlihat modern
                  color: AppColors.primary.withValues(alpha: 0.08), 
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Lebar background mengikuti panjang tulisan
                  children: [
                    const Icon(
                      Icons.chat_bubble,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Chat Pelanggan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary, // Menyesuaikan warna utama aplikasi
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), // Jarak antara title banner dengan garis pembatas
            
            Container(
              height: 1,
              color: Colors.grey[200],
            ),
            const SizedBox(height: 12),

            // 2. DAFTAR LIST CHAT YANG MENDUKUNG FITUR HOVER PIN DAN DELETE
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
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: rooms.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
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

                          return HoverableChatTile(
                            displayName: displayName,
                            photoUrl: photoUrl,
                            room: room,
                            onTap: () {
                              context.push('/chat', extra: {
                                'receiverId': otherUid,
                                'receiverName': displayName,
                              });
                            },
                            onPin: () {
                              // Fitur Pin Chat
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Menyematkan chat $displayName')),
                              );
                            },
                            onDelete: () async {
                              // Fitur Hapus Chat Langsung dari Firestore
                              await FirebaseFirestore.instance
                                  .collection('chat_rooms')
                                  .doc(room.id)
                                  .delete();
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Chat dengan $displayName telah dihapus')),
                              );
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

// ==========================================
// WIDGET KUSTOM BARU: HOVERABLE CHAT TILE
// ==========================================
class HoverableChatTile extends StatefulWidget {
  final String displayName;
  final String photoUrl;
  final ChatRoomModel room;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  const HoverableChatTile({
    super.key,
    required this.displayName,
    required this.photoUrl,
    required this.room,
    required this.onTap,
    required this.onPin,
    required this.onDelete,
  });

  @override
  State<HoverableChatTile> createState() => _HoverableChatTileState();
}

class _HoverableChatTileState extends State<HoverableChatTile> {
  bool _isHovered = false; 

  @override
  Widget build(BuildContext context) {
    final String timeString = widget.room.lastTime != null
        ? DateFormat('HH:mm').format(widget.room.lastTime!)
        : '';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        // Memberi latar belakang abu-abu tipis saat baris chat di-hover kursor
        color: _isHovered ? Colors.grey[50] : Colors.transparent,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: widget.photoUrl.isNotEmpty ? NetworkImage(widget.photoUrl) : null,
            child: widget.photoUrl.isEmpty 
                ? const Icon(Icons.person, color: AppColors.primary) 
                : null,
          ),
          title: Text(
            widget.displayName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Row(
            children: [
              if (widget.room.lastMessage?.contains('📷 Foto') ?? false)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.camera_alt, size: 14, color: Colors.grey),
                ),
              Expanded(
                child: Text(
                  widget.room.lastMessage ?? 'Belum ada pesan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // Mengubah sisi kanan secara dinamis (Jam -> Titik 3) saat di-hover kursor
          trailing: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: _isHovered
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<String>(
                        tooltip: 'Pilihan',
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onSelected: (value) {
                          if (value == 'pin') {
                            widget.onPin();
                          } else if (value == 'delete') {
                            widget.onDelete();
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'pin',
                            child: Row(
                              children: [
                                Icon(Icons.push_pin_outlined, size: 18, color: Colors.black54),
                                SizedBox(width: 10),
                                Text('Sematkan chat', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                SizedBox(width: 10),
                                Text('Hapus chat', style: TextStyle(color: Colors.red, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    key: const ValueKey('time_state'),
                    children: [
                      if (timeString.isNotEmpty)
                        Text(
                          timeString,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                    ],
                  ),
          ),
          onTap: widget.onTap,
        ),
      ),
    );
  }
}