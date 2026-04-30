import 'dart:async';
import 'package:flutter/material.dart';
import 'message_model.dart';

class ChatController extends ChangeNotifier {
  final List<Message> messages = [];
  bool isTyping = false;

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    messages.add(
      Message(text: text, isMe: true, time: DateTime.now()),
    );

    notifyListeners();

    _autoReply();
  }

  void sendQuickReply(String text) {
    sendMessage(text);
  }

  void _autoReply() async {
    isTyping = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    isTyping = false;

    messages.add(
      Message(
        text: "Terima kasih! Admin akan segera membantu 😊",
        isMe: false,
        time: DateTime.now(),
      ),
    );

    notifyListeners();
  }
}