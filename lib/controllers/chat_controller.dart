import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/communication.dart';
import '../repositories/chat_repository.dart';
import '../services/secure_storage_service.dart';

final chatThreadsProvider = FutureProvider<List<ChatThread>>((ref) async {
  return ref.watch(chatRepositoryProvider).getChatThreads();
});

final chatMessagesProvider = FutureProvider.family<List<ChatMessage>, String>((ref, threadId) async {
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
