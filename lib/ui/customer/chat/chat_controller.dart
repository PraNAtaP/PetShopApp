import 'dart:async';
import 'package:flutter/material.dart';
import 'message_model.dart';

class ChatController extends ChangeNotifier {
  final List<Message> messages = [];
  bool isTyping = false;

  ChatController() {
    // Pesan otomatis saat pertama kali dibuka
    messages.add(Message(
      text: "Halo! Selamat datang di Pet Point 🐶🐱\nAda yang bisa kami bantu hari ini?",
      isMe: false,
      time: DateTime.now(),
    ));
    messages.add(Message(
      text: "Silakan pilih topik di bawah ya! 🌟",
      isMe: false,
      time: DateTime.now(),
    ));
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    messages.add(Message(text: text, isMe: true, time: DateTime.now()));
    notifyListeners();
    _autoReply();
  }

  void _autoReply() async {
    isTyping = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    isTyping = false;
    messages.add(Message(
      text: "Terima kasih! Admin akan segera membantu 😊",
      isMe: false,
      time: DateTime.now(),
    ));
    notifyListeners();
  }
}