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