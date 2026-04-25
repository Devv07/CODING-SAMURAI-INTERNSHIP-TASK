// lib/screens/chat_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' as foundation;
import '../services/chat_service.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';
import '../widgets/message_bubble.dart';

// ─── Why the screen was blinking on every keystroke ───────────────────────
//
// CAUSE 1 — _onType() called setState(() => _isTyping = hasText)
//   This rebuilt the ENTIRE widget tree — AppBar, message StreamBuilder,
//   input bar, emoji picker. The StreamBuilder re-subscribed each time
//   causing the message list to flash.
//
// CAUSE 2 — AnimatedContainer for send button read _isTyping from parent
//   state, so every character = setState = full rebuild.
//
// CAUSE 3 — _showEmoji, _replyMsg, _uploading also called setState on
//   the parent, cascading rebuilds into the message list.
//
// FIX — Use ValueNotifier for every piece of UI state that changes
//   during normal use. ValueNotifier.value = x costs ZERO parent rebuilds.
//   Only ValueListenableBuilder widgets that directly listen to that
//   notifier will repaint — the message list is completely untouched.
//
// RESULT — Typing, emoji toggle, reply preview, send button animation
//   all update with zero impact on the message StreamBuilder.
// ─────────────────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  final UserModel otherUser;
  final String chatId;

  const ChatScreen({
    super.key,
    required this.otherUser,
    required this.chatId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  final ChatService _chatSvc = ChatService();
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final Uuid _uuid = const Uuid();

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ✅ ValueNotifiers — changing these triggers ZERO parent setState calls
  final ValueNotifier<bool> _isTyping = ValueNotifier(false);
  final ValueNotifier<bool> _showEmoji = ValueNotifier(false);
  final ValueNotifier<bool> _uploading = ValueNotifier(false);
  final ValueNotifier<double> _uploadPct = ValueNotifier(0.0);
  final ValueNotifier<MessageModel?> _replyMsg = ValueNotifier(null);

  // Send button animation — driven by _isTyping notifier
  late AnimationController _sendBtnAnim;
  late Animation<double> _sendBtnScale;

  Timer? _typingTimer;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _sendBtnAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1.0,
    );
    _sendBtnScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _sendBtnAnim, curve: Curves.elasticOut),
    );
    _chatSvc.markAsRead(
        chatId: widget.chatId, currentUserId: _uid);
    _msgCtrl.addListener(_onType);
  }

  @override
  void dispose() {
    _msgCtrl
      ..removeListener(_onType)
      ..dispose();
    _scrollCtrl.dispose();
    _typingTimer?.cancel();
    _sendBtnAnim.dispose();
    // Dispose all ValueNotifiers
    _isTyping.dispose();
    _showEmoji.dispose();
    _uploading.dispose();
    _uploadPct.dispose();
    _replyMsg.dispose();
    _chatSvc.setTyping(
        chatId: widget.chatId, uid: _uid, isTyping: false);
    super.dispose();
  }

  // ─── Typing ───────────────────────────────────────────────────────────────

  void _onType() {
    final hasText = _msgCtrl.text.trim().isNotEmpty;

    // ✅ NO setState — just update the notifier
    // Only _SendButton and _EmojiToggle will repaint
    if (hasText != _isTyping.value) {
      _isTyping.value = hasText;
      if (hasText) {
        _sendBtnAnim.forward();
      } else {
        _sendBtnAnim.reverse();
      }
    }

    _chatSvc.setTyping(
        chatId: widget.chatId, uid: _uid, isTyping: hasText);
    _typingTimer?.cancel();
    if (hasText) {
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _chatSvc.setTyping(
            chatId: widget.chatId, uid: _uid, isTyping: false);
      });
    }
  }

  // ─── Send text ────────────────────────────────────────────────────────────

  Future<void> _sendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    final reply = _replyMsg.value;
    _msgCtrl.clear();
    _replyMsg.value = null; // ✅ notifier — no setState
    _sendBtnAnim.reverse().then((_) => _sendBtnAnim.forward());
    await _chatSvc.sendMessage(
      senderId: _uid,
      receiverId: widget.otherUser.uid,
      content: text,
      type: MessageType.text,
      replyToId: reply?.id,
      replyContent: reply?.content,
      replySenderId: reply?.senderId,
    );
    _scrollToBottom();
  }

  // ─── Send image ───────────────────────────────────────────────────────────

  Future<void> _pickAndSendImage({bool fromCamera = false}) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1200,
    );
    if (picked == null) return;

    // ✅ notifier — no setState
    _uploading.value = true;
    _uploadPct.value = 0;

    try {
      final fileName = '${_uuid.v4()}.jpg';
      final ref = FirebaseStorage.instance
          .ref('chat_images/${widget.chatId}/$fileName');

      final task = ref.putFile(
        File(picked.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      task.snapshotEvents.listen((snap) {
        _uploadPct.value =
            snap.bytesTransferred / snap.totalBytes;
      });

      await task;
      final url = await ref.getDownloadURL();

      await _chatSvc.sendMessage(
        senderId: _uid,
        receiverId: widget.otherUser.uid,
        content: url,
        type: MessageType.image,
        replyToId: _replyMsg.value?.id,
        replyContent: _replyMsg.value?.content,
        replySenderId: _replyMsg.value?.senderId,
      );
      _replyMsg.value = null;
      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send image. Please try again.'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } finally {
      _uploading.value = false;
    }
  }

  // ─── Scroll ───────────────────────────────────────────────────────────────

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final max = _scrollCtrl.position.maxScrollExtent;
      if (jump) {
        _scrollCtrl.jumpTo(max);
      } else {
        _scrollCtrl.animateTo(max,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut);
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD — parent build() is called ONCE on init and NEVER again
  //  during normal chat use (typing, emoji, reply, send button)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // ✅ RepaintBoundary — AppBar repaints isolated from message list
            RepaintBoundary(child: _buildAppBar()),

            // ✅ Upload bar — only shown during image upload via ValueListenableBuilder
            ValueListenableBuilder<bool>(
              valueListenable: _uploading,
              builder: (_, uploading, __) =>
              uploading ? _buildUploadBar() : const SizedBox.shrink(),
            ),

            // ✅ Message list — NEVER rebuilt by typing/emoji/reply changes
            // Only rebuilt when Firebase sends new messages
            Expanded(
              child: RepaintBoundary(
                child: _MessageList(
                  chatId: widget.chatId,
                  myUid: _uid,
                  chatSvc: _chatSvc,
                  scrollCtrl: _scrollCtrl,
                  otherUser: widget.otherUser,
                  replyNotifier: _replyMsg,
                ),
              ),
            ),

            // ✅ Reply preview — only this widget rebuilds when _replyMsg changes
            ValueListenableBuilder<MessageModel?>(
              valueListenable: _replyMsg,
              builder: (_, reply, __) => reply != null
                  ? _buildReplyPreview(reply)
                  : const SizedBox.shrink(),
            ),

            // ✅ Input bar — only the send button and emoji icon
            // inside it rebuild (via their own ValueListenableBuilders)
            _buildInputBar(),

            // ✅ Emoji picker — shown/hidden via ValueListenableBuilder
            ValueListenableBuilder<bool>(
              valueListenable: _showEmoji,
              builder: (_, show, __) => AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: show
                    ? _buildEmojiPicker()
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 10, 8),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        boxShadow: [
          BoxShadow(
              color: Color(0x28000000),
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          _buildAvatarWidget(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUser.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                _buildSubtitle(),
              ],
            ),
          ),
          _buildMenuButton(),
        ],
      ),
    );
  }

  Widget _buildAvatarWidget() {
    final colors = AppColors.avatarColor(widget.otherUser.name);
    return Stack(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: colors),
          ),
          child: widget.otherUser.photoUrl.isNotEmpty
              ? ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.network(
                  widget.otherUser.photoUrl,
                  fit: BoxFit.cover))
              : Center(
            child: Text(
              widget.otherUser.initials,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
        StreamBuilder<UserModel?>(
          stream: _chatSvc.userStream(widget.otherUser.uid),
          builder: (_, snap) {
            final online = snap.data?.isOnline ?? false;
            return Positioned(
              bottom: 1,
              right: 1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: online
                      ? AppColors.online
                      : AppColors.offline,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.bgCard, width: 2),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSubtitle() {
    return StreamBuilder<bool>(
      stream: _chatSvc.typingStream(
          widget.chatId, widget.otherUser.uid),
      builder: (_, typingSnap) {
        if (typingSnap.data == true) {
          return const Text(
            'typing...',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.primary,
              fontStyle: FontStyle.italic,
            ),
          );
        }
        return StreamBuilder<UserModel?>(
          stream: _chatSvc.userStream(widget.otherUser.uid),
          builder: (_, uSnap) {
            final online = uSnap.data?.isOnline ?? false;
            final last = uSnap.data?.lastSeen ?? 0;
            final text = online
                ? 'Online'
                : last > 0
                ? 'Last seen ${DateFormat('h:mm a').format(DateTime.fromMillisecondsSinceEpoch(last))}'
                : 'Offline';
            return Text(
              text,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: online
                    ? AppColors.online
                    : AppColors.textHint,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMenuButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded,
          color: AppColors.textSecondary),
      color: AppColors.bgCard,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => [
        _menuItem('profile', Icons.person_outline_rounded,
            'View Profile'),
        _menuItem('clear', Icons.cleaning_services_outlined,
            'Clear Chat'),
        _menuItem('block', Icons.block_rounded, 'Block User',
            color: AppColors.accent),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(
      String val,
      IconData icon,
      String label, {
        Color color = AppColors.textPrimary,
      }) {
    return PopupMenuItem(
      value: val,
      child: Row(children: [
        Icon(icon,
            color: color == AppColors.textPrimary
                ? AppColors.textSecondary
                : color,
            size: 18),
        const SizedBox(width: 12),
        Text(label,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: color)),
      ]),
    );
  }

  // ─── Upload bar ───────────────────────────────────────────────────────────

  Widget _buildUploadBar() {
    return ValueListenableBuilder<double>(
      valueListenable: _uploadPct,
      builder: (_, pct, __) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8),
        color: AppColors.bgCard,
        child: Row(
          children: [
            const Icon(Icons.image_outlined,
                color: AppColors.primary, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Uploading image...',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: AppColors.bgInput,
                      valueColor:
                      const AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text('${(pct * 100).toInt()}%',
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  // ─── Reply preview ────────────────────────────────────────────────────────

  Widget _buildReplyPreview(MessageModel reply) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(
          left: BorderSide(color: AppColors.primary, width: 3),
          top: BorderSide(color: AppColors.bgInput, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded,
              color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  reply.senderId == _uid
                      ? 'You'
                      : widget.otherUser.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reply.isImage ? '📷 Photo' : reply.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _replyMsg.value = null,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: AppColors.bgInput,
                  shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded,
                  color: AppColors.textHint, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Input bar ────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        boxShadow: [
          BoxShadow(
              color: Color(0x22000000),
              blurRadius: 8,
              offset: Offset(0, -2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ✅ Emoji toggle — only this icon rebuilds when _showEmoji changes
          ValueListenableBuilder<bool>(
            valueListenable: _showEmoji,
            builder: (_, show, __) => GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                _showEmoji.value = !show;
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.bgInput,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  show
                      ? Icons.keyboard_rounded
                      : Icons.emoji_emotions_outlined,
                  color: show
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ✅ Text field — TextField never calls setState on parent
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.bgInput,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      maxLines: null,
                      textCapitalization:
                      TextCapitalization.sentences,
                      onTap: () {
                        if (_showEmoji.value) {
                          _showEmoji.value = false;
                        }
                      },
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        filled: false,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showAttachSheet,
                    child: const Padding(
                      padding:
                      EdgeInsets.only(right: 10, bottom: 10),
                      child: Icon(Icons.attach_file_rounded,
                          color: AppColors.textHint, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ✅ Send button — only this widget rebuilds when _isTyping changes
          ScaleTransition(
            scale: _sendBtnScale,
            child: ValueListenableBuilder<bool>(
              valueListenable: _isTyping,
              builder: (_, typing, __) => GestureDetector(
                onTap: _sendText,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: typing
                        ? const LinearGradient(
                      colors: [
                        AppColors.primary,
                        Color(0xFF0072FF)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : null,
                    color: typing ? null : AppColors.bgInput,
                    boxShadow: typing
                        ? [
                      BoxShadow(
                        color:
                        AppColors.primary.withOpacity(0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      )
                    ]
                        : [],
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: typing
                        ? Colors.white
                        : AppColors.textHint,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Attach sheet ─────────────────────────────────────────────────────────

  void _showAttachSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.bgInput,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _attachOpt(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    colors: const [
                      Color(0xFF00C9A7),
                      Color(0xFF0072FF)
                    ],
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndSendImage(fromCamera: false);
                    },
                  ),
                  _attachOpt(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    colors: const [
                      Color(0xFFFF6B6B),
                      Color(0xFFFFB347)
                    ],
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndSendImage(fromCamera: true);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachOpt({
    required IconData icon,
    required String label,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ─── Emoji picker ─────────────────────────────────────────────────────────

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 280,
      child: EmojiPicker(
        onEmojiSelected: (Category? category, Emoji emoji) {
          _msgCtrl
            ..text += emoji.emoji
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: _msgCtrl.text.length),
            );
        },
        onBackspacePressed: () {
          final text = _msgCtrl.text;
          if (text.isNotEmpty) {
            _msgCtrl
              ..text = text.characters.skipLast(1).string
              ..selection = TextSelection.fromPosition(
                TextPosition(offset: _msgCtrl.text.length),
              );
          }
        },
        textEditingController: _msgCtrl,
        config: Config(
          height: 280,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            emojiSizeMax: 28 *
                (foundation.defaultTargetPlatform ==
                    TargetPlatform.iOS
                    ? 1.20
                    : 1.0),
            backgroundColor: AppColors.bgCard,
            buttonMode: ButtonMode.MATERIAL,
            recentsLimit: 28,
            noRecents: const Text(
              'No Recents',
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textHint,
                  fontFamily: 'Poppins'),
              textAlign: TextAlign.center,
            ),
          ),
          categoryViewConfig: const CategoryViewConfig(
            backgroundColor: AppColors.bgCard,
            indicatorColor: AppColors.primary,
            iconColor: AppColors.textHint,
            iconColorSelected: AppColors.primary,
            backspaceColor: AppColors.primary,
          ),
          bottomActionBarConfig: const BottomActionBarConfig(
            backgroundColor: AppColors.bgCard,
            buttonColor: AppColors.bgCard,
            buttonIconColor: AppColors.textSecondary,
          ),
          searchViewConfig: const SearchViewConfig(
            backgroundColor: AppColors.bgCard,
            buttonIconColor: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  bool _sameDay(int ts1, int ts2) {
    final a = DateTime.fromMillisecondsSinceEpoch(ts1);
    final b = DateTime.fromMillisecondsSinceEpoch(ts2);
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }
}

class _MessageList extends StatefulWidget {
  final String chatId;
  final String myUid;
  final ChatService chatSvc;
  final ScrollController scrollCtrl;
  final UserModel otherUser;
  final ValueNotifier<MessageModel?> replyNotifier;

  const _MessageList({
    required this.chatId,
    required this.myUid,
    required this.chatSvc,
    required this.scrollCtrl,
    required this.otherUser,
    required this.replyNotifier,
  });

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MessageModel>>(
      stream: widget.chatSvc.messagesStream(widget.chatId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
                color: AppColors.primary),
          );
        }

        final msgs = snapshot.data ?? [];

        if (msgs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('👋',
                    style: TextStyle(fontSize: 48)),
                const SizedBox(height: 14),
                Text(
                  'Say hi to ${widget.otherUser.name}!',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        widget.chatSvc.markAsRead(
            chatId: widget.chatId,
            currentUserId: widget.myUid);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.scrollCtrl.hasClients) {
            widget.scrollCtrl.jumpTo(
                widget.scrollCtrl.position.maxScrollExtent);
          }
        });

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView.builder(
            controller: widget.scrollCtrl,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            itemCount: msgs.length,
            itemBuilder: (_, i) {
              final msg = msgs[i];
              final isMe = msg.senderId == widget.myUid;
              final showDate = i == 0 ||
                  !_sameDay(
                      msgs[i - 1].timestamp, msg.timestamp);
              final showAvatar = !isMe &&
                  (i == msgs.length - 1 ||
                      msgs[i + 1].senderId != msg.senderId);

              return Column(
                children: [
                  if (showDate) _dateDivider(msg.timestamp),
                  MessageBubble(
                    message: msg,
                    isMe: isMe,
                    showAvatar: showAvatar,
                    otherUserName: widget.otherUser.name,
                    otherUserPhoto: widget.otherUser.photoUrl,
                    onReply: () =>
                    widget.replyNotifier.value = msg,
                    onDelete: isMe
                        ? () => widget.chatSvc.deleteMessage(
                        chatId: widget.chatId,
                        messageId: msg.id)
                        : null,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _dateDivider(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final now = DateTime.now();
    String label;
    if (_sameDay(ts, now.millisecondsSinceEpoch)) {
      label = 'Today';
    } else if (_sameDay(
        ts,
        now
            .subtract(const Duration(days: 1))
            .millisecondsSinceEpoch)) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMMM d, yyyy').format(d);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const Expanded(
              child:
              Divider(color: AppColors.bgInput, thickness: 1)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.bgInput),
            ),
            child: Text(label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                )),
          ),
          const Expanded(
              child:
              Divider(color: AppColors.bgInput, thickness: 1)),
        ],
      ),
    );
  }

  bool _sameDay(int ts1, int ts2) {
    final a = DateTime.fromMillisecondsSinceEpoch(ts1);
    final b = DateTime.fromMillisecondsSinceEpoch(ts2);
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }
}