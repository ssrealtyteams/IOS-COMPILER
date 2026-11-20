import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../../../../domain/entities/user.dart';
import 'package:sales_crm_dialer/ui/features/auth/data/sources/remote/auth_remote_source.dart';
import 'package:sales_crm_dialer/ui/features/auth/data/sources/local/auth_local_source.dart';
import '../../../../core/services/location_tracking_service.dart';
import '../../../../data/repositories/remote_lead_repository.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

@injectable
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    required AuthRemoteSource remoteSource,
    required AuthLocalSource localSource,
  })  : _remote = remoteSource,
        _local = localSource;

  final AuthRemoteSource _remote;
  final AuthLocalSource _local;

  AuthState _state = AuthState.initial;
  AuthState get state => _state;

  User? _currentUser;
  User? get currentUser => _currentUser;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isPasswordVisible = false;
  bool get isPasswordVisible => _isPasswordVisible;

  bool _rememberMe = false;
  bool get rememberMe => _rememberMe;

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleRememberMe() {
    _rememberMe = !_rememberMe;
    notifyListeners();
  }

  Future<void> checkAuthState() async {
    _setState(AuthState.loading);
    final user = await _local.getCurrentUser();
    if (user != null) {
      _currentUser = user;
      _setState(AuthState.authenticated);
    } else {
      _setState(AuthState.unauthenticated);
    }
  }

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    _setState(AuthState.loading);

    final result = await _remote.login(
      identifier: identifier.trim(),
      password: password,
      rememberMe: _rememberMe,
    );

    result.fold(
      onSuccess: (data) async {
        await _local.saveSession(
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
          user: data['user'] as User,
        );
        _currentUser = data['user'] as User;

        // Immediately fetch fresh leads for this agent
        try {
          await RemoteLeadRepository.clearCache();
          await RemoteLeadRepository.fetchFromApi();
        } catch (_) {}

        _setState(AuthState.authenticated);
        if (!_currentUser!.isExecutive) {
          LocationTrackingService.instance.startTracking();
        }
      },
      onFailure: (error) {
        _errorMessage = error.message;
        _setState(AuthState.error);
      },
    );
  }

  Future<void> logout() async {
    LocationTrackingService.instance.stopTracking();
    await _remote.logout();
    await _local.clearSession();
    try {
      await RemoteLeadRepository.clearCache();
    } catch (_) {}
    _currentUser = null;
    _setState(AuthState.unauthenticated);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setState(AuthState state) {
    _state = state;
    notifyListeners();
  }
}
