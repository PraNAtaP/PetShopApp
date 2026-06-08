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

  /// Sends a text message (Murni mengirim pesan customer tanpa ada balasan otomatis).
  void sendMessage(String text) async {
    if (text.trim().isEmpty || _chatId == null || _currentUid == null || _receiverId == null) return;

    // Kirim pesan asli milik Customer ke Firestore via ChatService
    await _chatService.sendMessage(
      chatId: _chatId!,
      senderId: _currentUid!,
      receiverId: _receiverId!,
      text: text.trim(),
      receiverName: _receiverName,
      customerName: _currentUserName,
    );
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