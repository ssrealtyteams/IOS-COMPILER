import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sales_crm_dialer/domain/entities/user.dart';
import 'auth_local_source.dart';

class LocalAuthSourceImpl implements AuthLocalSource {
  static const _kUserKey = 'auth_cached_user';
  static const _kTokenKey = 'auth_access_token';
  static const _kRefreshTokenKey = 'auth_refresh_token';

  static User? _inMemoryCachedUser;
  static User? get inMemoryCachedUser => _inMemoryCachedUser;

  static bool get isDirectorOrExecutive {
    final u = _inMemoryCachedUser;
    if (u == null) return false;
    return u.isExecutive ||
        u.isDirector ||
        (u.email?.toLowerCase() == 'info@ssrealty.org') ||
        (u.employeeId?.toUpperCase() == 'SSR000');
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString(_kUserKey);
      if (userJsonStr != null && userJsonStr.isNotEmpty) {
        final map = jsonDecode(userJsonStr) as Map<String, dynamic>;
        final user = User.fromJson(map);
        _inMemoryCachedUser = user;
        return user;
      }
    } catch (_) {}
    return _inMemoryCachedUser;
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kTokenKey);
    } catch (_) {}
    return null;
  }

  @override
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required User user,
  }) async {
    _inMemoryCachedUser = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kTokenKey, accessToken);
      await prefs.setString(_kRefreshTokenKey, refreshToken);
      await prefs.setString(_kUserKey, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  @override
  Future<void> clearSession() async {
    _inMemoryCachedUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kTokenKey);
      await prefs.remove(_kRefreshTokenKey);
      await prefs.remove(_kUserKey);
      await prefs.remove('attendance_is_punched_in');
      await prefs.remove('attendance_last_punch_date');
    } catch (_) {}
  }

  Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
