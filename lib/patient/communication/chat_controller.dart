import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/communication.dart';
import '../../repositories/chat_repository.dart';
import '../../services/secure_storage_service.dart';
import 'dart:async';
import 'dart:convert';

final _chatThreadsSignatureProvider = StateProvider<String?>((ref) => null);
final _chatMessagesSignatureProvider = StateProvider<Map<String, String>>((ref) => {});

final chatThreadsProvider = FutureProvider<List<ChatThread>>((ref) async {
  // Refresh every 5 seconds
  final timer = Timer(const Duration(seconds: 5), () => ref.invalidateSelf());
  ref.onDispose(() => timer.cancel());

  final threads = await ref.watch(chatRepositoryProvider).getChatThreads();

  // Lightweight signature: count + first thread ID + first thread's lastMessageTime
  final currentSignature = threads.isEmpty
      ? '0'
      : '${threads.length}-${threads.first.id}-${threads.first.lastMessageTime.toIso8601String()}';

  final cachedSignature = ref.read(_chatThreadsSignatureProvider);

  if (currentSignature != cachedSignature) {
    ref.read(_chatThreadsSignatureProvider.notifier).state = currentSignature;
    print('💬 Chat threads UPDATED - changes detected');
  } else {
    print('💬 Chat threads - no changes');
  }

  return threads;
});

final chatMessagesProvider = FutureProvider.family<List<ChatMessage>, String>((ref, threadId) async {
  // Refresh every 3 seconds
  final timer = Timer(const Duration(seconds: 3), () => ref.invalidateSelf());
  ref.onDispose(() => timer.cancel());

  final messages = await ref.watch(chatRepositoryProvider).getChatMessages(threadId);

  // Lightweight signature: count + last message ID + last message timestamp
  final currentSignature = messages.isEmpty
      ? '0'
      : '${messages.length}-${messages.last.id}-${messages.last.timestamp.toIso8601String()}';

  final cache = ref.read(_chatMessagesSignatureProvider);
  final cachedSignature = cache[threadId];

  if (currentSignature != cachedSignature) {
    ref.read(_chatMessagesSignatureProvider.notifier).state = {...cache, threadId: currentSignature};
    print('💬 NEW MESSAGE detected in thread $threadId');
  } else {
    print('💬 Messages for $threadId - no changes');
  }

  return messages;
});



final currentUserIdProvider = FutureProvider<String?>((ref) async {
  return ref.watch(storageServiceProvider).getUserId();
});

class ChatController extends StateNotifier<AsyncValue<void>> {
  final ChatRepository _repository;

  ChatController(this._repository) : super(const AsyncValue.data(null));

  Future<void> sendMessage(String threadId, String content, WidgetRef ref) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.sendMessage(threadId, content);
      ref.invalidate(chatMessagesProvider(threadId));
    });
  }
}

final chatControllerProvider = StateNotifierProvider<ChatController, AsyncValue<void>>((ref) {
  return ChatController(ref.watch(chatRepositoryProvider));
});
