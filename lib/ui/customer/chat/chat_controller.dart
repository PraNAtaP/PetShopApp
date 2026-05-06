import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  String get receiverName => _receiverName ?? 'Pet Point Admin';

  Future<void> _init() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        isLoading = false;
        notifyListeners();
        return;
      }

      _currentUid = user.uid;

      if (_receiverId == null) {
        final adminInfo = await _chatService.getAdminInfo();
        _receiverId = adminInfo['uid'];
        _receiverName = adminInfo['nama'];
      }

      _chatId = _chatService.getChatId(_currentUid!, _receiverId!);

      _messagesSub = _chatService.getMessages(_chatId!).listen((msgs) {
        messages = msgs;
        isLoading = false;
        notifyListeners();
        _chatService.markAsRead(_chatId!, _currentUid!);
      });
    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Sends a text message.
  void sendMessage(String text) {
    if (text.trim().isEmpty || _chatId == null || _currentUid == null || _receiverId == null) return;

    _chatService.sendMessage(
      chatId: _chatId!,
      senderId: _currentUid!,
      receiverId: _receiverId!,
      text: text.trim(),
      receiverName: _receiverName,
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