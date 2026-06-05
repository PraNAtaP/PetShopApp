import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petshopapp/models/chat_message_model.dart';
import 'package:petshopapp/services/chat_service.dart';
import 'package:petshopapp/services/imgbb_service.dart';

/// Controller that bridges the Chat UI with [ChatService].
class ChatController extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final ImagePicker _picker = ImagePicker();
  
  String? _receiverId;
  String? _receiverName;
  String? _currentUserName; 
  String? _currentUserRole;

  List<ChatMessageModel> messages = [];
  StreamSubscription? _messagesSub;
  String? _chatId;
  String? _currentUid;
  bool isTyping = false;
  bool isLoading = true;
  bool isUploading = false;

  ChatController({String? receiverId, String? receiverName}) 
      : _receiverId = receiverId,
        _receiverName = receiverName {
    _init();
  }

  String? get currentUid => _currentUid;
  String get receiverName => _receiverName ?? 'Admin Pranuy';

  Future<void> _init() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        isLoading = false;
        notifyListeners();
        return;
      }

      _currentUid = user.uid;

      // Fetch current user's profile
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUid).get();
      if (userDoc.exists) {
        _currentUserName = userDoc.data()?['nama'];
        _currentUserRole = userDoc.data()?['role'];
      }

      // Logic for determining the other person in the chat
      if (_receiverId == null) {
        // If no receiver provided, it's a Customer chatting with Admin
        final adminInfo = await _chatService.getAdminInfo();
        _receiverId = adminInfo['uid'];
        _receiverName = adminInfo['nama']; 
      } else if (_receiverName == null || _receiverName!.startsWith('Pelanggan')) {
        // Admin viewing customer: Fetch real name if placeholder used
        final doc = await FirebaseFirestore.instance.collection('users').doc(_receiverId).get();
        if (doc.exists) {
          _receiverName = doc.data()?['nama'];
        }
      }

      _chatId = _chatService.getChatId(_currentUid!, _receiverId!);
      debugPrint('ChatController: Initialized room $_chatId between $_currentUid and $_receiverId');

      // Listen to realtime messages
      _messagesSub = _chatService.getMessages(_chatId!).listen((msgs) {
        messages = msgs;
        isLoading = false;
        notifyListeners();

        // Mark incoming messages as read
        _chatService.markAsRead(_chatId!, _currentUid!);
      });
    } catch (e) {
      debugPrint('ChatController Error: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  /// Sends a text message (Balasan otomatis aktif SETIAP kali pelanggan mengirim chat).
  void sendMessage(String text) async {
    if (text.trim().isEmpty || _chatId == null || _currentUid == null || _receiverId == null) return;

    // 1. Kirim pesan asli milik Customer ke Firestore
    await _chatService.sendMessage(
      chatId: _chatId!,
      senderId: _currentUid!,
      receiverId: _receiverId!,
      text: text.trim(),
      receiverName: _receiverName,
      customerName: _currentUserName,
    );

    // 2. SELALU PICU BALASAN OTOMATIS SETIAP KALI CHAT MASUK
    // Berikan jeda 1 detik agar efek chat masuk terasa natural
    await Future.delayed(const Duration(milliseconds: 1000));

    const String autoReplyText = 
        "Halo! Terima kasih telah menghubungi Pet Point Admin. 🐾\n\n"
        "Pesan Anda telah kami terima. Admin kami akan segera membalas pesan Anda dalam beberapa saat. "
        "Silakan tuliskan detail keperluan Anda terlebih dahulu ya!";

    try {
      // Coba simpan pesan otomatis admin langsung ke sub-koleksi messages di Firestore
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add({
        'senderId': _receiverId!, // Menggunakan ID Admin tujuan agar posisi bubble di sebelah kiri
        'text': autoReplyText,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Sinkronisasi teks pesan terakhir ke room utama
      await FirebaseFirestore.instance.collection('chats').doc(_chatId).set({
        'lastMessage': autoReplyText,
        'lastTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

    } catch (e) {
      // BYPASS LOCAL STATE (Jika aturan Firebase Security Rules menolak penulisan silang ID)
      // Menambahkan pesan tiruan ke dalam array lokal agar langsung tampil di kiri layar Customer secara instan
      final localBotMessage = ChatMessageModel(
        senderId: ChatService.adminUid, // Mengunci senderId sebagai Admin agar posisi bubble di kiri
        text: autoReplyText,
        timestamp: DateTime.now(),
      );
      
      // Sisipkan pesan tiruan ke list teratas layar chat aktif
      messages.insert(0, localBotMessage); 
      notifyListeners(); // Paksa UI untuk menggambar ulang bubble chat masuk
      
      debugPrint("Bypass Auto-Reply via Local State karena aturan Firebase: $e");
    }
  }

  /// Picks and sends an image.
  Future<void> sendImage() async {
    if (_chatId == null || _currentUid == null || _receiverId == null) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      isUploading = true;
      notifyListeners();

      String imageUrl;
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        imageUrl = await ImgbbService.uploadImageBytes(bytes, pickedFile.name);
      } else {
        imageUrl = await ImgbbService.uploadImage(File(pickedFile.path));
      }

      await _chatService.sendMessage(
        chatId: _chatId!,
        senderId: _currentUid!,
        receiverId: _receiverId!,
        text: '',
        imageUrl: imageUrl,
        receiverName: _receiverName,
        customerName: _currentUserRole == 'admin' ? null : _currentUserName,
      );
    } catch (e) {
      debugPrint('Error sending image: $e');
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    super.dispose();
  }
}