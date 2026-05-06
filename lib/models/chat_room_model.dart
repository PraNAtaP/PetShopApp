import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a chat room between two participants.
class ChatRoomModel {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastTime;
  
  /// The name of the other participant. 
  /// In the document, this is often stored as a map or individual fields.
  final String? receiverName;

  const ChatRoomModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastTime,
    this.receiverName,
  });

  /// Maps a Firestore document to [ChatRoomModel].
  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoomModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] as String?,
      lastTime: (data['lastTime'] as Timestamp?)?.toDate(),
      // We store a map of names to determine the receiver name dynamically if needed,
      // but the spec specifically asked for a single receiverName field.
      receiverName: data['receiverName'] as String?,
    );
  }

  /// Converts this instance to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastTime': lastTime != null ? Timestamp.fromDate(lastTime!) : FieldValue.serverTimestamp(),
      'receiverName': receiverName,
    };
  }

  ChatRoomModel copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastTime,
    String? receiverName,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTime: lastTime ?? this.lastTime,
      receiverName: receiverName ?? this.receiverName,
    );
  }
}
