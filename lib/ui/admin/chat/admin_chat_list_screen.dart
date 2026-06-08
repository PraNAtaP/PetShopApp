import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/chat_room_model.dart';

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
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08), 
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Container(
              height: 1,
              color: Colors.grey[200],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('chats').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final rooms = docs
                      .map((doc) => ChatRoomModel.fromFirestore(doc))
                      .where((room) =>
                          room.participants.contains(currentUid) &&
                          room.isDeleted == false)
                      .toList();

                  // Sort client-side by lastTime descending
                  rooms.sort((a, b) {
                    if (a.lastTime == null && b.lastTime == null) return 0;
                    if (a.lastTime == null) return 1;
                    if (b.lastTime == null) return -1;
                    return b.lastTime!.compareTo(a.lastTime!);
                  });

                  if (rooms.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum ada chat dari pelanggan.', 
                            style: TextStyle(color: Colors.grey),
                          ),
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
                        orElse: () => room.participants.isNotEmpty ? room.participants.first : 'User',
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
                            onDelete: () async {
                              await FirebaseFirestore.instance
                                  .collection('chats')
                                  .doc(room.id)
                                  .update({'isDeleted': true});
                              
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Chat dengan $displayName telah dihapus')),
                                );
                              }
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

class HoverableChatTile extends StatefulWidget {
  final String displayName;
  final String photoUrl;
  final ChatRoomModel room;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const HoverableChatTile({
    super.key,
    required this.displayName,
    required this.photoUrl,
    required this.room,
    required this.onTap,
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
          trailing: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: _isHovered
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Hapus Chat',
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: widget.onDelete,
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