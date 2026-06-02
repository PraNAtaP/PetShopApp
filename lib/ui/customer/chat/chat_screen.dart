import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:petshopapp/models/chat_message_model.dart';
import 'package:petshopapp/core/theme/app_colors.dart';
import 'chat_controller.dart';
import 'chat_bubble.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:petshopapp/services/auth_service.dart';
import 'package:petshopapp/ui/customer/main/base_screen.dart';

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
 final ScrollController _scrollController = ScrollController();
 final FocusNode _keyboardFocusNode = FocusNode();

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
  void _scrollToBottom() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    }
  });
}

  @override
void dispose() {
  _controller.dispose();
  _scrollController.dispose();
  _keyboardFocusNode.dispose();
  super.dispose();
}

  /// Fungsi bantuan untuk mengubah DateTime menjadi teks "Hari ini", "Kemarin", atau Tanggal
  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return "Hari ini";
    } else if (messageDate == yesterday) {
      return "Kemarin";
    } else {
      return DateFormat('d MMMM yyyy', 'id_ID').format(date); 
    }
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
          if (displayMessages.isNotEmpty) {
            Future.microtask(_scrollToBottom);
          }
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    final authService = context.read<AuthService>();
                    final role = authService.currentUser?.role.value;
                    if (role == 'admin') {
                      context.go('/admin/dashboard');
                    } else {
                      final baseScreen = BaseScreen.of(context);
                      if (baseScreen != null) {
                        baseScreen.setTab(0);
                      } else {
                        context.go('/home');
                      }
                    }
                  }
                },
              ),
              title: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.secondary,
                    child: Icon(Icons.pets, color: Colors.black54, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    chat.receiverName ?? 'Admin',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
               ],
              ),
              backgroundColor: AppColors.primary,
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
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          itemCount: displayMessages.length,
                          itemBuilder: (context, index) {
                            final msg = displayMessages[index];
                            final isMe = msg.senderId == chat.currentUid;

                            // LOGIKA PEMISAH TANGGAL
                            bool showDateDivider = false;
                            if (msg.timestamp != null) {
                              if (index == 0) {
                                // Pesan pertama selalu memunculkan tanggal
                                showDateDivider = true;
                              } else {
                                // Cek pesan sebelumnya, jika tanggal berbeda maka munculkan pembatas baru
                                final prevMsg = displayMessages[index - 1];
                                if (prevMsg.timestamp != null) {
                                  final currentLineDate = DateTime(msg.timestamp!.year, msg.timestamp!.month, msg.timestamp!.day);
                                  final prevLineDate = DateTime(prevMsg.timestamp!.year, prevMsg.timestamp!.month, prevMsg.timestamp!.day);
                                  if (currentLineDate != prevLineDate) {
                                    showDateDivider = true;
                                  }
                                }
                              }
                            }

                            return Column(
                              children: [
                                if (showDateDivider && msg.timestamp != null)
                                  Container(
                                    margin: const EdgeInsets.symmetric(vertical: 14),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getDateLabel(msg.timestamp!),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ChatBubble(message: msg, isMe: isMe),
                              ],
                            );
                          },
                        ),
                ),

                // 2. INPUT AREA & HORIZONTAL QUICK REPLIES
                if (chat.isUploading)
                  const LinearProgressIndicator(minHeight: 2),

                // Menampilkan topik cepat bergeser ke samping (Horizontal) menggantikan posisi lama
                if (widget.receiverId == null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    color: Colors.white,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: quickReplies.map((reply) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ActionChip(
                              avatar: Icon(reply['icon'], size: 16, color: Colors.black54),
                              label: Text(reply['text']),
                              onPressed: () {
                                _controller.text = reply['text'];
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                _buildInputArea(chat),
              ],
            ),
          );
        },
      ),
    );  
  }

  Widget _buildInputArea(ChatController chat) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
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
              child: KeyboardListener(
                focusNode: _keyboardFocusNode,
                onKeyEvent: (event) {
                  final shiftPressed =
                      HardwareKeyboard.instance.logicalKeysPressed.contains(
                        LogicalKeyboardKey.shiftLeft,
                      ) ||
                      HardwareKeyboard.instance.logicalKeysPressed.contains(
                        LogicalKeyboardKey.shiftRight,
                      );

                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.enter &&
                      !shiftPressed) {
                    if (_controller.text.trim().isNotEmpty) {
                      chat.sendMessage(_controller.text);
                      _controller.clear();
                      _scrollToBottom();
                    }
                  }
                },
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.multiline,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: "Ketik pesan di sini...",
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
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
              icon: const Icon(Icons.send, color: AppColors.primary),
            )
          ],
        ),
      ),
    );
  }
}