import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../utils/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showAvatar;
  final String otherUserName;
  final String otherUserPhoto;
  final VoidCallback? onReply;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showAvatar = false,
    this.otherUserName = '',
    this.otherUserPhoto = '',
    this.onReply,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: Dismissible(
        key: Key('bubble_${message.id}'),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (_) async {
          onReply?.call();
          return false;
        },
        background: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.reply_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: 3,
            left: isMe ? 48 : 0,
            right: isMe ? 0 : 48,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe) ...[
                SizedBox(
                  width: 32,
                  child: showAvatar ? _miniAvatar() : null,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(child: _bubble(context)),
            ],
          ),
        ),
      ),
    );
  }

  // mini avatar

  Widget _miniAvatar() {
    final colors = AppColors.avatarColor(otherUserName);
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colors),
      ),
      child: otherUserPhoto.isNotEmpty
          ? ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(otherUserPhoto, fit: BoxFit.cover),
      )
          : Center(
        child: Text(
          otherUserName.isNotEmpty
              ? otherUserName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // bubble container

  Widget _bubble(BuildContext context) {
    final isImg = message.isImage && !message.isDeleted;
    return Container(
      decoration: BoxDecoration(
        gradient: isMe && !isImg
            ? const LinearGradient(
          colors: [AppColors.primary, Color(0xFF0072FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: isMe && !isImg ? null : AppColors.bgBubbleReceived,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: isMe
                ? AppColors.primary.withOpacity(0.18)
                : Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.replyContent != null) _replyQuote(),
          if (message.isDeleted)
            _deletedContent()
          else if (isImg)
            _imageContent(context)
          else
            _textContent(),
        ],
      ),
    );
  }

  // reply quote strip

  Widget _replyQuote() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withOpacity(0.12)
            : AppColors.bgInput.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white.withOpacity(0.45) : AppColors.primary,
            width: 3,
          ),
        ),
      ),
      child: Text(
        message.replyContent!,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11.5,
          color:
          isMe ? Colors.white.withOpacity(0.65) : AppColors.textSecondary,
        ),
      ),
    );
  }

  // deleted

  Widget _deletedContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block_rounded,
              size: 13,
              color: isMe
                  ? Colors.white.withOpacity(0.5)
                  : AppColors.textHint),
          const SizedBox(width: 6),
          Text(
            'This message was deleted',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: isMe
                  ? Colors.white.withOpacity(0.55)
                  : AppColors.textHint,
            ),
          ),
          const SizedBox(width: 8),
          _timeText(),
        ],
      ),
    );
  }

  // text content
  Widget _textContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.content,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: isMe ? Colors.white : AppColors.textPrimary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 3),
          _timestamp(),
        ],
      ),
    );
  }

  // image content

  Widget _imageContent(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
        bottomLeft: Radius.circular(isMe ? 18 : 4),
        bottomRight: Radius.circular(isMe ? 4 : 18),
      ),
      child: Stack(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.64,
              maxHeight: 260,
              minWidth: 120,
              minHeight: 90,
            ),
            child: GestureDetector(
              onTap: () => _openViewer(context),
              child: Image.network(
                message.content,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, prog) {
                  if (prog == null) return child;
                  return SizedBox(
                    width: 200,
                    height: 150,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: prog.expectedTotalBytes != null
                            ? prog.cumulativeBytesLoaded /
                            prog.expectedTotalBytes!
                            : null,
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  width: 200,
                  height: 150,
                  color: AppColors.bgInput,
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: AppColors.textHint, size: 36),
                  ),
                ),
              ),
            ),
          ),
          // Time overlay
          Positioned(
            bottom: 6,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _timestamp(onImage: true),
            ),
          ),
        ],
      ),
    );
  }

  void _openViewer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ImageViewer(url: message.content),
      ),
    );
  }

  // timestamp row

  Widget _timestamp({bool onImage = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _timeText(onImage: onImage),
        if (isMe) ...[
          const SizedBox(width: 4),
          _statusIcon(onImage: onImage),
        ],
      ],
    );
  }

  Widget _timeText({bool onImage = false}) {
    return Text(
      DateFormat('h:mm a')
          .format(DateTime.fromMillisecondsSinceEpoch(message.timestamp)),
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 10,
        color: onImage
            ? Colors.white
            : isMe
            ? Colors.white.withOpacity(0.65)
            : AppColors.textHint,
      ),
    );
  }

  Widget _statusIcon({bool onImage = false}) {
    final readColor =
    onImage ? Colors.white : AppColors.primaryLight;
    final defaultColor = onImage
        ? Colors.white.withOpacity(0.7)
        : Colors.white.withOpacity(0.65);

    switch (message.status) {
      case MessageStatus.sending:
        return Icon(Icons.access_time_rounded,
            size: 13, color: defaultColor);
      case MessageStatus.sent:
        return Icon(Icons.check_rounded, size: 13, color: defaultColor);
      case MessageStatus.delivered:
        return Icon(Icons.done_all_rounded,
            size: 13, color: defaultColor);
      case MessageStatus.read:
        return Icon(Icons.done_all_rounded,
            size: 13, color: readColor);
    }
  }

  // options sheet

  void _showOptions(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bgInput,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (!message.isDeleted) ...[
              _option(context,
                  icon: Icons.reply_rounded,
                  label: 'Reply',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    onReply?.call();
                  }),
              if (message.isText)
                _option(context,
                    icon: Icons.copy_rounded,
                    label: 'Copy Text',
                    color: AppColors.textSecondary,
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: message.content));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          backgroundColor: AppColors.primary,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }),
              if (onDelete != null)
                _option(context,
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    color: AppColors.accent,
                    onTap: () {
                      onDelete?.call();
                      Navigator.pop(context);
                    }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _option(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Color color,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 11),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Text(label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color == AppColors.accent
                      ? AppColors.accent
                      : AppColors.textPrimary,
                )),
          ],
        ),
      ),
    );
  }
}

// full-screen Image Viewer

class _ImageViewer extends StatelessWidget {
  final String url;
  const _ImageViewer({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, prog) {
              if (prog == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            },
          ),
        ),
      ),
    );
  }
}