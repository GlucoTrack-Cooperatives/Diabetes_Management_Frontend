import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_text_styles.dart';
import '../../patient/communication/chat_controller.dart';
import 'physician_chat_screen.dart';

class PhysicianChatList extends ConsumerStatefulWidget {
  const PhysicianChatList({super.key});

  @override
  ConsumerState<PhysicianChatList> createState() => _PhysicianChatListState();
}

class _PhysicianChatListState extends ConsumerState<PhysicianChatList> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final threadsAsync = ref.watch(chatThreadsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (value) => setState(() => searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search patients...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        Expanded(
          child: threadsAsync.when(
            skipLoadingOnReload: true,
            data: (threads) {
              // Filtering based on participantName (which should be the patient name for physician)
              final filteredThreads = threads
                  .where((t) => t.participantName.toLowerCase().contains(searchQuery.toLowerCase()))
                  .toList();

              filteredThreads.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

              if (filteredThreads.isEmpty) {
                return const Center(child: Text("No chats found"));
              }

              return ListView.separated(
                itemCount: filteredThreads.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final thread = filteredThreads[index];                  return ListTile(
                    leading: CircleAvatar(
                        child: Text(thread.participantName.isNotEmpty ? thread.participantName[0] : '?')
                    ),
                    title: Text(thread.participantName, style: AppTextStyles.bodyText1),
                    subtitle: Text(
                      thread.lastMessage.isNotEmpty ? thread.lastMessage : "No messages yet",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // FIX: Added .toLocal() here to convert from UTC to Poland time
                    trailing: Text(DateFormat('HH:mm').format(thread.lastMessageTime.toLocal())),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PhysicianChatScreen(
                            threadId: thread.id,
                            patientName: thread.participantName,
                            patientId: thread.patientId,
                          ),
                        ),
                      );
                      ref.invalidate(chatThreadsProvider);
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }
}
