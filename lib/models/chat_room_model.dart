import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a chat room between a customer and an admin.
class ChatRoomModel {
  final String roomId;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastUpdate;

  /// Creates a new [ChatRoomModel] instance.
  const ChatRoomModel({
    required this.roomId,
    required this.participants,
    this.lastMessage,
    this.lastUpdate,
  });

  /// Factory constructor to map Firestore [DocumentSnapshot] to [ChatRoomModel].
  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoomModel(
      roomId: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['last_message'] as String?,
      lastUpdate: (data['last_update'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts the [ChatRoomModel] instance into a Map.
  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'last_message': lastMessage,
      'last_update': lastUpdate != null ? Timestamp.fromDate(lastUpdate!) : FieldValue.serverTimestamp(),
    };
  }

  /// Creates a copy of this [ChatRoomModel] maintaining immutability.
  ChatRoomModel copyWith({
    String? roomId,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastUpdate,
  }) {
    return ChatRoomModel(
      roomId: roomId ?? this.roomId,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}
