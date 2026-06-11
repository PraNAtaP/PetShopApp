import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petshopapp/services/admin_log_service.dart';

/// Admin-specific chat operations that target the admin collection 'chat_rooms'.
/// All methods use batched writes to include an admin log entry atomically.
class AdminChatService {
  AdminChatService._private();
  static final AdminChatService instance = AdminChatService._private();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> pinChat({
    required String roomId,
    required String adminId,
    required String adminName,
  }) async {
    final batch = _firestore.batch();
    final roomRef = _firestore.collection('chat_rooms').doc(roomId);
    final logRef = AdminLogService.instance.getNewLogRef();

    batch.set(roomRef, {
      'isPinned': true,
      'pinnedAt': FieldValue.serverTimestamp(),
      'pinnedBy': adminId,
    }, SetOptions(merge: true));

    batch.set(logRef, AdminLogService.instance.buildLogMap(
      adminName: adminName,
      actionType: 'PIN_CHAT',
      description: 'Pinned chat: $roomId by $adminName',
      adminId: adminId,
      targetId: roomId,
      targetType: 'chats',
    ));

    await batch.commit();
  }

  Future<void> unpinChat({
    required String roomId,
    required String adminId,
    required String adminName,
  }) async {
    final batch = _firestore.batch();
    final roomRef = _firestore.collection('chat_rooms').doc(roomId);
    final logRef = AdminLogService.instance.getNewLogRef();

    batch.set(roomRef, {
      'isPinned': false,
      'pinnedAt': FieldValue.delete(),
      'pinnedBy': FieldValue.delete(),
    }, SetOptions(merge: true));

    batch.set(logRef, AdminLogService.instance.buildLogMap(
      adminName: adminName,
      actionType: 'UNPIN_CHAT',
      description: 'Unpinned chat: $roomId by $adminName',
      adminId: adminId,
      targetId: roomId,
      targetType: 'chats',
    ));

    await batch.commit();
  }

  Future<void> deleteChat({
    required String roomId,
    required String adminId,
    required String adminName,
  }) async {
    final batch = _firestore.batch();
    final roomRef = _firestore.collection('chats').doc(roomId);
    final logRef = AdminLogService.instance.getNewLogRef();

    batch.set(roomRef, {
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'deletedBy': adminId,
    }, SetOptions(merge: true));

    batch.set(logRef, AdminLogService.instance.buildLogMap(
      adminName: adminName,
      actionType: 'DELETE_CHAT',
      description: 'Deleted chat (soft): $roomId by $adminName',
      adminId: adminId,
      targetId: roomId,
      targetType: 'chats',
    ));

    await batch.commit();
  }

  Future<void> pinMessage({
    required String roomId,
    required String messageId,
    required String adminId,
    required String adminName,
  }) async {
    final batch = _firestore.batch();
    final msgRef = _firestore.collection('chats').doc(roomId).collection('messages').doc(messageId);
    final logRef = AdminLogService.instance.getNewLogRef();

    batch.set(msgRef, {
      'isPinned': true,
      'pinnedAt': FieldValue.serverTimestamp(),
      'pinnedBy': adminId,
    }, SetOptions(merge: true));

    batch.set(logRef, AdminLogService.instance.buildLogMap(
      adminName: adminName,
      actionType: 'PIN_MESSAGE',
      description: 'Pinned message $messageId in chat $roomId by $adminName',
      adminId: adminId,
      targetId: messageId,
      targetType: 'chats',
    ));

    await batch.commit();
  }

  Future<void> unpinMessage({
    required String roomId,
    required String messageId,
    required String adminId,
    required String adminName,
  }) async {
    final batch = _firestore.batch();
    final msgRef = _firestore.collection('chats').doc(roomId).collection('messages').doc(messageId);
    final logRef = AdminLogService.instance.getNewLogRef();

    batch.set(msgRef, {
      'isPinned': false,
      'pinnedAt': FieldValue.delete(),
      'pinnedBy': FieldValue.delete(),
    }, SetOptions(merge: true));

    batch.set(logRef, AdminLogService.instance.buildLogMap(
      adminName: adminName,
      actionType: 'UNPIN_MESSAGE',
      description: 'Unpinned message $messageId in chat $roomId by $adminName',
      adminId: adminId,
      targetId: messageId,
      targetType: 'chats',
    ));

    await batch.commit();
  }

  Future<void> deleteMessage({
    required String roomId,
    required String messageId,
    required String adminId,
    required String adminName,
  }) async {
    final batch = _firestore.batch();
    final msgRef = _firestore.collection('chats').doc(roomId).collection('messages').doc(messageId);
    final logRef = AdminLogService.instance.getNewLogRef();

    batch.set(msgRef, {
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'deletedBy': adminId,
    }, SetOptions(merge: true));

    batch.set(logRef, AdminLogService.instance.buildLogMap(
      adminName: adminName,
      actionType: 'DELETE_MESSAGE',
      description: 'Deleted message $messageId in chat $roomId by $adminName',
      adminId: adminId,
      targetId: messageId,
      targetType: 'chats',
    ));

    await batch.commit();
  }
}
