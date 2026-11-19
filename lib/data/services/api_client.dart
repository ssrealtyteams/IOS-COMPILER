import '../models/user_api_model.dart';

class ApiClient {
  Future<UserApiModel> fetchUser(String id) async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 800));
    return UserApiModel(
      id: id,
      fullName: 'John Doe',
      emailAddress: 'john.doe@example.com',
    );
  }
}
