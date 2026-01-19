import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/communication.dart';
import '../controllers/chat_controller.dart';

class ChatView extends ConsumerStatefulWidget {
  final String title;
  final String threadId;

  const ChatView({super.key, required this.title, required this.threadId});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
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

  // Helper to format the date header string
  String _getDateHeader(DateTime date) {
    // Convert the message date to local time first
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

    return Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            data: (messages) {
              final currentUserId = currentUserIdAsync.value;
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  bool isMe = msg.senderId == currentUserId;

                  // Date logic for headers
                  bool showDateHeader = false;
                  if (index == messages.length - 1) {
                    // Always show header for the very first message in history
                    showDateHeader = true;
                  } else {
                    // Compare current message date with the next one in the list (previous chronologically)
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
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getDateHeader(date),
            style: AppTextStyles.bodyText2.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              msg.content,
              style: TextStyle(color: isMe ? Colors.white : Colors.black),
            ),
          ),
          Text(
            // ADD .toLocal() HERE
            DateFormat('HH:mm').format(msg.timestamp.toLocal()),
            style: AppTextStyles.bodyText2.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: "Type a message...",
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.primary),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}