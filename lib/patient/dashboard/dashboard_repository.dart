import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(apiClientProvider)); // Inject the smart client
});

class DashboardRepository {
  final ApiClient _client;

  DashboardRepository(this._client);

  Future<Map<String, dynamic>> getPatientStats() async {
    // We just call the endpoint. The client handles the Token!
    final response = await _client.get('/patient/dashboard/stats'); // TODO: add, change to proper endpoint
    return response;
  }
}