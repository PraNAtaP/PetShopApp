import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single chat message within a chat room.
class ChatMessageModel {
  final String? id;
  final String senderId;
  final String text; // canonical for customer messages
  final String? imageUrl;
  final DateTime? timestamp;
  final bool isRead;

  // Admin-related optional fields (backward-compatible)
  final bool isPinned;
  final DateTime? pinnedAt;
  final String? pinnedBy;

  final bool isDeleted;
  final DateTime? deletedAt;
  final String? deletedBy;

  const ChatMessageModel({
    this.id,
    required this.senderId,
    this.text = '',
    this.imageUrl,
    this.timestamp,
    this.isRead = false,
    this.isPinned = false,
    this.pinnedAt,
    this.pinnedBy,
    this.isDeleted = false,
    this.deletedAt,
    this.deletedBy,
  });

  /// Maps a Firestore document to [ChatMessageModel].
  /// Supports legacy admin field 'message' as fallback for text.
  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? data['message'] ?? '',
      imageUrl: data['imageUrl'] as String?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      isRead: data['isRead'] ?? false,
      isPinned: data['isPinned'] as bool? ?? false,
      pinnedAt: (data['pinnedAt'] as Timestamp?)?.toDate(),
      pinnedBy: data['pinnedBy'] as String?,
      isDeleted: data['isDeleted'] as bool? ?? false,
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      deletedBy: data['deletedBy'] as String?,
    );
  }

  /// Converts this instance to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'senderId': senderId,
      'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };

    if (isPinned) map['isPinned'] = true;
    if (pinnedAt != null) map['pinnedAt'] = Timestamp.fromDate(pinnedAt!);
    if (pinnedBy != null) map['pinnedBy'] = pinnedBy;

    if (isDeleted) map['isDeleted'] = true;
    if (deletedAt != null) map['deletedAt'] = Timestamp.fromDate(deletedAt!);
    if (deletedBy != null) map['deletedBy'] = deletedBy;

    return map;
  }

  ChatMessageModel copyWith({
    String? id,
    String? senderId,
    String? text,
    String? imageUrl,
    DateTime? timestamp,
    bool? isRead,
    bool? isPinned,
    DateTime? pinnedAt,
    String? pinnedBy,
    bool? isDeleted,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      pinnedBy: pinnedBy ?? this.pinnedBy,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }
}
