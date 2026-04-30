import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_controller.dart';
import 'chat_bubble.dart';
import 'quick_reply.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatController(),
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();

    return Scaffold(
      appBar: AppBar(title: const Text("Pet Point Admin")),
      body: Column(
        children: [
          // CHAT LIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                ...chat.messages
                    .map((m) => ChatBubble(message: m)),

                if (chat.isTyping)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Admin sedang mengetik..."),
                  )
              ],
            ),
          ),

          // QUICK REPLY
          Column(
            children: [
              QuickReply(
                text: "Booking grooming",
                onTap: () => chat.sendQuickReply(
                    "Hai saya ingin booking grooming"),
              ),
              QuickReply(
                text: "Fun fact hewan",
                onTap: () => chat.sendQuickReply(
                    "Saya ingin info fun fact"),
              ),
            ],
          ),

          // INPUT
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: "Ketik pesan...",
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  chat.sendMessage(controller.text);
                  controller.clear();
                },
              )
            ],
          )
        ],
      ),
    );
  }
}