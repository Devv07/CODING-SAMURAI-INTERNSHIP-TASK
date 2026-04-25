enum MessageType { text, image }

enum MessageStatus { sending, sent, delivered, read }

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final int timestamp;
  final bool isDeleted;
  final String? replyToId;
  final String? replyContent;
  final String? replySenderId;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sending,
    required this.timestamp,
    this.isDeleted = false,
    this.replyToId,
    this.replyContent,
    this.replySenderId,
  });

  factory MessageModel.fromMap(Map<dynamic, dynamic> map) {
    return MessageModel(
      id: (map['id'] ?? '').toString(),
      senderId: (map['senderId'] ?? '').toString(),
      receiverId: (map['receiverId'] ?? '').toString(),
      content: (map['content'] ?? '').toString(),
      type: MessageType.values[(map['type'] as int?) ?? 0],
      status: MessageStatus.values[(map['status'] as int?) ?? 0],
      timestamp: (map['timestamp'] as int?) ?? 0,
      isDeleted: map['isDeleted'] == true,
      replyToId: map['replyToId']?.toString(),
      replyContent: map['replyContent']?.toString(),
      replySenderId: map['replySenderId']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'senderId': senderId,
    'receiverId': receiverId,
    'content': content,
    'type': type.index,
    'status': status.index,
    'timestamp': timestamp,
    'isDeleted': isDeleted,
    'replyToId': replyToId,
    'replyContent': replyContent,
    'replySenderId': replySenderId,
  };

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    MessageStatus? status,
    int? timestamp,
    bool? isDeleted,
    String? replyToId,
    String? replyContent,
    String? replySenderId,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      isDeleted: isDeleted ?? this.isDeleted,
      replyToId: replyToId ?? this.replyToId,
      replyContent: replyContent ?? this.replyContent,
      replySenderId: replySenderId ?? this.replySenderId,
    );
  }

  bool get isImage => type == MessageType.image;
  bool get isText => type == MessageType.text;
}