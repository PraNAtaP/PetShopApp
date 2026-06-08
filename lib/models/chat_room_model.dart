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
  final DateTime? pinnedAt;
  final String? pinnedBy;
  final bool isDeleted; // Tambahkan field isDeleted untuk Soft Delete
  final DateTime? deletedAt;
  final String? deletedBy;

  const ChatRoomModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastTime,
    this.receiverName,
    this.customerName,
    this.isPinned = false,
    this.pinnedAt,
    this.pinnedBy,
    this.isDeleted = false, // Secara default bernilai false (aktif)
    this.deletedAt,
    this.deletedBy,
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
      'participants': participants,
      'lastMessage': lastMessage,
      'lastTime': lastTime != null ? Timestamp.fromDate(lastTime!) : FieldValue.serverTimestamp(),
      'receiverName': receiverName,
      'customerName': customerName,
      'isPinned': isPinned,
      'isDeleted': isDeleted,
    };

    if (pinnedAt != null) map['pinnedAt'] = Timestamp.fromDate(pinnedAt!);
    if (pinnedBy != null) map['pinnedBy'] = pinnedBy;
    if (deletedAt != null) map['deletedAt'] = Timestamp.fromDate(deletedAt!);
    if (deletedBy != null) map['deletedBy'] = deletedBy;

    return map;
  }

  ChatRoomModel copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastTime,
    String? receiverName,
    String? customerName,
    bool? isPinned,
    DateTime? pinnedAt,
    String? pinnedBy,
    bool? isDeleted,
    DateTime? deletedAt,
    String? deletedBy,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTime: lastTime ?? this.lastTime,
      receiverName: receiverName ?? this.receiverName,
      customerName: customerName ?? this.customerName,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      pinnedBy: pinnedBy ?? this.pinnedBy,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }
}