import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/communication.dart';
import '../patient/communication/chat_controller.dart';

class ChatView extends ConsumerStatefulWidget {
  final String title;
  final String threadId;

  const ChatView({super.key, required this.title, required this.threadId});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    ref.read(chatControllerProvider.notifier).sendMessage(
      widget.threadId,
      _messageController.text.trim(),
      ref,
    );
    _messageController.clear();
  }

  String _getDateHeader(DateTime date) {
    final localDate = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(localDate.year, localDate.month, localDate.day);

    if (msgDate == today) return "Today";
    if (msgDate == yesterday) return "Yesterday";
    if (today.difference(msgDate).inDays < 7) {
      return DateFormat('EEEE').format(localDate);
    }
    return DateFormat('d MMM').format(localDate);
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.threadId));
    final currentUserIdAsync = ref.watch(currentUserIdProvider);

    // 1. Soft background color for the whole chat area
    return Container(
      color: const Color(0xFFF5F7FA),
      child: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              skipLoadingOnReload: true,
              data: (messages) {
                final currentUserId = currentUserIdAsync.value;
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  physics: const BouncingScrollPhysics(), // 2. Bouncing physics feels more native
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    // Defensive check for null currentUserId
                    bool isMe = currentUserId != null && msg.senderId == currentUserId;

                    bool showDateHeader = false;
                    if (index == messages.length - 1) {
                      showDateHeader = true;
                    } else {
                      final prevMsg = messages[index + 1];
                      if (msg.timestamp.day != prevMsg.timestamp.day ||
                          msg.timestamp.month != prevMsg.timestamp.month ||
                          msg.timestamp.year != prevMsg.timestamp.year) {
                        showDateHeader = true;
                      }
                    }

                    return Column(
                      children: [
                        if (showDateHeader) _buildDateHeader(msg.timestamp),
                        _buildMessageBubble(msg, isMe),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05), // Very subtle grey
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _getDateHeader(date),
            style: AppTextStyles.bodyText2.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    // 3. Modern Bubble Design
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75, // Max 75% width
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          // Subtle shadow for depth on received messages
          boxShadow: isMe
              ? []
              : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min, // Hug content
          children: [
            Text(
              msg.content,
              style: AppTextStyles.bodyText1.copyWith(
                color: isMe ? Colors.white : Colors.black87,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
                DateFormat('HH:mm').format(msg.timestamp.toLocal()),
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey.shade500,
                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    // 4. "Pill" style input area with elevation
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.transparent),
                ),
                child: TextField(
                  controller: _messageController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 4, // Grow up to 4 lines
                  decoration: const InputDecoration(
                    hintText: "Type a message...",
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Circular Send Button
            GestureDetector(
              onTap: _sendMessage,
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}