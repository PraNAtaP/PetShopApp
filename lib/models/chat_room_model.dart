import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a chat room between two participants.
class ChatRoomModel {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastTime;
  final String? receiverName;
  final String? customerName; // Added to store the customer's real name

  const ChatRoomModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastTime,
    this.receiverName,
    this.customerName,
  });

  /// Maps a Firestore document to [ChatRoomModel].
  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoomModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] as String?,
      lastTime: (data['lastTime'] as Timestamp?)?.toDate(),
      receiverName: data['receiverName'] as String?,
      customerName: data['customerName'] as String?,
    );
  }

  /// Converts this instance to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastTime': lastTime != null ? Timestamp.fromDate(lastTime!) : FieldValue.serverTimestamp(),
      'receiverName': receiverName,
      'customerName': customerName,
    };
  }

  ChatRoomModel copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastTime,
    String? receiverName,
    String? customerName,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTime: lastTime ?? this.lastTime,
      receiverName: receiverName ?? this.receiverName,
      customerName: customerName ?? this.customerName,
    );
  }
}
