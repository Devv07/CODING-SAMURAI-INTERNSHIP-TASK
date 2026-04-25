// lib/services/chat_service.dart
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final _uuid = const Uuid();

  // ═══════════════════════════════════════════════════════════════════
  // USERS
  // ═══════════════════════════════════════════════════════════════════

  Stream<List<UserModel>> allUsersStream(String currentUid) {
    return _db.ref(AppConstants.pathUsers).onValue.map((event) {
      if (!event.snapshot.exists) return [];
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final users = <UserModel>[];
      data.forEach((key, value) {
        if (key.toString() != currentUid && value is Map) {
          try {
            users.add(UserModel.fromMap(value));
          } catch (_) {}
        }
      });
      users.sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
      return users;
    });
  }

  Stream<UserModel?> userStream(String uid) {
    return _db
        .ref('${AppConstants.pathUsers}/$uid')
        .onValue
        .map((e) {
      if (!e.snapshot.exists) return null;
      try {
        return UserModel.fromMap(
            e.snapshot.value as Map<dynamic, dynamic>);
      } catch (_) {
        return null;
      }
    });
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final snap =
      await _db.ref('${AppConstants.pathUsers}/$uid').get();
      if (!snap.exists) return null;
      return UserModel.fromMap(snap.value as Map<dynamic, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateProfile({
    required String uid,
    String? name,
    String? status,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (status != null) updates['status'] = status;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (updates.isNotEmpty) {
      await _db.ref('${AppConstants.pathUsers}/$uid').update(updates);
    }
  }

  Future<void> setUserOffline(String uid) async {
    try {
      await _db.ref('${AppConstants.pathUsers}/$uid').update({
        'isOnline': false,
        'lastSeen': ServerValue.timestamp,
      });
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════════════════
  // CHATS  — reads /chats node directly and filters by uid
  // This is the most reliable approach — no index needed
  // ═══════════════════════════════════════════════════════════════════

  Stream<List<ChatModel>> chatsStream(String uid) {

    // ✅ Read the entire /chats node and filter locally
    // This always works regardless of old/new data format
    return _db.ref(AppConstants.pathChats).onValue.map((event) {

      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <ChatModel>[];
      }

      final raw = event.snapshot.value as Map<dynamic, dynamic>;

      final chats = <ChatModel>[];
      raw.forEach((key, value) {
        if (value is! Map) return;
        try {
          final map = value as Map<dynamic, dynamic>;

          // ✅ Check ALL possible ways a uid can be stored
          final chatId = key.toString();
          bool isMyChat = false;

          // Method 1: senderId / receiverId fields (new format)
          final sender = (map['senderId'] ?? '').toString();
          final receiver = (map['receiverId'] ?? '').toString();
          if (sender == uid || receiver == uid) {
            isMyChat = true;
          }

          // Method 2: chatId contains uid (always true for our buildId)
          // ChatModel.buildId sorts and joins with _ so chatId = uid1_uid2
          if (!isMyChat && chatId.contains(uid)) {
            isMyChat = true;
          }

          // Method 3: participants map (old format)
          if (!isMyChat) {
            final parts = map['participants'];
            if (parts is Map) {
              parts.forEach((_, v) {
                if (v.toString() == uid) isMyChat = true;
              });
            } else if (parts is List) {
              for (final v in parts) {
                if (v.toString() == uid) isMyChat = true;
              }
            }
          }

          // Method 4: uid_0 / uid_1 flat fields
          if (!isMyChat) {
            if (map['uid_0'] == uid || map['uid_1'] == uid) {
              isMyChat = true;
            }
          }

          if (isMyChat) {
            // Build ChatModel — handle both old and new formats
            chats.add(_parseChatFromMap(chatId, map, uid));
          }
        } catch (e) {
        }
      });

      chats.sort(
              (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return chats;
    });
  }

  /// Parse a ChatModel from raw Firebase map, handling all formats
  ChatModel _parseChatFromMap(
      String chatId, Map<dynamic, dynamic> map, String currentUid) {
    // Get sender/receiver
    String sender = (map['senderId'] ?? '').toString();
    String receiver = (map['receiverId'] ?? '').toString();

    // Fallback: derive from chatId (format: uid1_uid2 sorted)
    if (sender.isEmpty || receiver.isEmpty) {
      // Try participants
      final parts = map['participants'];
      final list = <String>[];
      if (parts is Map) {
        parts.forEach((_, v) {
          if (v != null) list.add(v.toString());
        });
      } else if (parts is List) {
        for (final v in parts) {
          if (v != null) list.add(v.toString());
        }
      }
      if (list.length >= 2) {
        sender = list[0];
        receiver = list[1];
      }

      // Last fallback: split chatId by _
      if ((sender.isEmpty || receiver.isEmpty) && chatId.contains('_')) {
        final idx = chatId.indexOf('_');
        sender = chatId.substring(0, idx);
        receiver = chatId.substring(idx + 1);
      }
    }

    // Parse unreadCount
    final unread = <String, int>{};
    final rawUnread = map['unreadCount'];
    if (rawUnread is Map) {
      rawUnread.forEach((k, v) {
        unread[k.toString()] =
        (v is int) ? v : int.tryParse(v.toString()) ?? 0;
      });
    }

    return ChatModel(
      chatId: (map['chatId'] ?? chatId).toString(),
      senderId: sender,
      receiverId: receiver,
      lastMessage: (map['lastMessage'] ?? '').toString(),
      lastMessageSenderId:
      (map['lastMessageSenderId'] ?? '').toString(),
      lastMessageTime: (map['lastMessageTime'] as int?) ?? 0,
      lastMessageType: (map['lastMessageType'] as int?) ?? 0,
      unreadCount: unread,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // MESSAGES
  // ═══════════════════════════════════════════════════════════════════

  Stream<List<MessageModel>> messagesStream(String chatId) {
    return _db
        .ref('${AppConstants.pathMessages}/$chatId')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return [];
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final msgs = <MessageModel>[];
      data.forEach((_, v) {
        try {
          msgs.add(MessageModel.fromMap(v as Map<dynamic, dynamic>));
        } catch (_) {}
      });
      msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return msgs;
    });
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
    String? replyToId,
    String? replyContent,
    String? replySenderId,
  }) async {
    final chatId = ChatModel.buildId(senderId, receiverId);
    final msgId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Save message
    await _db
        .ref('${AppConstants.pathMessages}/$chatId/$msgId')
        .set(MessageModel(
      id: msgId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      type: type,
      status: MessageStatus.sent,
      timestamp: now,
      replyToId: replyToId,
      replyContent: replyContent,
      replySenderId: replySenderId,
    ).toMap());

    // 2. Save/update chat — always write senderId + receiverId as flat fields
    final chatRef = _db.ref('${AppConstants.pathChats}/$chatId');
    final chatSnap = await chatRef.get();

    if (!chatSnap.exists) {
      await chatRef.set({
        'chatId': chatId,
        'senderId': senderId,         // ✅ flat field
        'receiverId': receiverId,     // ✅ flat field
        'lastMessage': content,
        'lastMessageSenderId': senderId,
        'lastMessageTime': now,
        'lastMessageType': type.index,
        'unreadCount': {receiverId: 1, senderId: 0},
      });
    } else {
      // Also update senderId/receiverId in case old doc didn't have them
      final existingData =
      chatSnap.value as Map<dynamic, dynamic>;
      final unreadMap = existingData['unreadCount'];
      int currentUnread = 0;
      if (unreadMap is Map && unreadMap[receiverId] != null) {
        currentUnread = (unreadMap[receiverId] as int?) ?? 0;
      }
      await chatRef.update({
        'senderId': senderId,
        'receiverId': receiverId,
        'lastMessage': content,
        'lastMessageSenderId': senderId,
        'lastMessageTime': now,
        'lastMessageType': type.index,
        'unreadCount/$receiverId': currentUnread + 1,
      });
    }

    // 3. Delivered status
    Future.delayed(const Duration(milliseconds: 800), () {
      _db
          .ref(
          '${AppConstants.pathMessages}/$chatId/$msgId/status')
          .set(MessageStatus.delivered.index);
    });
  }

  Future<void> markAsRead({
    required String chatId,
    required String currentUserId,
  }) async {
    try {
      await _db
          .ref(
          '${AppConstants.pathChats}/$chatId/unreadCount/$currentUserId')
          .set(0);

      final snap = await _db
          .ref('${AppConstants.pathMessages}/$chatId')
          .orderByChild('receiverId')
          .equalTo(currentUserId)
          .get();

      if (!snap.exists) return;
      final updates = <String, dynamic>{};
      (snap.value as Map<dynamic, dynamic>).forEach((key, value) {
        final status = (value['status'] as int?) ?? 0;
        if (status < MessageStatus.read.index) {
          updates[
          '${AppConstants.pathMessages}/$chatId/$key/status'] =
              MessageStatus.read.index;
        }
      });
      if (updates.isNotEmpty) await _db.ref().update(updates);
    } catch (_) {}
  }

  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    await _db
        .ref('${AppConstants.pathMessages}/$chatId/$messageId')
        .update({
      'isDeleted': true,
      'content': 'This message was deleted',
    });
  }

  Future<void> setTyping({
    required String chatId,
    required String uid,
    required bool isTyping,
  }) async {
    await _db
        .ref('${AppConstants.pathChats}/$chatId/typing/$uid')
        .set(isTyping);
  }

  Stream<bool> typingStream(String chatId, String otherUid) {
    return _db
        .ref('${AppConstants.pathChats}/$chatId/typing/$otherUid')
        .onValue
        .map((e) => e.snapshot.value as bool? ?? false);
  }
}