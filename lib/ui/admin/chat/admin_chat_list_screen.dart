import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/models/chat_room_model.dart';
import 'package:petshopapp/services/chat_service.dart';
import 'package:petshopapp/services/admin_chat_service.dart';

class AdminChatListScreen extends StatefulWidget {
  const AdminChatListScreen({super.key});

  @override
  State<AdminChatListScreen> createState() => _AdminChatListScreenState();
}

class _AdminChatListScreenState extends State<AdminChatListScreen> {
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

  /// Fetch admin-side metadata for a list of room IDs (chat_rooms collection).
  /// Returns a map: roomId -> document data map (may include isPinned, pinnedAt, pinnedBy, isDeleted, deletedAt, deletedBy).
  Future<Map<String, Map<String, dynamic>>> _fetchPinnedMap(List<String> roomIds) async {
    final db = FirebaseFirestore.instance;
    final Map<String, Map<String, dynamic>> result = {};
    for (final id in roomIds) {
      try {
        final doc = await db.collection('chat_rooms').doc(id).get();
        if (doc.exists && doc.data() != null) {
          result[id] = doc.data()!;
        }
      } catch (_) {
        // ignore individual read errors for robustness
      }
    }
    return result;
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

                  // Fetch admin-side metadata (pinned/deleted) for these rooms and merge/sort.
                  return FutureBuilder<Map<String, Map<String, dynamic>>>(
                    future: _fetchPinnedMap(rooms.map((r) => r.id).toList()),
                    builder: (context, pinnedSnapshot) {
                      final pinnedMap = pinnedSnapshot.data ?? {};
                      // create a local copy to sort
                      final sortedRooms = List<ChatRoomModel>.from(rooms);
                      sortedRooms.sort((a, b) {
                        final aPinned = pinnedMap[a.id]?['isPinned'] as bool? ?? false;
                        final bPinned = pinnedMap[b.id]?['isPinned'] as bool? ?? false;
                        if (aPinned != bPinned) return aPinned ? -1 : 1;
                        final aPinnedAt = (pinnedMap[a.id]?['pinnedAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
                        final bPinnedAt = (pinnedMap[b.id]?['pinnedAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
                        if (aPinnedAt != bPinnedAt) return bPinnedAt.compareTo(aPinnedAt);
                        return (b.lastTime ?? DateTime(0)).compareTo(a.lastTime ?? DateTime(0));
                      });

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: sortedRooms.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final room = sortedRooms[index];
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
                                final isPinned = pinnedMap[room.id]?['isPinned'] as bool? ?? false;

                                return HoverableChatTile(
                                  displayName: displayName,
                                  photoUrl: photoUrl,
                                  room: room,
                                  isPinned: isPinned,
                                  onTap: () {
                                    context.push('/chat', extra: {
                                      'receiverId': otherUid,
                                      'receiverName': displayName,
                                    });
                                  },
                                  onPin: () async {
                                    final adminId = FirebaseAuth.instance.currentUser?.uid ?? ChatService.adminUid;
                                    final adminName = FirebaseAuth.instance.currentUser?.displayName ?? ChatService.adminName;
                                    try {
                                      if (isPinned) {
                                        await AdminChatService.instance.unpinChat(roomId: room.id, adminId: adminId, adminName: adminName);
                                        if (mounted) {
                                          setState(() {}); // Trigger refresh
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Sematan dilepas untuk chat $displayName')),
                                          );
                                        }
                                      } else {
                                        await AdminChatService.instance.pinChat(roomId: room.id, adminId: adminId, adminName: adminName);
                                        if (mounted) {
                                          setState(() {}); // Trigger refresh
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Chat dengan $displayName telah disematkan')),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Gagal mengubah sematan chat: $e')),
                                        );
                                      }
                                    }
                                  },
                                  onDelete: () async {
                                    final adminId = FirebaseAuth.instance.currentUser?.uid ?? ChatService.adminUid;
                                    final adminName = FirebaseAuth.instance.currentUser?.displayName ?? ChatService.adminName;
                                    try {
                                      await AdminChatService.instance.deleteChat(roomId: room.id, adminId: adminId, adminName: adminName);
                                      if (mounted) {
                                        setState(() {}); // Trigger refresh
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Chat dengan $displayName telah dihapus')),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Gagal menghapus chat: $e')),
                                        );
                                      }
                                    }
                                  },

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

class HoverableChatTile extends StatefulWidget {
  final String displayName;
  final String photoUrl;
  final ChatRoomModel room;
  final bool isPinned;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onPin;

  const HoverableChatTile({
    super.key,
    required this.displayName,
    required this.photoUrl,
    required this.room,
    this.isPinned = false,
    required this.onTap,
    required this.onDelete,
    this.onPin,
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
        color: _isHovered ? Colors.grey[50] : (widget.isPinned ? Colors.blue.shade50.withValues(alpha: 0.3) : Colors.transparent),
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
                      if (widget.onPin != null)
                        IconButton(
                          tooltip: widget.isPinned ? 'Lepaskan Sematan' : 'Sematkan Chat',
                          icon: Icon(widget.isPinned ? Icons.push_pin : Icons.push_pin_outlined, color: widget.isPinned ? Colors.orange : Colors.blue),
                          onPressed: widget.onPin,
                        ),
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
                    mainAxisSize: MainAxisSize.min,
                    key: const ValueKey('time_state'),
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.isPinned)
                            const Icon(Icons.push_pin, size: 14, color: Colors.orange),
                          if (widget.isPinned && timeString.isNotEmpty)
                            const SizedBox(width: 4),
                          if (timeString.isNotEmpty)
                            Text(
                              timeString,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                        ],
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