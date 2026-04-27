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

  // ── Chat Body ─────────────────────────────────────────────────────────────

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

    final avatar = Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isAdmin ? PetColors.lightGreen : PetColors.yellow,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          isAdmin ? '🐾' : '😊',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isAdmin ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isAdmin
            ? [avatar, const SizedBox(width: 6), bubble]
            : [bubble, const SizedBox(width: 6), avatar],
      ),
    );
  }

  // ── Typing Indicator ──────────────────────────────────────────────────────

  Widget _typingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
                color: PetColors.lightGreen, shape: BoxShape.circle),
            child: const Center(
                child: Text('🐾', style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: Colors.blue.shade50, width: 0.5),
            ),
            child: const _TypingDotsWidget(),
          ),
        ],
      ),
    );
  }

  // ── Area Bawah (Quick Reply + Input) ──────────────────────────────────────

  Widget _buildBottomArea() {
    return Container(
      color: PetColors.bgInput,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showQuickReplies) _buildQuickReplies(),
          _buildInputRow(),
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      decoration: BoxDecoration(
        color: PetColors.bgInput,
        border: Border(top: BorderSide(color: Colors.blue.shade100, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('✨ ',
                  style: TextStyle(fontSize: 12)),
              Text('Pilih topik cepat atau ketik sendiri ya!',
                  style: TextStyle(
                      color: PetColors.lightBlue,
                      fontSize: 9,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 6),
          ...kQuickReplies.map((qr) => _quickChip(qr)),
        ],
      ),
    );
  }

  Widget _quickChip(QuickReply qr) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: GestureDetector(
        onTap: () => _sendMessage(qr.text),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: PetColors.lightGreen, width: 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Text(qr.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  qr.text,
                  style: const TextStyle(
                      color: PetColors.navyBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w400),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      decoration: BoxDecoration(
        color: PetColors.bgInput,
        border: Border(top: BorderSide(color: Colors.blue.shade100, width: 0.5)),
      ),
      child: Row(
        children: [
          // Tombol Attachment
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: PetColors.yellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.attach_file,
                  color: PetColors.navyBlue, size: 18),
            ),
          ),
          const SizedBox(width: 8),

          // Input Text
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                border:
                    Border.all(color: const Color(0xFFC9D8EF), width: 1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _inputCtrl,
                style: const TextStyle(
                    fontSize: 12, color: PetColors.navyBlue),
                decoration: const InputDecoration(
                  hintText: 'Ketik pesan di sini...',
                  hintStyle: TextStyle(
                      fontSize: 12, color: Color(0xFFAAC0D8)),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                ),
                onSubmitted: _sendMessage,
                textInputAction: TextInputAction.send,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Tombol Kirim
          GestureDetector(
            onTap: () => _sendMessage(_inputCtrl.text),
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: PetColors.navyBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }


// ─── Typing Dots Widget (Animasi) ────────────────────────────────────────────

class _TypingDotsWidget extends StatefulWidget {
  const _TypingDotsWidget();

  @override
  State<_TypingDotsWidget> createState() => _TypingDotsWidgetState();
}

class _TypingDotsWidgetState extends State<_TypingDotsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final offset =
                ((_ctrl.value * 3 - i) % 1.0).clamp(0.0, 1.0);
            final dy = offset < 0.5 ? offset * 2 : (1.0 - offset) * 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Transform.translate(
                offset: Offset(0, -5 * dy),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: PetColors.lightBlue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}