import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single chat message within a chat room.
class ChatMessageModel {
  final String? id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final DateTime? timestamp;
  final bool isRead;

  const ChatMessageModel({
    this.id,
    required this.senderId,
    this.text = '',
    this.imageUrl,
    this.timestamp,
    this.isRead = false,
  });

  /// Maps a Firestore document to [ChatMessageModel].
  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'] as String?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      isRead: data['isRead'] ?? false,
    );
  }

  /// Converts this instance to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? senderId,
    String? text,
    String? imageUrl,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
