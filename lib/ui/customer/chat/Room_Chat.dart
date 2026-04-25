import 'dart:async';
import 'package:flutter/material.dart';
 
enum MessageSender { customer, admin }
 
class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime time;
  final bool isTypingIndicator;
 
  ChatMessage({
    required this.text,
    required this.sender,
    required this.time,
    this.isTypingIndicator = false,
  });
}
// Warna Tema
class PetColors {
  static const navyBlue   = Color(0xFF003F87);
  static const lightGreen = Color(0xFFA8D5A1);
  static const red        = Color(0xFFD32F2F);
  static const yellow     = Color(0xFFFFC107);
  static const lightBlue  = Color(0xFF87CEEB);
  static const bgChat     = Color(0xFFEEF3FB);
  static const bgInput    = Color(0xFFF8F9FF);
}
// quick reply
class QuickReply {
  final String emoji;
  final String text;
  const QuickReply({required this.emoji, required this.text});
}
 
const List<QuickReply> kQuickReplies = [
  QuickReply(emoji: '🛁', text: 'Hai saya ingin booking grooming'),
  QuickReply(emoji: '🐾', text: 'Hai saya ingin info fun fact peliharaan'),
  QuickReply(emoji: '🏡', text: 'Hai saya tertarik untuk mengadopsi hewan'),
];
// Auto Replies
const Map<String, String> kAutoReplies = {
  'grooming': 'Wah mau grooming? 🛁✨ Yuk pilih jadwal yang cocok! '
      'Kami buka Senin–Sabtu pukul 09.00–17.00. Mau booking untuk hewan apa?',
  'fun fact': 'Seru banget! 🐾🌟 Tahukah kamu, kucing bisa tidur hingga '
      '16 jam sehari? Atau anjing bisa mencium bau 100.000x lebih tajam dari manusia! '
      'Mau fun fact tentang hewan apa?',
  'adopsi': 'Wah kamu mau adopsi hewan? 🏡💕 Kami punya banyak hewan lucu '
      'yang butuh rumah hangat. Mau lihat daftar hewan yang tersedia?',
};

// class ChatRoomPage extends StatefulWidget {
class RoomChatScreen extends StatefulWidget {
  const RoomChatScreen({super.key});
 
  @override
  State<RoomChatScreen> createState() => _RoomChatScreenState();
}
// state class ChatRoomPage
class _RoomChatScreenState extends State<RoomChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _showQuickReplies = true;
 
  @override
  void initState() {
    super.initState();
    _addAdminWelcome();
  }
 
  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
  }
// function add admin welcome
  void _addAdminWelcome() {
    Future.delayed(const Duration(milliseconds: 400), () {
      _addMessage('Halo! Selamat datang di Pet Point 🐶🐱\nAda yang bisa kami bantu hari ini?',
          MessageSender.admin);
      Future.delayed(const Duration(milliseconds: 800), () {
        _addMessage('Silakan pilih topik di bawah ya! 🌟', MessageSender.admin);
      });
    });
  }
// function add message
 void _addMessage(String text, MessageSender sender) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        sender: sender,
        time: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }
 //function send message
void _sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
 
    _inputCtrl.clear();
    setState(() => _showQuickReplies = false);
    _addMessage(trimmed, MessageSender.customer);
    _triggerAdminReply(trimmed);
  }
  //function trigger admin reply
 void _triggerAdminReply(String customerText) {
    setState(() => _isTyping = true);
    _scrollToBottom();
    final lower = customerText.toLowerCase();
    String reply = 'Terima kasih pesannya! 😊 Tim kami akan segera membalas ya~';
 
    for (final entry in kAutoReplies.entries) {
      if (lower.contains(entry.key)) {
        reply = entry.value;
        break;
      }
    }
      Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _isTyping = false);
      _addMessage(reply, MessageSender.admin);
    });
  }
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        );
      }
    });
  // BUILD
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PetColors.bgChat,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildChatBody()),
            _buildBottomArea(),
          ],
        ),
      ),
    );
  }
 // ── Header 
    Widget _buildHeader() {
    return Container(
      color: PetColors.navyBlue,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: PetColors.lightGreen,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🐾', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pet Point Admin',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: PetColors.lightGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('Online sekarang',
                        style: TextStyle(
                            color: PetColors.lightGreen, fontSize: 10)),
                  ],
                )
              ],
            ),
          ),
          _headerIconBtn(Icons.phone_outlined),
          const SizedBox(width: 8),
          _headerIconBtn(Icons.more_vert),
        ],
      ),
    );
  }

  Widget _headerIconBtn(IconData icon) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }
// ── Chat Body 

  Widget _buildChatBody() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      itemCount: _messages.length + (_isTyping ? 2 : 1),
      itemBuilder: (context, index) {
        if (index == 0) return _dateDivider();

        final msgIndex = index - 1;

        if (_isTyping && msgIndex == _messages.length) {
          return _typingBubble();
        }

        final msg = _messages[msgIndex];
        return _buildBubble(msg);
      },
    );
  }
 Widget _dateDivider() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(child: Container(height: 0.5, color: Colors.blue.shade100)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFC9D8EF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('🌸 Hari ini',
                style: TextStyle(
                    color: PetColors.navyBlue,
                    fontSize: 9,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Container(height: 0.5, color: Colors.blue.shade100)),
        ],
      ),
    );
 }
  Widget _buildBubble(ChatMessage msg) {
    final isAdmin = msg.sender == MessageSender.admin;
    final timeStr =
        '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}';
  final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isAdmin ? Colors.white : PetColors.navyBlue,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isAdmin ? 4 : 16),
          bottomRight: Radius.circular(isAdmin ? 16 : 4),
        ),
        border: isAdmin
            ? Border.all(color: Colors.blue.shade50, width: 0.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            msg.text,
            style: TextStyle(
              color: isAdmin ? PetColors.navyBlue : Colors.white,
              fontSize: 11.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(timeStr,
                  style: TextStyle(
                    fontSize: 9,
                    color: isAdmin
                        ? PetColors.lightBlue
                        : PetColors.lightGreen,
                  )),
              if (!isAdmin) ...[
                const SizedBox(width: 3),
                const Icon(Icons.done_all,
                    size: 12, color: PetColors.lightGreen),
              ]
            ],
          ),
        ],
      ),
    );


