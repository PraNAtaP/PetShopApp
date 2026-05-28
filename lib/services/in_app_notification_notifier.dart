import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petshopapp/core/theme/app_colors.dart';

/// Service to handle premium top-positioned in-app general notifications.
class InAppNotificationNotifier {
  static final InAppNotificationNotifier instance =
      InAppNotificationNotifier._internal();
  InAppNotificationNotifier._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _subscription;
  String? _lastNotifiedDocId;
  OverlayEntry? _currentOverlay;
  Timer? _dismissTimer;

  /// Starts listening for new notifications for the current user.
  void startListening(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _subscription?.cancel();

    _subscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .skip(1) // Skip initial load payload to prevent spam on app start
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added ||
                change.type == DocumentChangeType.modified) {
              _handleNotificationUpdate(context, change.doc);
            }
          }
        });
  }

  Future<void> _handleNotificationUpdate(
    BuildContext context,
    DocumentSnapshot doc,
  ) async {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return;

    final isRead = data['read'] as bool? ?? false;
    final docId = doc.id;

    if (!isRead && _lastNotifiedDocId != docId) {
      _lastNotifiedDocId = docId;
      _playNotificationSound();
      _showTopOverlay(context, data);
    }
  }

  void _playNotificationSound() async {
    try {
      await _audioPlayer.play(
        UrlSource(
          'https://assets.mixkit.co/active_storage/sfx/2358/2358-preview.mp3',
        ),
      );
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void _showTopOverlay(BuildContext context, Map<String, dynamic> data) {
    final title = data['title'] ?? 'Notifikasi Baru';
    final body = data['body'] ?? '';
    final type = data['type'] as String?;

    // Remove existing notification if any
    _dismissOverlay();

    _currentOverlay = OverlayEntry(
      builder: (context) => _PremiumNotificationWidget(
        title: title,
        message: body,
        type: type,
        onTap: () {
          _dismissOverlay();
          if (type == 'adoption_cancellation') {
            context.push('/adoption-history');
          } else if (type == 'grooming_booking') {
            context.push('/grooming-history');
          } else {
            context.push('/notifications');
          }
        },
        onDismiss: _dismissOverlay,
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);

    // Auto-dismiss after 5 seconds
    _dismissTimer = Timer(const Duration(seconds: 5), () {
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

class _PremiumNotificationWidget extends StatefulWidget {
  final String title;
  final String message;
  final String? type;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _PremiumNotificationWidget({
    required this.title,
    required this.message,
    this.type,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_PremiumNotificationWidget> createState() =>
      _PremiumNotificationWidgetState();
}

class _PremiumNotificationWidgetState extends State<_PremiumNotificationWidget>
    with SingleTickerProviderStateMixin {
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
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'adoption_cancellation':
        return Icons.cancel_schedule_send_rounded;
      case 'grooming_booking':
        return Icons.wash_rounded;
      case 'order_shipping':
        return Icons.local_shipping_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'adoption_cancellation':
        return Colors.red;
      case 'grooming_booking':
        return Colors.blue;
      case 'order_shipping':
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getColorForType(widget.type);
    final iconBgColor = iconColor.withOpacity(0.1);

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
                          color: iconBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIconForType(widget.type),
                          color: iconColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              widget.message,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          'Buka',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
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
