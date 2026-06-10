import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'package:petshopapp/services/admin_chat_service.dart';
import 'package:petshopapp/services/chat_service.dart';

class AdminChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const AdminChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  late String _chatRoomId;

  @override
  void initState() {
    super.initState();
    // Membuat ID Room Chat yang konsisten: customerUID_adminUID
    // Di mana widget.receiverId adalah customerUID, dan _currentUid adalah adminUID
    _chatRoomId = '${widget.receiverId}_$_currentUid';
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final String messageText = _messageController.text.trim();
    _messageController.clear();

    final now = DateTime.now();

    // 1. Tambah Pesan ke Sub-Koleksi 'messages' di dalam koleksi 'chats'
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatRoomId)
        .collection('messages')
        .add({
      'senderId': _currentUid,
      'receiverId': widget.receiverId,
      'text': messageText,
      'message': messageText, // Kompatibilitas mundur
      'timestamp': Timestamp.fromDate(now),
      'isRead': false,
    });

    // 2. Update Informasi Terakhir di Dokumen Utama Chat Room
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatRoomId)
        .set({
      'id': _chatRoomId,
      'participants': [_currentUid, widget.receiverId],
      'lastMessage': messageText,
      'lastTime': Timestamp.fromDate(now),
      'receiverName': widget.receiverName, 
      'isDeleted': false, // Mengaktifkan kembali chat room jika sebelumnya di-soft delete
      'userUnreadCount': FieldValue.increment(1),
    }, SetOptions(merge: true));

    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.person, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text(
              widget.receiverName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Area Menampilkan List Chat
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Belum ada obrolan dengan ${widget.receiverName}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final bool isMe = data['senderId'] == _currentUid;
                    final Timestamp? timestamp = data['timestamp'] as Timestamp?;
                    final String timeString = timestamp != null
                        ? DateFormat('HH:mm').format(timestamp.toDate())
                        : '';
                    final String content = data['text'] ?? data['message'] ?? '';
                    final String messageId = docs[index].id;
                    final bool msgIsPinned = data['isPinned'] as bool? ?? false;
                    final bool msgIsDeleted = data['isDeleted'] as bool? ?? false;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12),
                                topRight: const Radius.circular(12),
                                bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
                                bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.6,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (msgIsDeleted) ...[
                                  Text(
                                    'Pesan dihapus',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: isMe ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                ] else ...[
                                  if (msgIsPinned)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.push_pin, size: 14, color: Colors.orange),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            content,
                                            style: TextStyle(
                                              color: isMe ? Colors.white : Colors.black87,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      content,
                                      style: TextStyle(
                                        color: isMe ? Colors.white : Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  timeString,
                                  style: TextStyle(
                                    color: isMe ? Colors.white70 : Colors.black38,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Three-dot menu for admin actions on each message
                          Positioned(
                            right: -8,
                            top: -6,
                            child: PopupMenuButton<String>(
                              tooltip: 'Message options',
                              icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                              onSelected: (value) async {
                                final adminId = FirebaseAuth.instance.currentUser?.uid ?? ChatService.adminUid;
                                final adminName = FirebaseAuth.instance.currentUser?.displayName ?? ChatService.adminName;
                                try {
                                  if (value == 'pin') {
                                    await AdminChatService.instance.pinMessage(
                                      roomId: _chatRoomId,
                                      messageId: messageId,
                                      adminId: adminId,
                                      adminName: adminName,
                                    );
                                  } else if (value == 'unpin') {
                                    await AdminChatService.instance.unpinMessage(
                                      roomId: _chatRoomId,
                                      messageId: messageId,
                                      adminId: adminId,
                                      adminName: adminName,
                                    );
                                  } else if (value == 'delete') {
                                    await AdminChatService.instance.deleteMessage(
                                      roomId: _chatRoomId,
                                      messageId: messageId,
                                      adminId: adminId,
                                      adminName: adminName,
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action failed: $e')));
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                if (!msgIsPinned)
                                  const PopupMenuItem<String>(value: 'pin', child: Text('Sematkan pesan')),
                                if (msgIsPinned)
                                  const PopupMenuItem<String>(value: 'unpin', child: Text('Lepaskan sematan')),
                                const PopupMenuItem<String>(value: 'delete', child: Text('Hapus pesan', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Kolom Input Pesan Bagian Bawah
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.black12, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Tulis balasan pesan...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: FloatingActionButton.small(
                    onPressed: _sendMessage,
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    child: const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}