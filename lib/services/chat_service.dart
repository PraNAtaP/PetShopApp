import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petshopapp/models/chat_room_model.dart';
import 'package:petshopapp/models/chat_message_model.dart';
import 'package:petshopapp/services/fcm_service.dart';

/// Service to handle realtime chat operations via Firestore.
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Centralized Admin Identity
  static const String adminUid = 'xs2BEOZim6VKKmhlv7PrAIuQWHz2';
  static const String adminName = 'Admin Pranuy';

  /// Generates a standardized chat ID: customerUID_adminUID.
  String getChatId(String uid1, String uid2) {
    if (uid1 == adminUid) {
      return '${uid2}_$adminUid';
    } else {
      return '${uid1}_$adminUid';
    }
  }

  /// Returns a realtime stream of chat rooms where [userId] is a participant.
  Stream<List<ChatRoomModel>> getChatRooms(String userId) {
    try {
      return _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .snapshots()
          .map((snapshot) {
        final rooms = snapshot.docs
            .map((doc) => ChatRoomModel.fromFirestore(doc))
            .toList();
        
        // Sort client-side
        rooms.sort((a, b) {
          if (a.lastTime == null) return 1;
          if (b.lastTime == null) return -1;
          return b.lastTime!.compareTo(a.lastTime!);
        });
        
        return rooms;
      });
    } catch (e) {
      throw Exception('Gagal mengambil daftar chat: $e');
    }
  }

  /// Returns a realtime stream of messages for a specific [chatId].
  Stream<List<ChatMessageModel>> getMessages(String chatId) {
    try {
      return _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ChatMessageModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      throw Exception('Gagal mengambil pesan: $e');
    }
  }

  /// Sends a message and updates room metadata.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
    String? imageUrl,
    String? receiverName,
    String? customerName,
  }) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);

      await chatRef.collection('messages').add(
        ChatMessageModel(
          senderId: senderId,
          text: text,
          imageUrl: imageUrl,
        ).toMap(),
      );

      await chatRef.set({
        'participants': [senderId, receiverId],
        'lastMessage': imageUrl != null && text.isEmpty ? '📷 Foto' : text,
        'lastTime': FieldValue.serverTimestamp(),
        'receiverName': receiverName ?? (receiverId == adminUid ? adminName : 'Pelanggan'),
        if (customerName != null) 'customerName': customerName,
      }, SetOptions(merge: true));

      // ── KIRIM FCM NOTIFICATION KETIKA PESAN TERKIRIM ──
      try {
        final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
        if (receiverDoc.exists) {
          final receiverToken = receiverDoc.data()?['fcm_token'] as String?;
          if (receiverToken != null && receiverToken.isNotEmpty) {
            String senderName = senderId == adminUid ? adminName : (customerName ?? 'Pelanggan');
            
            await FCMService.instance.sendNotification(
              targetFCMToken: receiverToken,
              title: 'Pesan baru dari $senderName',
              body: text.isNotEmpty ? text : '📷 Mengirim foto',
              data: {
                'type': 'chat',
                'chatId': chatId,
              }
            );
          }
        }
      } catch (e) {
        print('Gagal kirim FCM dari ChatService: $e');
      }

    } catch (e) {
      throw Exception('Gagal mengirim pesan: $e');
    }
  }

  /// Marks unread messages as read.
  Future<void> markAsRead(String chatId, String userId) async {
    try {
      final unread = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: userId)
          .get();

      if (unread.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('ChatService Error: $e');
    }
  }

  /// Returns the static admin info.
  Future<Map<String, String>> getAdminInfo() async {
    return {
      'uid': adminUid,
      'nama': adminName,
    };
  }
}