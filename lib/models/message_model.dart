import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single chat message within a chat room.
class MessageModel {
  final String messageId;
  final String senderId;
  final String text;
  final bool isRead;
  final DateTime? timestamp;

  /// Creates a new [MessageModel] instance.
  const MessageModel({
    required this.messageId,
    required this.senderId,
    required this.text,
    required this.isRead,
    this.timestamp,
  });

  /// Factory constructor to map Firestore [DocumentSnapshot] to [MessageModel].
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      messageId: doc.id,
      senderId: data['sender_id'] ?? '',
      text: data['text'] ?? '',
      isRead: data['is_read'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts the [MessageModel] instance into a Map.
  Map<String, dynamic> toMap() {
    return {
      'sender_id': senderId,
      'text': text,
      'is_read': isRead,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp(),
    };
  }

  /// Creates a copy of this [MessageModel] maintaining immutability.
  MessageModel copyWith({
    String? messageId,
    String? senderId,
    String? text,
    bool? isRead,
    DateTime? timestamp,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
