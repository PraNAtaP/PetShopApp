import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Service to handle in-app chat notifications (Sound & SnackBar).
/// Listens to Firestore changes instead of FCM for low-latency in-app alerts.
class InAppChatNotifier {
  static final InAppChatNotifier instance = InAppChatNotifier._internal();
  InAppChatNotifier._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _subscription;
  String? _lastNotifiedMessageId;

  /// Starts listening for new messages in all rooms where the user is a participant.
  void startListening(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _subscription?.cancel();

    // Listen to 'chats' collection where user is a participant
    _subscription = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified || change.type == DocumentChangeType.added) {
          _handleRoomUpdate(context, change.doc, user.uid);
        }
      }
    });
  }

  Future<void> _handleRoomUpdate(BuildContext context, DocumentSnapshot doc, String currentUid) async {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return;

    // Check if the update is a new message and NOT from the current user
    final messagesSnapshot = await doc.reference
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (messagesSnapshot.docs.isEmpty) return;

    final lastMessageDoc = messagesSnapshot.docs.first;
    final lastMessageData = lastMessageDoc.data();
    final senderId = lastMessageData['senderId'];
    final messageId = lastMessageDoc.id;

    // Condition: New message, not from me, and not already notified
    if (senderId != currentUid && _lastNotifiedMessageId != messageId) {
      final isRead = lastMessageData['isRead'] ?? false;
      
      if (!isRead) {
        _lastNotifiedMessageId = messageId;
        _playNotificationSound();
        _showInAppBanner(context, data, lastMessageData);
      }
    }
  }

  void _playNotificationSound() async {
    try {
      await _audioPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2358/2358-preview.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void _showInAppBanner(BuildContext context, Map<String, dynamic> roomData, Map<String, dynamic> messageData) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final String senderId = messageData['senderId'];
    
    // Determine display name: 
    // If sender is NOT current user, and current user is NOT admin -> it must be Admin (Pet Min)
    // If current user IS admin -> it must be Customer (roomData['customerName'])
    String senderName = 'Seseorang';
    if (senderId != currentUid) {
      if (senderId == 'xs2BEOZim6VKKmhlv7PrAIuQWHz2') {
        senderName = 'Pet Min'; 
      } else {
        senderName = roomData['customerName'] ?? 'Pelanggan';
      }
    }

    final String text = messageData['text'] ?? '📷 Mengirim foto';

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(senderName, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Balas',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            context.push('/chat', extra: {
              'receiverId': senderId,
              'receiverName': senderName,
            });
          },
        ),
      ),
    );
  }

  void stopListening() {
    _subscription?.cancel();
  }
}
