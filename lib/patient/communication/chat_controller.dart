import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/communication.dart';
import '../../repositories/chat_repository.dart';
import '../../services/secure_storage_service.dart';
import 'dart:async';

final chatThreadsProvider = FutureProvider<List<ChatThread>>((ref) async {
  // Refresh every 5 seconds for the list view
  final timer = Timer(const Duration(seconds: 5), () => ref.invalidateSelf());
  ref.onDispose(() => timer.cancel());

  return ref.watch(chatRepositoryProvider).getChatThreads();
});

final chatMessagesProvider = FutureProvider.family<List<ChatMessage>, String>((ref, threadId) async {
  // Refresh every 3 seconds for the active chat view
  final timer = Timer(const Duration(seconds: 3), () => ref.invalidateSelf());
  ref.onDispose(() => timer.cancel());

  return ref.watch(chatRepositoryProvider).getChatMessages(threadId);
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
