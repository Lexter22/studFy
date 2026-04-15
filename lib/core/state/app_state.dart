import 'package:flutter/foundation.dart';

import '../../features/auth/domain/models/app_user.dart';

class AppState extends ChangeNotifier {
  bool _isAuthenticated = false;
  AppUser? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  AppUser? get currentUser => _currentUser;

  void login([AppUser? user]) {
    if (_isAuthenticated) {
      _currentUser = user ?? _currentUser;
      return;
    }

    _isAuthenticated = true;
    _currentUser = user;
    notifyListeners();
  }

  void logout() {
    if (!_isAuthenticated) {
      return;
    }

    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }

  void syncAuthState(AppUser? user) {
    _isAuthenticated = user != null;
    _currentUser = user;
    notifyListeners();
  }

  bool get hasUser => _currentUser != null;
}
