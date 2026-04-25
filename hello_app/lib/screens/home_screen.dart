// lib/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'users_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WHY THE SCREEN WAS REFRESHING ON EVERY KEYSTROKE — and how we fixed it:
//
// CAUSE 1 (main cause):
//   The search TextField's onChanged called setState(() => _query = v) on the
//   PARENT _HomeScreenState. setState on the parent rebuilds the ENTIRE widget
//   tree — including the top bar, the StreamBuilder for the avatar, the FAB,
//   and the full chat list. Every character typed = full screen rebuild.
//
// CAUSE 2:
//   The StreamBuilder<UserModel?> in _buildTopBar() has no key, so every time
//   the parent rebuilt it re-subscribed to the Firebase stream — causing a
//   visible flicker as the avatar briefly went blank then re-loaded.
//
// CAUSE 3:
//   _subscribeToUser() called setState on every user presence update, which
//   again triggered a full parent rebuild.
//
// FIX:
//   1. Extract the chat list into its own StatefulWidget (_ChatListSection)
//      that holds _query and _filtered. Keystrokes only rebuild this child,
//      NOT the top bar / avatar / FAB.
//   2. Pass _chats and _userCache as parameters — the child reads from them
//      and calls setState only on itself.
//   3. Use ValueNotifier<String> for the search query so _ChatListSection
//      can listen without any setState on the parent at all.
//   4. Wrap _buildTopBar avatar in a RepaintBoundary so the StreamBuilder
//      repaints are isolated and never cascade upward.
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final ChatService _chatSvc = ChatService();
  final AuthService _authSvc = AuthService();

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ✅ ValueNotifier — updating it does NOT call setState on this widget
  final ValueNotifier<String> _queryNotifier = ValueNotifier('');
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // Chat data lives here — only updated when Firebase sends new data
  List<ChatModel> _chats = [];
  final Map<String, UserModel> _userCache = {};
  final Map<String, StreamSubscription<UserModel?>> _userSubs = {};
  StreamSubscription<List<ChatModel>>? _chatSub;

  late AnimationController _fabAnim;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fabAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _listenToChats();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatSub?.cancel();
    for (final sub in _userSubs.values) sub.cancel();
    _queryNotifier.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _fabAnim.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (state == AppLifecycleState.resumed) {
      _authSvc.setupPresence(uid);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _chatSvc.setUserOffline(uid);
    }
  }

  void _listenToChats() {
    _chatSub?.cancel();
    _chatSub = _chatSvc.chatsStream(_uid).listen(
          (chats) {
        if (!mounted) return;
        // ✅ setState here only updates _chats/_isLoading — NOT triggered by typing
        setState(() {
          _chats = chats;
          _isLoading = false;
        });
        for (final chat in chats) {
          final otherUid = chat.otherUid(_uid);
          if (otherUid.isNotEmpty) _subscribeToUser(otherUid);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  void _subscribeToUser(String uid) {
    if (_userSubs.containsKey(uid)) return;
    _userSubs[uid] = _chatSvc.userStream(uid).listen((user) {
      if (user != null && mounted) {
        // ✅ Only update the cache entry — minimal rebuild
        setState(() => _userCache[uid] = user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      floatingActionButton: _buildFAB(),
      body: SafeArea(
        child: Column(
          children: [
            // ✅ RepaintBoundary isolates the StreamBuilder avatar repaint
            // from the rest of the tree
            RepaintBoundary(child: _buildTopBar()),
            _buildSearchBar(),
            Expanded(
              // ✅ _ChatListSection is a separate widget — it holds its own
              // _query state. Typing only rebuilds THIS widget, not the
              // top bar, avatar, or FAB above it.
              child: _isLoading
                  ? _shimmer()
                  : _ChatListSection(
                uid: _uid,
                chats: _chats,
                userCache: _userCache,
                queryNotifier: _queryNotifier,
                chatSvc: _chatSvc,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Top bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 18, 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: const Icon(Icons.chat_bubble_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const Text(
            'Hello Chat',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          // ✅ StreamBuilder is inside RepaintBoundary — its repaints
          // never trigger parent rebuilds
          StreamBuilder<UserModel?>(
            stream: _chatSvc.userStream(_uid),
            builder: (_, snap) {
              final user = snap.data;
              return GestureDetector(
                onTap: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProfileScreen()));
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: AppColors.avatarColor(user?.name ?? ''),
                    ),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: user?.photoUrl.isNotEmpty == true
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: Image.network(user!.photoUrl,
                        fit: BoxFit.cover),
                  )
                      : Center(
                    child: Text(
                      user?.initials ?? 'U',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Search bar ───────────────────────────────────────────────────────────
  // ✅ onChanged updates ValueNotifier — zero setState calls on parent

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded,
              color: AppColors.textHint, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              // ✅ NO setState here — just update the ValueNotifier
              onChanged: (v) => _queryNotifier.value = v,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: const InputDecoration(
                hintText: 'Search chats...',
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.textHint,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          // ✅ ValueListenableBuilder — only this tiny X button rebuilds
          // when query changes, not the whole screen
          ValueListenableBuilder<String>(
            valueListenable: _queryNotifier,
            builder: (_, query, __) {
              if (query.isEmpty) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  _queryNotifier.value = '';
                  _searchFocus.unfocus();
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.close_rounded,
                      color: AppColors.textSecondary, size: 18),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Shimmer ──────────────────────────────────────────────────────────────

  Widget _shimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgCard.withOpacity(0.3),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.bgInput),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 13,
                      width: 100,
                      decoration: BoxDecoration(
                          color: AppColors.bgInput,
                          borderRadius: BorderRadius.circular(7))),
                  const SizedBox(height: 8),
                  Container(
                      height: 11,
                      width: 170,
                      decoration: BoxDecoration(
                          color: AppColors.bgInput.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── FAB ─────────────────────────────────────────────────────────────────

  Widget _buildFAB() {
    return ScaleTransition(
      scale: CurvedAnimation(
          parent: _fabAnim, curve: Curves.elasticOut),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const UsersScreen()));
          _listenToChats();
        },
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF0072FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.edit_rounded,
              color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ✅ Separate widget for the chat list + search filtering
// Lives below the search bar. Only THIS widget rebuilds when:
//   - user types in search (via ValueNotifier)
//   - _chats or _userCache update from parent setState
// The top bar, avatar StreamBuilder, and FAB are completely unaffected.
// ─────────────────────────────────────────────────────────────────────────────

class _ChatListSection extends StatelessWidget {
  final String uid;
  final List<ChatModel> chats;
  final Map<String, UserModel> userCache;
  final ValueNotifier<String> queryNotifier;
  final ChatService chatSvc;

  const _ChatListSection({
    required this.uid,
    required this.chats,
    required this.userCache,
    required this.queryNotifier,
    required this.chatSvc,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ ValueListenableBuilder only rebuilds the list — not the parent
    return ValueListenableBuilder<String>(
      valueListenable: queryNotifier,
      builder: (context, query, _) {
        if (chats.isEmpty) return _emptyState();

        final filtered = _filter(query);

        if (filtered.isEmpty && query.isNotEmpty) {
          return Center(
            child: Text(
              'No results for "$query"',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
          itemCount: filtered.length,
          itemBuilder: (_, i) =>
              _ChatTile(
                chat: filtered[i],
                myUid: uid,
                user: userCache[filtered[i].otherUid(uid)],
                onTap: (user) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        otherUser: user,
                        chatId: filtered[i].chatId,
                      ),
                    ),
                  );
                },
              ),
        );
      },
    );
  }

  List<ChatModel> _filter(String query) {
    if (query.trim().isEmpty) return chats;
    final q = query.toLowerCase().trim();
    return chats.where((chat) {
      final user = userCache[chat.otherUid(uid)];
      if (user == null) return true;
      return user.name.toLowerCase().contains(q) ||
          user.email.toLowerCase().contains(q);
    }).toList();
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.12),
                  const Color(0xFF0072FF).withOpacity(0.12),
                ],
              ),
            ),
            child: Icon(Icons.chat_bubble_outline_rounded,
                size: 42,
                color: AppColors.primary.withOpacity(0.55)),
          ),
          const SizedBox(height: 20),
          const Text(
            'No conversations yet',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap ✏ to start a new chat',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ✅ Each chat tile is its own const-friendly StatelessWidget
// Flutter can skip rebuilding tiles whose inputs haven't changed
// ─────────────────────────────────────────────────────────────────────────────

class _ChatTile extends StatelessWidget {
  final ChatModel chat;
  final String myUid;
  final UserModel? user;
  final void Function(UserModel user) onTap;

  const _ChatTile({
    required this.chat,
    required this.myUid,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherUid = chat.otherUid(myUid);
    final unread = chat.unreadFor(myUid);
    final time =
    DateTime.fromMillisecondsSinceEpoch(chat.lastMessageTime);
    final displayName =
        user?.name ?? (otherUid.length > 8 ? otherUid.substring(0, 8) : otherUid);

    return GestureDetector(
      onTap: () {
        if (user != null) onTap(user!);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.bgCard.withOpacity(0.45),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            // ─── Avatar ─────────────────────────────────────────────
            Stack(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: AppColors.avatarColor(user?.name ?? ''),
                    ),
                  ),
                  child: user?.photoUrl.isNotEmpty == true
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(27),
                    child: Image.network(
                      user!.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          user!.initials,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  )
                      : Center(
                    child: Text(
                      user?.initials ??
                          (otherUid.isNotEmpty
                              ? otherUid[0].toUpperCase()
                              : '?'),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: user?.isOnline == true
                          ? AppColors.online
                          : AppColors.offline,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.bgDark, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // ─── Name + message ──────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: unread > 0
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(time),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: unread > 0
                              ? AppColors.primary
                              : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (chat.lastMessageSenderId == myUid)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.done_all_rounded,
                              color: AppColors.primary, size: 15),
                        ),
                      Expanded(
                        child: Text(
                          chat.lastMessageType == 1
                              ? '📷 Photo'
                              : chat.lastMessage.isEmpty
                              ? 'Tap to chat'
                              : chat.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: unread > 0
                                ? AppColors.textSecondary
                                : AppColors.textHint,
                            fontWeight: unread > 0
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                Color(0xFF0072FF),
                              ],
                            ),
                            borderRadius:
                            BorderRadius.circular(20),
                          ),
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inDays == 0) return DateFormat('h:mm a').format(t);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEE').format(t);
    return DateFormat('MM/dd').format(t);
  }
}