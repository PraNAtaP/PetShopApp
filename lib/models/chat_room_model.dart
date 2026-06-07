import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a chat room between two participants.
class ChatRoomModel {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastTime;
  final String? receiverName;
  final String? customerName; 
  final bool isPinned;
  final bool isDeleted; // Tambahkan field isDeleted untuk Soft Delete

  const ChatRoomModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastTime,
    this.receiverName,
    this.customerName,
    this.isPinned = false,
    this.isDeleted = false, // Secara default bernilai false (aktif)
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
      isPinned: data['isPinned'] as bool? ?? false,
      isDeleted: data['isDeleted'] as bool? ?? false, // Parsing field isDeleted
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
      'isPinned': isPinned,
      'isDeleted': isDeleted, // Simpan status isDeleted ke Firestore
    };
  }

  ChatRoomModel copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastTime,
    String? receiverName,
    String? customerName,
    bool? isPinned,
    bool? isDeleted,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTime: lastTime ?? this.lastTime,
      receiverName: receiverName ?? this.receiverName,
      customerName: customerName ?? this.customerName,
      isPinned: isPinned ?? this.isPinned,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}