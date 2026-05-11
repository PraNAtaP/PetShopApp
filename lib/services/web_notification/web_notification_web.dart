// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:petshopapp/core/router/admin_router.dart';

class WebNotificationService {
  static final WebNotificationService instance = WebNotificationService._();
  
  WebNotificationService._();

  StreamSubscription? _chatSubscription;
  StreamSubscription? _orderSubscription;
  StreamSubscription? _bookingSubscription;
  
  final Set<String> _processedDocIds = {};
  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    // Try requesting permission automatically
    html.Notification.requestPermission().then((permission) {
      if (permission == 'granted') {
        _startListeners();
      } else {
        debugPrint('Web Notification permission $permission');
      }
    });
  }

  /// Called manually from a user gesture (e.g., button click)
  Future<void> requestPermissionManually() async {
    final permission = await html.Notification.requestPermission();
    if (permission == 'granted') {
      if (!_isInitialized) {
        _isInitialized = true;
      }
      _startListeners();
      debugPrint('WebNotification: Permission granted manually!');
    } else {
      debugPrint('WebNotification: Permission denied manually ($permission)');
    }
  }

  void _startListeners() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Listen to Chats
    _chatSubscription = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified || change.type == DocumentChangeType.added) {
          _handleChatUpdate(change.doc, user.uid);
        }
      }
    });

    // 2. Listen to Orders (transactions)
    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null && (data['status_bayar'] == 'Pending' || data['status_bayar'] == 'Belum Bayar' || data['status_bayar'] == 'Menunggu Verifikasi')) {
            _showNotification(
              id: change.doc.id,
              title: 'Pesanan Baru Masuk!',
              body: 'Order ID: ${change.doc.id.substring(0, 8).toUpperCase()}',
              onClickPath: '/admin/dashboard', 
            );
          }
        }
      }
    });

    // 3. Listen to Grooming Bookings
    _bookingSubscription = FirebaseFirestore.instance
        .collection('grooming_bookings')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null && data['status'] == 'Pending') {
            _showNotification(
              id: change.doc.id,
              title: 'Booking Grooming Baru!',
              body: '${data['customerName'] ?? 'Pelanggan'} memesan untuk ${data['petName'] ?? 'Hewan'}',
              onClickPath: '/admin/dashboard',
            );
          }
        }
      }
    });
  }

  Future<void> _handleChatUpdate(DocumentSnapshot doc, String currentUid) async {
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

    if (senderId != currentUid) {
      final isRead = lastMessageData['isRead'] ?? false;
      
      if (!isRead) {
        String senderName = data['customerName'] ?? 'Pelanggan';
        String text = lastMessageData['text'] ?? '📷 Mengirim foto';
        
        debugPrint('WebNotification: Preparing chat notification for $messageId');
        
        _showNotification(
          id: messageId,
          title: 'Pesan dari $senderName',
          body: text,
          onClickPath: '/chat',
          extraArgs: {
            'receiverId': senderId,
            'receiverName': senderName,
          },
        );
      }
    }
  }

  void _showNotification({
    required String id,
    required String title,
    required String body,
    required String onClickPath,
    Map<String, dynamic>? extraArgs,
  }) {
    // Prevent duplicate notifications
    if (_processedDocIds.contains(id)) {
      debugPrint('WebNotification: Already processed $id, skipping.');
      return;
    }
    _processedDocIds.add(id);

    // Keep set size manageable
    if (_processedDocIds.length > 100) {
      final iterator = _processedDocIds.iterator;
      iterator.moveNext();
      _processedDocIds.remove(iterator.current);
    }

    if (html.Notification.permission == 'granted') {
      try {
        debugPrint('WebNotification: Triggering html.Notification for $title');
        
        // Use the absolute URL to the standard Flutter Web PWA icon
        final String iconUrl = '${html.window.location.origin}/icons/Icon-192.png';
        
        final notification = html.Notification(
          title,
          body: body,
          icon: iconUrl, 
        );

        notification.onClick.listen((event) {
          notification.close();
          final context = adminNavigatorKey.currentContext;
          if (context != null) {
            if (extraArgs != null) {
              context.push(onClickPath, extra: extraArgs);
            } else {
              context.go(onClickPath);
            }
          } else {
            html.window.location.href = '/#$onClickPath';
          }
        });
      } catch (e) {
        debugPrint('WebNotification Error: $e');
      }
    } else {
      debugPrint('WebNotification: Permission is not granted (${html.Notification.permission})');
    }
  }

  void dispose() {
    _chatSubscription?.cancel();
    _orderSubscription?.cancel();
    _bookingSubscription?.cancel();
    _isInitialized = false;
  }
}
