import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/chat_room_model.dart';
import 'package:petshopapp/services/chat_service.dart';
import 'package:petshopapp/ui/customer/chat/chat_screen.dart';

class AdminChatListScreen extends StatelessWidget {
  const AdminChatListScreen({super.key});

  Future<String> _fetchUserName(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.data()?['nama'] ?? 'Pelanggan ($uid)';
    } catch (_) {
      return 'Pelanggan ($uid)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ChatService chatService = ChatService();
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Chat Pelanggan'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: StreamBuilder<List<ChatRoomModel>>(
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
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final room = rooms[index];
              final otherUid = room.participants.firstWhere((id) => id != currentUid, orElse: () => 'User');
              
              return FutureBuilder<String>(
                future: room.customerName != null 
                    ? Future.value(room.customerName) 
                    : _fetchUserName(otherUid),
                builder: (context, nameSnapshot) {
                  final displayName = nameSnapshot.data ?? (room.customerName ?? 'Loading...');

                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, color: Colors.white),
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
                            room.lastMessage ?? 'No messages yet',
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
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
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
    );
  }
}
