import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petshopapp/core/theme/app_colors.dart';

/// Service to handle premium top-positioned in-app chat notifications.
class InAppChatNotifier {
  static final InAppChatNotifier instance = InAppChatNotifier._internal();
  InAppChatNotifier._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _subscription;
  String? _lastNotifiedMessageId;
  OverlayEntry? _currentOverlay;
  Timer? _dismissTimer;

  /// Starts listening for new messages in all rooms where the user is a participant.
  void startListening(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _subscription?.cancel();

    _subscription = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .skip(1) // Skip initial load payload to prevent spam on reload
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

    if (senderId != currentUid && _lastNotifiedMessageId != messageId) {
      final isRead = lastMessageData['isRead'] ?? false;
      
      if (!isRead) {
        _lastNotifiedMessageId = messageId;
        _playNotificationSound();
        _showTopOverlay(context, data, lastMessageData);
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

  void _showTopOverlay(BuildContext context, Map<String, dynamic> roomData, Map<String, dynamic> messageData) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final String senderId = messageData['senderId'];
    
    String senderName = 'Seseorang';
    if (senderId != currentUid) {
      if (senderId == 'xs2BEOZim6VKKmhlv7PrAIuQWHz2') {
        senderName = 'Pet Min'; 
      } else {
        senderName = roomData['customerName'] ?? 'Pelanggan';
      }
    }

    final String text = messageData['text'] ?? '📷 Mengirim foto';

    // Remove existing notification if any
    _dismissOverlay();

    _currentOverlay = OverlayEntry(
      builder: (context) => _PremiumNotificationWidget(
        senderName: senderName,
        message: text,
        onTap: () {
          _dismissOverlay();
          context.push('/chat', extra: {
            'receiverId': senderId,
            'receiverName': senderName,
          });
        },
        onDismiss: _dismissOverlay,
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);

    // Auto-dismiss after 4 seconds
    _dismissTimer = Timer(const Duration(seconds: 4), () {
      _dismissOverlay();
    });
  }

  void _dismissOverlay() {
    _dismissTimer?.cancel();
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  void stopListening() {
    _subscription?.cancel();
    _dismissOverlay();
  }
}

/// A custom widget for the premium top notification.
class _PremiumNotificationWidget extends StatefulWidget {
  final String senderName;
  final String message;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _PremiumNotificationWidget({
    required this.senderName,
    required this.message,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_PremiumNotificationWidget> createState() => _PremiumNotificationWidgetState();
}

class _PremiumNotificationWidgetState extends State<_PremiumNotificationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: widget.onTap,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat_bubble_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.senderName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              widget.message,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: widget.onTap,
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text('Balas', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
