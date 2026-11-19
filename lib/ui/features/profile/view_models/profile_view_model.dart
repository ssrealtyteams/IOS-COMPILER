import 'package:flutter/foundation.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../domain/models/user.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({required UserRepository userRepository})
      : _userRepository = userRepository;

  final UserRepository _userRepository;

  User? _user;
  User? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _userRepository.getUser(id);
    } catch (e) {
      _errorMessage = 'Failed to load profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
