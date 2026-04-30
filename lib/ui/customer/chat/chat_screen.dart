import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_controller.dart';
import 'chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  final List<Map<String, dynamic>> quickReplies = [
    {"text": "Hai saya ingin booking grooming", "icon": Icons.bathtub_outlined},
    {"text": "Hai saya ingin info fun fact peliharaan", "icon": Icons.pets},
    {"text": "Hai saya tertarik untuk mengadopsi hewan", "icon": Icons.home_outlined},
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Membungkus dengan ChangeNotifierProvider agar ChatController tersedia
    return ChangeNotifierProvider(
      create: (_) => ChatController(),
      child: Consumer<ChatController>(
        builder: (context, chat, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FB),
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context); // Fungsi keluar
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text("Pet Point Admin", 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("Online sekarang", 
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal)),
                    ],
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            body: Column(
              children: [
                // 1. LIST CHAT
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: chat.messages.length + (chat.isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chat.messages.length && chat.isTyping) {
                        return _typingIndicator();
                      }
                      return ChatBubble(message: chat.messages[index]);
                    },
                  ),
                ),

                // 2. QUICK REPLIES
                if (chat.messages.length < 5)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        const Text("✨ Pilih topik cepat atau ketik sendiri ya!", 
                          style: TextStyle(color: Colors.blue, fontSize: 12)),
                        const SizedBox(height: 8),
                        // Melewatkan chat controller ke fungsi helper
                        ...quickReplies.map((reply) => _buildQuickReply(reply, chat)).toList(),
                      ],
                    ),
                  ),

                // 3. INPUT AREA (Tetap ada di atas Navbar)
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
            const CircleAvatar(
              backgroundColor: Colors.amber,
              child: Icon(Icons.attach_file, color: Colors.black),
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

  Widget _typingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16, 
            backgroundColor: Color(0xFFC5E1A5), 
            child: Icon(Icons.pets, size: 16, color: Colors.black54)
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text("...", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}