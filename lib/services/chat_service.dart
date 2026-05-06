import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petshopapp/models/chat_room_model.dart';
import 'package:petshopapp/models/chat_message_model.dart';

/// Service to handle realtime chat operations via Firestore.
///
/// Firestore structure:
/// - `chats/{chatId}` — Room metadata (participants, lastMessage, lastTime)
/// - `chats/{chatId}/messages/{messageId}` — Individual messages
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generates a deterministic chat ID from two UIDs.
  /// Sorts alphabetically to guarantee the same room for both users.
  String getChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
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
        
        // Sort client-side to avoid needing a composite index
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
  /// Ordered by [timestamp] descending (newest first).
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

  /// Sends a message to a chat room.
  ///
  /// Creates the room document if it doesn't exist yet.
  /// Updates room metadata (lastMessage, lastTime) on every send.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
    String? imageUrl,
    String? receiverName,
  }) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);

      // Add message to sub-collection
      await chatRef.collection('messages').add(
        ChatMessageModel(
          senderId: senderId,
          text: text,
          imageUrl: imageUrl,
        ).toMap(),
      );

      // Update or create room metadata
      await chatRef.set({
        'participants': [senderId, receiverId],
        'lastMessage': imageUrl != null && text.isEmpty ? '📷 Foto' : text,
        'lastTime': FieldValue.serverTimestamp(),
        // For simple apps, we store the receiver name for the customer.
        if (receiverName != null) 'receiverName': receiverName,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Gagal mengirim pesan: $e');
    }
  }

  /// Marks all unread messages in a chat as read for the given [userId].
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
      // Non-critical, just log it
      print('ChatService Error (markAsRead): $e');
    }
  }

  /// Fetches the first admin user found in the system.
  /// Used to determine who the customer should chat with.
  Future<Map<String, String>> getAdminInfo() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        return {
          'uid': snapshot.docs.first.id,
          'nama': data['nama'] ?? 'Pet Point Admin',
        };
      }
      return {'uid': 'ADMIN_UID', 'nama': 'Pet Point Admin'};
    } catch (e) {
      return {'uid': 'ADMIN_UID', 'nama': 'Pet Point Admin'};
    }
  }
}
