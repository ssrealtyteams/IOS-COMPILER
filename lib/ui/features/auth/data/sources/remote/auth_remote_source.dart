import 'package:sales_crm_dialer/core/error/result.dart';

abstract class AuthRemoteSource {
  Future<Result<Map<String, dynamic>, AppError>> login({
    required String identifier,
    required String password,
    required bool rememberMe,
  });
  Future<void> logout();
}
