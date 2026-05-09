import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:petshopapp/models/chat_message_model.dart';
import 'chat_controller.dart';
import 'chat_bubble.dart';


class ChatScreen extends StatefulWidget {
  final String? receiverId;
  final String? receiverName;
  final String? defaultTopic;

  const ChatScreen({
    super.key, 
    this.receiverId, 
    this.receiverName,
    this.defaultTopic,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
 late TextEditingController _controller;

  final List<Map<String, dynamic>> quickReplies = [
    {"text": "Hai saya ingin booking grooming", "icon": Icons.bathtub_outlined},
    {"text": "Hai saya ingin info fun fact peliharaan", "icon": Icons.pets},
    {"text": "Hai saya tertarik untuk mengadopsi hewan", "icon": Icons.home_outlined},
  ];

@override
void initState() {
  super.initState();

  _controller = TextEditingController(
    text: widget.defaultTopic ?? '',
  );
}

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatController(
        receiverId: widget.receiverId,
        receiverName: widget.receiverName,
      ),
      child: Consumer<ChatController>(
        builder: (context, chat, child) {
          // Messages are newest-first from Firestore, reverse for display
          final displayMessages = chat.messages.reversed.toList();

          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FB),
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFC5E1A5),
                    child: Icon(Icons.pets, color: Colors.black54, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(chat.receiverName, 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            body: chat.isLoading 
                ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                : Column(
              children: [
                // 1. MESSAGE LIST
                Expanded(
                  child: displayMessages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'Mulai percakapan!',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          itemCount: displayMessages.length,
                          itemBuilder: (context, index) {
                            final msg = displayMessages[index];
                            final isMe = msg.senderId == chat.currentUid;
                            return ChatBubble(message: msg, isMe: isMe);
                          },
                        ),
                ),

                // 2. QUICK REPLIES (Only show for customer/new chat)
                if (displayMessages.length < 3 && widget.receiverId == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        const Text("✨ Pilih topik cepat atau ketik sendiri ya!", 
                          style: TextStyle(color: Colors.blue, fontSize: 12)),
                        const SizedBox(height: 8),
                        ...quickReplies.map((reply) => _buildQuickReply(reply, chat)),
                      ],
                    ),
                  ),

                // 3. INPUT AREA
                if (chat.isUploading)
                  const LinearProgressIndicator(minHeight: 2),
                _buildInputArea(chat),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickReply(Map<String, dynamic> reply, ChatController chat) {
    return GestureDetector(
      onTap: () => chat.sendMessage(reply['text']),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green.shade300),
          borderRadius: BorderRadius.circular(25),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(reply['icon'], size: 20, color: Colors.grey),
            const SizedBox(width: 10),
            Expanded(child: Text(reply['text'], style: const TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ChatController chat) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            GestureDetector(
              onTap: chat.isUploading ? null : () => chat.sendImage(),
              child: CircleAvatar(
                backgroundColor: chat.isUploading ? Colors.grey : Colors.amber,
                child: chat.isUploading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.attach_file, color: Colors.black),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: "Ketik pesan di sini...",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                if (_controller.text.trim().isNotEmpty) {
                  chat.sendMessage(_controller.text);
                  _controller.clear();
                }
              },
              icon: const Icon(Icons.send, color: Color(0xFF0D47A1)),
            )
          ],
        ),
      ),
    );
  }
}