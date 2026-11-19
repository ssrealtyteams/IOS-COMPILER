import '../../domain/models/user.dart';
import '../services/api_client.dart';

class UserRepository {
  UserRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;
  User? _cachedUser;

  Future<User> getUser(String id) async {
    if (_cachedUser != null && _cachedUser!.id == id) {
      return _cachedUser!;
    }

    final apiModel = await _apiClient.fetchUser(id);
    _cachedUser = User(
      id: apiModel.id,
      name: apiModel.fullName,
      email: apiModel.emailAddress,
    );
    return _cachedUser!;
  }
}
