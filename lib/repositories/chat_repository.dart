import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/communication.dart';
import '../services/api_client.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatRepository(apiClient);
});

class ChatRepository {
  final ApiClient _apiClient;

  ChatRepository(this._apiClient);

  Future<List<ChatThread>> getChatThreads() async {
    // This endpoint should return threads for the logged-in user
    // For physician: list of patient threads
    // For patient: likely just one thread with their physician
    final response = await _apiClient.get('/communication/threads');
    if (response == null) return [];
    return (response as List).map((e) => ChatThread.fromJson(e)).toList();
  }

  Future<List<ChatMessage>> getChatMessages(String threadId) async {
    final response = await _apiClient.get('/communication/threads/$threadId/messages');
    if (response == null) return [];
    return (response as List).map((e) => ChatMessage.fromJson(e)).toList();
  }

  Future<ChatMessage> sendMessage(String threadId, String content) async {
    final response = await _apiClient.post('/communication/threads/$threadId/messages', {
      'content': content,
    });
    return ChatMessage.fromJson(response);
  }
}
