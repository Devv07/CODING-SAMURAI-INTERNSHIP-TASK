// lib/models/chat_model.dart

class ChatModel {
  final String chatId;
  final String senderId;
  final String receiverId;
  final String lastMessage;
  final String lastMessageSenderId;
  final int lastMessageTime;
  final int lastMessageType;
  final Map<String, int> unreadCount;

  const ChatModel({
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageTime,
    this.lastMessageType = 0,
    required this.unreadCount,
  });

  factory ChatModel.fromMap(Map<dynamic, dynamic> map) {
    final unread = <String, int>{};
    final rawUnread = map['unreadCount'];
    if (rawUnread is Map) {
      rawUnread.forEach((k, v) {
        unread[k.toString()] =
        (v is int) ? v : int.tryParse(v.toString()) ?? 0;
      });
    }

    return ChatModel(
      chatId: (map['chatId'] ?? '').toString(),
      senderId: (map['senderId'] ?? '').toString(),
      receiverId: (map['receiverId'] ?? '').toString(),
      lastMessage: (map['lastMessage'] ?? '').toString(),
      lastMessageSenderId:
      (map['lastMessageSenderId'] ?? '').toString(),
      lastMessageTime: (map['lastMessageTime'] as int?) ?? 0,
      lastMessageType: (map['lastMessageType'] as int?) ?? 0,
      unreadCount: unread,
    );
  }

  Map<String, dynamic> toMap() => {
    'chatId': chatId,
    'senderId': senderId,
    'receiverId': receiverId,
    'lastMessage': lastMessage,
    'lastMessageSenderId': lastMessageSenderId,
    'lastMessageTime': lastMessageTime,
    'lastMessageType': lastMessageType,
    'unreadCount': unreadCount,
  };

  static String buildId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  String otherUid(String myUid) {
    if (senderId == myUid) return receiverId;
    if (receiverId == myUid) return senderId;
    // Fallback: split chatId
    if (chatId.contains('_')) {
      final parts = chatId.split('_');
      if (parts[0] == myUid) return parts[1];
      if (parts[1] == myUid) return parts[0];
    }
    return '';
  }

  int unreadFor(String uid) => unreadCount[uid] ?? 0;
}