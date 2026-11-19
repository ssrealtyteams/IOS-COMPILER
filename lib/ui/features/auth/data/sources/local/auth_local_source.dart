import 'package:sales_crm_dialer/domain/entities/user.dart';

abstract class AuthLocalSource {
  Future<User?> getCurrentUser();
  Future<String?> getAccessToken();
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required User user,
  });
  
  Future<void> clearSession();
}
