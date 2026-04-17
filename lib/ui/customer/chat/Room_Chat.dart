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
  }
 